#!/bin/bash

# -- Filter IFS output (to be applied through a grib_filter call)
# Useful when there are output with different timestep.
# Comment if no filtering/change for different output
#FILTERGG2D="if ( (!(typeOfLevel is \"isobaricInhPa\") && !(typeOfLevel is \"isobaricInPa\") && !(typeOfLevel is \"potentialVorticity\" ))) { write; }"
#FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") )) { write; }"
#FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"


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

submit_cmd="qsub"

# required programs, including compression options
for soft in nco netcdf python cdo cdftools
do
    if ! module -t list 2>&1 | grep -q $soft
    then
        module load $soft
    fi
done

cdo=cdo
cdozip="$cdo -f nc4c -z zip"
rbld="/perm/ms/nl/nm6/r1902-merge-new-components/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

cdftoolsbin="${CDFTOOLS_DIR}/bin"
#cdftoolsbin="/home/ms/nl/nm6/ECEARTH/postproc/barakuda/cdftools_light/bin"
python=python

# Set this to 1 if a newer syntax is used ("cdfmean -f file ..." instead
# of "cdfmean file ..."). Set both to 1 if using version 4 of cdftools, only the second if using 3.0.1. 
newercdftools=0
newercdftools2=0

# Set to 0 for not to rebuild 3D relative humidity
rh_build=1

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="/perm/ms/nl/nm6/ECE3-DATA/post-proc"

# Base dir to archive (ie just make a copy of) the monthly results. Daily results, if any, are left in scratch. 
STOREDIR=/home/hpc/pr45de/di56bov/work/ecearth3/post/hiresclim/

# ---------- NEMO VAR/FILES MANGLING ----------------------

# NEMO 'wfo' variable can be in the SBC files instead of T files, then
# set this flag to 1
export use_SBC=0

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
