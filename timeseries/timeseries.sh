#/bin/bash

set -eu

usage()
{
    cat << EOT >&2

  Usage: timeseries.sh [-r POSTDIR] [-u userexp] [-w] EXP

  Example: ./timeseries.sh io01
     Compute timeseries for experiment EXP.

  Options:
     -r POSTDIR  : overwrite ECE3_POSTPROC_POSTDIR
     -u USERexp  : alternative 'user' owner of the experiment, default to $USER
                    overwrite USERexp token.
     -w  : create plots and Webpage to display them

     ECE3_POSTPROC_POSTDIR and USERexp default values should be set in
     your conf_timeseries_$ECE3_POSTPROC_MACHINE.sh file
EOT
}

#########################
# options and arguments #
#########################
ALT_RUNDIR=""
web=0

while getopts "h?u:r:w" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        u)  USERexp=$OPTARG
            ;;
        r)  ALT_RUNDIR=$OPTARG
            ;;
        w)  web=1
    esac
done
shift $((OPTIND-1))

if [ $# -ne 1 ]; then
   usage
   exit 1
fi

# set variables which can be eval'd
EXPID=$1

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# load cdo, netcdf and dir for results and mesh files
. $ECE3_POSTPROC_TOPDIR/conf/$ECE3_POSTPROC_MACHINE/conf_timeseries_$ECE3_POSTPROC_MACHINE.sh

# -- HARDCODED OPTION
do_trans=0

#############################################################
# -- Check configuration settings
############################################################

# Base directory of HiresClim2 postprocessing outputs
if [[ -n $ALT_RUNDIR ]]
then
    export DATADIR=`eval echo ${ALT_RUNDIR}`/mon
else
    export DATADIR=`eval echo ${ECE3_POSTPROC_POSTDIR}`/mon
fi
[[ ! -d $DATADIR ]] && echo "*EE* Experiment HiresClim2 output dir $DATADIR does not exist!" && exit 1

# Output dir
export DIR_TIME_SERIES=`eval echo ${ECE3_POSTPROC_DIAGDIR}/timeseries`/$EXPID

# test if it was a coupled run, and find resolution
# TODO use same checks in hiresclim2, ECMean and timeseries
# TODO test with real 2 year data, in my (Etienne) tests with faked 2 year data the plots were very wrong
check=$( ls $DATADIR/Post_*/*sosaline* 2>/dev/null || true )
NEMOCONFIG=""
do_ocean=0
if [[ -n $check ]]
then 
    do_ocean=1
    
    a_file=$(ls -1 $DATADIR/Post_*/*sosaline.nc | head -n1)
    ysize=$(cdo griddes $a_file | grep ysize | awk '{print $3}')

    case $ysize in
        1050)
            NEMOCONFIG=ORCA025L75
            ;;
        292)
            NEMOCONFIG=ORCA1L75
            ;;
        *)
            echo '*EE* Unaccounted NEMO resolution: ysize=$ysize' && exit 1
    esac
    
    export NEMOCONFIG
    echo "*II* TimeSeries accounts for nemo output"
fi

# where to find mesh and mask files 
export NEMO_MESH_DIR=${MESHDIR_TOP}/$NEMOCONFIG


###########################
# -- Atmospheric timeseries
###########################

cd $ECE3_POSTPROC_TOPDIR/timeseries

echo "*II* Compute Atmospheric TimeSeries"
./monitor_atmo.sh -R $EXPID -o

(( web )) && { echo "*II* Plot Atmospheric TimeSeries"
               ./monitor_atmo.sh -R $EXPID -e ; }

#######################
# -- Oceanic timeseries
#######################

if (( $do_ocean ))
then
    echo "*II* Compute Oceanic TimeSeries"
    ./monitor_ocean.sh -R $EXPID
    
    (( web )) && { echo "*II* Plot Oceanic TimeSeries"
                   ./monitor_ocean.sh -R $EXPID -e ; }
fi

#########################
# -- Archive and transfer
#########################

if (( $do_trans ))
then
    cd ${DIR_TIME_SERIES}
    rm -r -f  timeseries_$EXPID.tar # remove old if any
    tar cfv timeseries_$EXPID.tar  $EXPID/
#    ectrans -remote sansone -source timeseries_$EXPID.tar  -put -verbose -overwrite
#    ectrans -remote sansone -source ~/EXPERIMENTS.$MACHINE.$USER.dat -verbose -overwrite
fi
