#!/usr/bin/env bash

usage()
{
   echo "Usage: amwg_modobs.sh [-r altdir] [-u USERexp] EXP YEAR1 YEAR2"
   echo
   echo "Do an AMWG analysis of experiment EXP in years YEAR1 to YEAR2"
   echo
   echo "Basically a wrapper around:"
   echo "     ncarize (to create climatology from post-processed EC-Earth output)"
   echo "     diag_mod_vs_obs.sh (the plot engine)"
   echo 
   echo "Option:"
   echo "   -r ALTDIR   : fully qualified path to another hiresclim2 output dir (default set in config file)"
   echo "   -u USERexp  : alternative user owner of the experiment (default set in config file)"
}

set -e

# -- Sanity check
[[ -z $ECE3_POSTPROC_TOPDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_DATADIR ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_MACHINE ]] && echo "User environment not set. See ../README." && exit 1 

# -- options

while getopts "h?r:u:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        u)  USERexp=$OPTARG
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

EXPID=$1
year1=$2
year2=$3

# -- User configuration
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_amwg_${ECE3_POSTPROC_MACHINE}.sh

# - installation params
export EMOP_DIR=$ECE3_POSTPROC_TOPDIR/amwg
export DIR_EXTRA="${EMOP_DIR}/data"

# - HiresClim2 post-processed files loc 
if [[ -n $ALT_RUNDIR ]]
then
    POST_DIR=$ALT_RUNDIR
else
    POST_DIR=$(eval echo ${ECE3_POSTPROC_POSTDIR})
fi

[[ ! -d $POST_DIR ]] && echo "*EE* Experiment output dir $POST_DIR does not exist!" && exit 1
export POST_DIR


# -- create climatology of the experiment
cd $EMOP_DIR/ncarize
./ncarize_pd.sh $EXPID ${year1} ${year2}

# -- diagnostic: compare generated climatology with observations
cd $EMOP_DIR/amwg_diag
export RUN=$1     
export PERIOD=$2-$3
csh ./csh/diag_mod_vs_obs.csh

# -- Store
DIAGS=$EMOP_CLIM_DIR/diag_${EXPID}_${year1}-${year2}
cd $DIAGS
rm -r -f diag_${EXPID}.tar
tar cvf diag_${EXPID}.tar ${EXPID}-obs_${year1}-${year2}
#ectrans -remote sansone -source diag_${EXPID}.tar -verbose -overwrite
#ectrans -remote sansone -source ~/EXPERIMENTS.${ECE3_POSTPROC_MACHINE}.$USERme.dat -verbose -overwrite
