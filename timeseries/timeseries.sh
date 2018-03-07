#/bin/bash

#set -xuve
set -eu

usage()
{
  echo "Usage: timeseries.sh [-r ALT_RUNDIR] [-u userexp] EXP"
  echo "Example: ./timeseries.sh io01"
  echo "   Compute timeseries for experiment EXP."
  echo "Options are:"
  echo "   -r ALT_RUNDIR : fully qualified path to another user EC-Earth top RUNDIR"
  echo "                   that is RUNDIR/EXP/post must exists and be readable"
  echo "   -u USERexp  : alternative user owner of the experiment, default $USER"
}

#########################
# options and arguments #
#########################

while getopts "h?ur:" opt; do
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

if [ $# -gt 3 ]; then
   usage
   exit 1
fi

exp=$1
ALT_RUNDIR=""

# set variables which can be eval'd
EXPID=$exp

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

if [ "$#" -eq 3 ]; then           # optional alternative top rundir 
    ALT_RUNDIR=$3
fi

# load cdo, netcdf and dir for results and mesh files
. $ECE3_POSTPROC_TOPDIR/conf/$ECE3_POSTPROC_MACHINE/conf_timeseries_$ECE3_POSTPROC_MACHINE.sh

do_trans=0

#############################################################
# -- Check settings dependent only on the ECE3_POSTPROC_* variables, i.e. env
############################################################

# Base directory of HiresClim2 postprocessing outputs
if [[ -n $ALT_RUNDIR ]]
then
    export DATADIR=`eval echo ${ALT_RUNDIR}`/mon
else
    export DATADIR=`eval echo ${ECE3_POSTPROC_POSTDIR}`/mon
fi
[[ ! -d $DATADIR ]] && echo "*EE* Experiment HiresClim2 output dir $DATADIR does not exist!" && exit 1

#export DIR_TIME_SERIES=`echo ${DIR_TIME_SERIES} | sed -e "s|<RUN>|${RUN}|g"`
export DIR_TIME_SERIES=`eval echo ${ECE3_POSTPROC_DIAGDIR}/timeseries`/$exp

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
    echo "*II* ecmean accounts for nemo output"
fi

# where to find mesh and mask files 
export NEMO_MESH_DIR=${MESHDIR_TOP}/$NEMOCONFIG


###########################
# -- Atmospheric timeseries
###########################

cd $ECE3_POSTPROC_TOPDIR/timeseries
  
./monitor_atmo.sh -R $exp -o
./monitor_atmo.sh -R $exp -e

#######################
# -- Oceanic timeseries
#######################

if (( $do_ocean ))
then
    ./monitor_ocean.sh -R $exp
    ./monitor_ocean.sh -R $exp -e
fi

#########################
# -- Archive and transfer
#########################

if (( $do_trans ))
then
    cd ${DIR_TIME_SERIES}
    rm -r -f  timeseries_$exp.tar # remove old if any
    tar cfv timeseries_$exp.tar  $exp/
#    ectrans -remote sansone -source timeseries_$exp.tar  -put -verbose -overwrite
#    ectrans -remote sansone -source ~/EXPERIMENTS.$MACHINE.$USER.dat -verbose -overwrite
fi
