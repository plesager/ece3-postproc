#!/bin/bash

 ######################################
 # Configuration file for HIRESCLIM2  #
 ######################################

# --- PATTERN TO FIND MODEL OUTPUT
# 
# Must include $EXPID and be single-quoted
#
# optional variable are $USER, $LEGNB, $year
#
export IFSRESULTS0='/lustre3/projects/PRIMAVERA/${USER}/ecearth3/${EXPID}/output/ifs/${LEGNB}'
export NEMORESULTS0='/lustre3/projects/PRIMAVERA/${USER}/ecearth3/${EXPID}/output/nemo/${LEGNB}'

# --- PATTERN TO DEFINE WHERE TO SAVE POST-PROCESSED DATA
# 
# Should include ${EXPID} and be single-quoted
#
export ECE3_POSTPROC_POSTDIR='/lustre3/projects/CMIP6/${USER}/rundirs/${EXPID}/post'

# --- PROCESSING TO PERFORM (uncomment to change default)
# ECE3_POSTPROC_HC_IFS_MONTHLY=1
# ECE3_POSTPROC_HC_IFS_MONTHLY_MMA=0
# ECE3_POSTPROC_HC_IFS_DAILY=0
# ECE3_POSTPROC_HC_IFS_6HRS=0
# ECE3_POSTPROC_HC_NEMO=1         # applied only if available
# ECE3_POSTPROC_HC_NEMO_EXTRA=0   # require nco

# -- Filter IFS output (to be applied through a grib_filter call)
# Useful when there is output with mixed timestep and/or levels
# Comment if no filtering/change for different output
# 
#  The following will screen out model levels and 3-hourly data
#  from default Primavera output:
export FILTERGG2D="if ( (!(typeOfLevel is \"isobaricInhPa\") && !(typeOfLevel is \"isobaricInPa\") && !(typeOfLevel is \"potentialVorticity\" ) && ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800))) ) { write; }"
export FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") && ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) ))) { write; }"
export FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"


# --- TOOLS (required programs, including compression options) -----
submit_cmd="sbatch"

cdo=cdo
cdozip="$cdo -f nc4c -z zip"
rbld="/nfs/home/users/sager/primavera/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"
python=/nfs/home/users/sager/anaconda2/bin/python

# CDFtools - note that you cannot use the "cdftools light" from the barakuda package
cdftoolsbin="/nfs/home/users/sager/installed/CDFTOOLS/bin"

# By default the older (3.0.0) CDFTOOLS syntax is used.
# If you use version 4 or 3.0.1 (or 3.0.2), set the corresponding flag to 1.
cdftools4=1
cdftools301=0

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP=${ECE3_POSTPROC_DATADIR}/post-proc

# Set to 0 for not to rebuild 3D relative humidity
rh_build=1

# Base dir to archive (ie just make a copy of) the monthly results. Daily results, if any, are left in scratch. 
STOREDIR=

# ---------- NEMO VAR/FILES MANGLING ----------------------

# NEMO 'wfo' variable can be in the SBC files instead of T files, then
# set this flag to 1
export use_SBC=1

# NEMO files - which files are saved / we care for?
NEMO_SAVED_FILES="grid_T grid_U grid_V icemod"

# NEMO variables as currently named in EC-Earth output
export nm_wfo="wfo"         ; # water flux 
export nm_sst="tos"         ; # SST (2D)
export nm_sss="sos"         ; # SS salinity (2D)
export nm_ssh="zos"         ; # sea surface height (2D)
export nm_iceconc="siconc"  ; # Ice concentration as in icemod file (2D)
export nm_icethic="sithick" ; # Ice thickness as in icemod file (2D)  --- ! use "sithic" for EC-Earth 3.2.3, and "sithick" for PRIMAVERA
export nm_tpot="thetao"     ; # pot. temperature (3D)
export nm_s="so"            ; # salinity (3D)
export nm_u="uo"            ; # X current (3D)
export nm_v="vo"            ; # Y current (3D)
