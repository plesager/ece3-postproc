#!/bin/bash

set -xuve 

 ######################################
 # Configuration file for HIRESCLIM2  #
 ######################################

# For autosubmit these variables must be set elsewhere (in the calling script or .bashrc)
# IFSRESULTS0 NEMORESULTS0 ECE3_POSTPROC_POSTDIR

# --- PATTERN TO FIND MODEL OUTPUT
# 
# Must include $EXPID and be single-quoted
#
# optional variable are $USER, $LEGNB, $year
#export IFSRESULTS0='/scratch/ms/nl/$USER/ECEARTH-RUNS/${EXPID}/output/ifs/${LEGNB}'
#export NEMORESULTS0='/scratch/ms/nl/$USER/ECEARTH-RUNS/${EXPID}/output/nemo/${LEGNB}'

# --- PATTERN TO DEFINE WHERE TO SAVE POST-PROCESSED DATA
# 
# Must include ${EXPID} and be single-quoted
#
#export ECE3_POSTPROC_POSTDIR='$SCRATCHUSER}/ECEARTH-RUNS/${EXPID}/post'

# --- PROCESSING TO PERFORM (uncomment to change default)
# ECE3_POSTPROC_HC_IFS_MONTHLY=1
# ECE3_POSTPROC_HC_IFS_MONTHLY_MMA=0
# ECE3_POSTPROC_HC_IFS_DAILY=0
# ECE3_POSTPROC_HC_IFS_6HRS=0
# ECE3_POSTPROC_HC_NEMO=1         # applied only if available
# ECE3_POSTPROC_HC_NEMO_EXTRA=0   # require nco

# -- Filter IFS output (to be applied through a grib_filter call)
# Useful when there are output with different timestep.
# Set to empty if no filtering/change for different output
#FILTERGG2D="if ( (!(typeOfLevel is \"isobaricInhPa\") && !(typeOfLevel is \"isobaricInPa\") && !(typeOfLevel is \"potentialVorticity\" ))) { write; }"
#FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") )) { write; }"
#FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"
FILTERGG2D=""
FILTERGG3D=""
FILTERSH=""

# --- TOOLS (required programs, including compression options) -----

#submit_cmd="sbatch"
submit_cmd="bash"

# required programs, including compression options
module purge
module load intel/2017.4 impi/2017.4 mkl/2017.4
module load gsl grib netcdf hdf5 CDO/1.8.2 udunits nco python/2.7.13
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

#extension for IFS files, default ""
GRB_EXT=".grb"

# number of parallel procs for IFS (max 12) and NEMO rebuild. Default to 12.
if [ -z "${IFS_NPROCS:-}" ] ; then
    IFS_NPROCS=12; NEMO_NPROCS=12
fi

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="/gpfs/projects/bsc32/repository/ece3-postproc"

# Base dir to archive (ie just make a copy of) the monthly results. Daily results, if any, are left in scratch. 
STOREDIR=$SCRATCH/ecearth3/post/hiresclim/

# ---------- NEMO VAR/FILES MANGLING ----------------------

# NEMO 'wfo' variable can be in the SBC files instead of T files, then
# set this flag to 1
export use_SBC=0

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
