#!/bin/bash

set -xuve 

# -- Filter IFS output (to be applied through a grib_filter call)
# Useful when there are output with different timestep.
# Set to empty if no filtering/change for different output
#FILTERGG2D="if ( (!(typeOfLevel is \"isobaricInhPa\") && !(typeOfLevel is \"isobaricInPa\") && !(typeOfLevel is \"potentialVorticity\" ))) { write; }"
#FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") )) { write; }"
#FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"
FILTERGG2D=""
FILTERGG3D=""
FILTERSH=""

#PLS  # where is the IFS, NEMO output and logs located (change based on your directory structure)
#PLS  # 1) ISAC-CNR dir structure
#PLS  IFSRESULTS=$BASERESULTS/output/Output_*/IFS
#PLS  #ABNEMORESULTS=$BASERESULTS/output/Output_*/NEMO
#PLS  NEMORESULTS=$BASERESULTS/output/Output_$year/NEMO
#PLS  LOGSDIR=$BASERESULTS/log/Log_$year
#PLS  # 2) Generic EC-Earth dir structure (year = leg) Keep the * !
#PLS  #IFSRESULTS=$BASERESULTS/output/ifs/*
#PLS  #NEMORESULTS=$BASERESULTS/output/nemo/*
#PLS  #ABproposed change NEMORESULTS=$BASERESULTS/output/nemo/$year
#PLS  #LOGSDIR=$BASERESULTS/log/$year


# Configuration file for hiresclim script
# 
# Add here machine dependent set up that do NOT necessarily depends on any of
#    the following general user settings:
#    ECE3_POSTPROC_TOPDIR, ECE3_POSTPROC_RUNDIR, or ECE3_POSTPROC_DATADIR

submit_cmd="sbatch"


# required programs, including compression options
module load gsl grib netcdf hdf5 CDO udunits nco python/2.7.13
module list
export CDFTOOLS_DIR=/gpfs/projects/bsc32/opt/cdftools-3.1/intel-2017.4

cdo=cdo
cdozip="$cdo -f nc4c -z zip"
rbld="/gpfs/projects/bsc32/repository/apps/rebuild_nemo/rebuild_nemo"

cdftoolsbin="${CDFTOOLS_DIR}/bin"
#cdftoolsbin="/home/ms/nl/nm6/ECEARTH/postproc/barakuda/cdftools_light/bin"
newercdftools=0
newercdftools2=1
python=python

# number of parallel procs for IFS (max 12) and NEMO rebuild. Default to 12.
if [ -z "${IFS_NPROCS:-}" ] ; then
    IFS_NPROCS=12; NEMO_NPROCS=12
fi

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="/gpfs/projects/bsc32/bsc32051/ECE3-DATA/post-proc"

# Base dir to archive (ie just make a copy of) the monthly results. Daily results, if any, are left in scratch. 
STOREDIR=$SCRATCH/ecearth3/post/hiresclim/


# # NEMO files
# export NEMO_SAVED_FILES="grid_T grid_U grid_V icemod grid_W" ; # which files are saved / we care for?

# # NEMO variables
# export nm_wfo="wfo"        ; # water flux 
# export nm_sst="tos"        ; # SST (2D)
# export nm_sss="sos"        ; # SS salinity (2D)
# export nm_ssh="zos"        ; # sea surface height (2D)
# export nm_iceconc="siconc" ; # Ice concentration as in icemod file (2D)
# export nm_icethic="sithic" ; # Ice thickness as in icemod file (2D)
# export nm_tpot="thetao"    ; # pot. temperature (3D)
# export nm_s="so"           ; # salinity (3D)
# export nm_u="uo"           ; # X current (3D)
# export nm_v="vo"           ; # Y current (3D)




# TODO: implement a true backup on ECFS
