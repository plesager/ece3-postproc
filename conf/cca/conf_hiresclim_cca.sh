#!/bin/bash

 ######################################
 # Configuration file for HIRESCLIM2  #
 ######################################

# --- PATTERN TO FIND MODEL OUTPUT
# 
# Must include $EXPID and be single-quoted
#
# optional variable are $USER, $LEGNB, $year
export IFSRESULTS0='/scratch/ms/nl/$USER/ECEARTH-RUNS/${EXPID}/output/ifs/${LEGNB}'
export NEMORESULTS0='/scratch/ms/nl/$USER/ECEARTH-RUNS/${EXPID}/output/nemo/${LEGNB}'

# --- PROCESSING TO PERFORM (uncomment to change default)
# ECE3_POSTPROC_HC_IFS_MONTHL=1
# ECE3_POSTPROC_HC_IFS_MONTHLY_MMA=0
# ECE3_POSTPROC_HC_IFS_DAILY=0
# ECE3_POSTPROC_HC_IFS_6HRS=0
# ECE3_POSTPROC_HC_NEMO=1         # applied only if available
# ECE3_POSTPROC_HC_NEMO_EXTRA=0   # require nco

# --- Filter IFS output (to be applied through a grib_filter call)
# Useful when there are output with different timestep.
# Comment if no filtering/change for different output
#FILTERGG2D="if ( (!(typeOfLevel is \"isobaricInhPa\") && !(typeOfLevel is \"isobaricInPa\") && !(typeOfLevel is \"potentialVorticity\" ))) { write; }"
#FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") )) { write; }"
#FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"

# --- TOOLS (required programs, including compression options) -----
submit_cmd="qsub"

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
python=python

# Set this to 1 if a newer syntax is used ("cdfmean -f file ..." instead
# of "cdfmean file ..."). Set both to 1 if using version 4 of cdftools, only the second if using 3.0.1. 
newercdftools=0
newercdftools2=0

# Set to 0 for not to rebuild 3D relative humidity
rh_build=1

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="/perm/ms/nl/nm6/ECE3-DATA/post-proc"

# Base dir to archive (ie just make a copy of) the monthly results. Daily results, if any, are left behind. 
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
