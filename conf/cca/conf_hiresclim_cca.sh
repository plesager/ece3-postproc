#!/bin/bash

 ######################################
 # Configuration file for HIRESCLIM2  #
 ######################################

# For autosubmit these variables must be set elsewhere (in the calling script or .bashrc)
# IFSRESULTS0 NEMORESULTS0 ECE3_POSTPROC_POSTDIR

# --- PATTERN TO FIND MODEL OUTPUT
# 
# Must include ${EXPID} and be single-quoted
#
# optional variables: $USER, $LEGNB, $year
[[ -z ${IFSRESULTS0:-} ]] && export IFSRESULTS0='$SCRATCH/ECEARTH-RUNS/${EXPID}/output/ifs/${LEGNB}'
[[ -z ${NEMORESULTS0:-} ]] && export NEMORESULTS0='$SCRATCH/ECEARTH-RUNS/${EXPID}/output/nemo/${LEGNB}'

# --- PATTERN TO DEFINE WHERE TO SAVE POST-PROCESSED DATA
# 
# Must include ${EXPID} and be single-quoted
#
[[ -z ${ECE3_POSTPROC_POSTDIR:-} ]] && export ECE3_POSTPROC_POSTDIR='$SCRATCH/ECEARTH-RUNS/${EXPID}/post'

# --- PROCESSING TO PERFORM (uncomment to change default)
# ECE3_POSTPROC_HC_IFS_MONTHLY=1
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
rbld="/perm/ms/nl/nm6/trunk/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

cdftoolsbin="${CDFTOOLS_DIR}/bin"
python=python

# Set this to 1 if a newer syntax is used ("cdfmean -f file ..." instead
# of "cdfmean file ..."). Set both to 1 if using version 4 of cdftools, only the second if using 3.0.1. 
newercdftools=0
newercdftools2=1

# Set to 0 for not to rebuild 3D relative humidity
rh_build=1

#extension for IFS files, default ""
[[ -z ${GRB_EXT:-} ]] && GRB_EXT="" #".grb"

# number of parallel procs for IFS (max 12) and NEMO rebuild. Default to 12.
if [ -z "${IFS_NPROCS:-}" ] ; then
    IFS_NPROCS=12; NEMO_NPROCS=12
fi

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="/perm/ms/nl/nm6/ECE3-DATA/post-proc"

# Base dir to archive (ie just make a copy of) the monthly results. Daily results, if any, are left in scratch. 
STOREDIR=$SCRATCH/ecearth3/post/hiresclim/

# ---------- NEMO VAR/FILES MANGLING ----------------------

# NEMO 'wfo' variable should be in SBC files, set this flag to 0 if it is in grid_T files
export use_SBC=1

# NEMO files - which files are saved / we care for?
NEMO_SAVED_FILES="grid_T grid_U grid_V icemod"

# NEMO variables as currently named in EC-Earth output
export nm_wfo="wfo"        ; # water flux 
export nm_sst="tos"        ; # SST (2D)
export nm_sss="sos"        ; # SS salinity (2D)
export nm_ssh="zos"        ; # sea surface height (2D)
export nm_iceconc="siconc" ; # Ice concentration as in icemod file (2D)
export nm_icethic="sithic" ; # Ice thickness as in icemod file (2D)
export nm_tpot="thetao"    ; # pot. temperature (3D)
export nm_s="so"           ; # salinity (3D)
export nm_u="uo"           ; # X current (3D)
export nm_v="vo"           ; # Y current (3D)
