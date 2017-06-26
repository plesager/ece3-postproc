#/bin/bash

set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: timeseries.sh EXP [ALT_RUNDIR]"
    echo
    echo "   Compute timeseries for experiment EXP."
    exit
fi

exp=$1

# load cdo, netcdf and dir for results and mesh files
. $ECE3_POSTPROC_TOPDIR/conf/conf_timeseries_$ECE3_POSTPROC_MACHINE.sh

if [ "$#" -eq 2 ]; then           # optional alternative top rundir 
    ALT_RUNDIR=$2
fi

do_trans=0

#############################################################
# -- Check settings dependent only on the ECE3_POSTPROC_* variables, i.e. env
############################################################

# Base directory of HiresClim2 postprocessing outputs
if [[ -n $ALT_RUNDIR ]]
then
    export DATADIR=$ALT_RUNDIR/${exp}/post/mon/
else
    export DATADIR="${ECE3_POSTPROC_RUNDIR}/${exp}/post/mon/"
fi
[[ ! -d $DATADIR ]] && echo "*EE* Experiment HiresClim2 output dir $DATADIR does not exist!" && exit 1


# test if it was a coupled run, and find resolution

check=$( ls $DATADIR/Post_*/*sosaline* )
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
  
# ./monitor_atmo.sh -R $exp -o
# ./monitor_atmo.sh -R $exp -e

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
    ectrans -remote sansone -source timeseries_$exp.tar  -put -verbose -overwrite
    ectrans -remote sansone -source ~/EXPERIMENTS.$MACHINE.$USER.dat -verbose -overwrite
fi
