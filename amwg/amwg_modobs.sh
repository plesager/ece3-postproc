#!/usr/bin/env bash

usage()
{
   echo "Usage: amwg_modobs.sh [-r RUNDIR] EXP YEAR1 YEAR2"
   echo
   echo "Do an AMWG analysis of experiment EXP in years YEAR1 to YEAR2"
   echo
   echo "Basically a wrapper around:"
   echo "     ncarize (to create climatology from post-processed EC-Earth output)"
   echo "     diag_mod_vs_obs.sh (the plot engine)"
   echo 
   echo "Option:"
   echo "   -r RUNDIR : fully qualified path to another user EC-Earth top RUNDIR [NOT TESTED YET!]"
   echo "                that has been  processed by hiresclim2."
   echo "                That means RUNDIR/EXP/post must exists, contain files, and be readable"
}

set -e

# -- Sanity check
[[ -z $ECE3_POSTPROC_TOPDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_RUNDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_DATADIR ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_MACHINE ]] && echo "User environment not set. See ../README." && exit 1 

# -- options

while getopts "h?r:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        r)  ALT_RUNDIR=$OPTARG 
            ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 3 ]; then
   usage
   exit 0
fi

expname=$1
year1=$2
year2=$3

# -- User configuration
. $ECE3_POSTPROC_TOPDIR/conf/conf_amwg_${ECE3_POSTPROC_MACHINE}.sh

# - installation params
export EMOP_DIR=$ECE3_POSTPROC_TOPDIR/amwg
export DIR_EXTRA="${EMOP_DIR}/data"

# - HiresClim2 post-processed files loc 
if [[ -n $ALT_RUNDIR ]]
then
    export POST_DIR="$ALT_RUNDIR/$expname/post"
else
    export POST_DIR="$ECE3_POSTPROC_RUNDIR/$expname/post"
fi
[[ ! -d $POST_DIR ]] && echo "*EE* Experiment output dir $POST_DIR does not exist!" && exit 1


# -- get to work
cd $EMOP_DIR/ncarize
./ncarize_pd.sh -C ${ECE3_POSTPROC_MACHINE} -R $expname -i ${year1} -e ${year2}

cd $EMOP_DIR/amwg_diag
./diag_mod_vs_obs.sh -C ${ECE3_POSTPROC_MACHINE} -R $expname -P ${year1}-${year2}


# -- Store
DIAGS=$EMOP_CLIM_DIR/diag_${expname}_${year1}-${year2}
cd $DIAGS
rm -r -f diag_${expname}.tar
tar cvf diag_${expname}.tar ${expname}-obs_${year1}-${year2}
#ectrans -remote sansone -source diag_${expname}.tar -verbose -overwrite
#ectrans -remote sansone -source ~/EXPERIMENTS.${ECE3_POSTPROC_MACHINE}.$USERme.dat -verbose -overwrite
