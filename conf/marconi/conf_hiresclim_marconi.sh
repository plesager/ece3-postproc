#!/bin/bash

# configuration file for hiresclim script
# add here machine dependent set up
# It expects USER* variables defined in conf_users.sh

 ######################################
 # Configuration file for HIRESCLIM2  #
 ######################################

# --- PATTERN TO FIND MODEL OUTPUT
# 
# Must include $EXPID and be single-quoted
#
# optional variable are $USER*, $LEGNB, $year
export IFSRESULTS0='/marconi_scratch/userexternal/${USERexp}/ece3/${EXPID}/output/Output_${year}/IFS'
export NEMORESULTS0='/marconi_scratch/userexternal/${USERexp}/ece3/${EXPID}/output/Output_${year}/NEMO'

# --- PATTERN TO DEFINE WHERE TO SAVE POST-PROCESSED DATA
# 
# Must include ${EXPID} and be single-quoted
#
export ECE3_POSTPROC_POSTDIR='/marconi_scratch/userexternal/${USERme}/ece3/${EXPID}/post'

# --- PROCESSING TO PERFORM (uncomment to change default)
# ECE3_POSTPROC_HC_IFS_MONTHL=1
# ECE3_POSTPROC_HC_IFS_MONTHLY_MMA=0
# ECE3_POSTPROC_HC_IFS_DAILY=0
# ECE3_POSTPROC_HC_IFS_6HRS=0
# ECE3_POSTPROC_HC_NEMO=1         # applied only if available
# ECE3_POSTPROC_HC_NEMO_EXTRA=0   # require nco

# --- Filter IFS output (to be applied through a grib_filter call)
# Comment if no filtering/change for different output
FILTERGG2D="if ( (!(typeOfLevel is \"isobaricInhPa\") && !(typeOfLevel is \"isobaricInPa\") && !(typeOfLevel is \"potentialVorticity\" ))) { write; }"
FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") )) { write; }"
FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"

# --- TOOLS (required programs, including compression options) -----

#scheduler
submit_cmd="sbatch"

# required programs, including compression options
module unload netcdf hdf5

for soft in hdf5/1.8.17--intel--pe-xe-2017--binary netcdf/4.4.1--intel--pe-xe-2017--binary nco python cdo
do
    if ! module -t list 2>&1 | grep -q $soft
    then
        module load $soft
    fi
done

# required programs, including compression options
#cdo="$ROOT/$USER0/opt/bin/cdo -L"
cdo=cdo
cdozip="$cdo -f nc4c -z zip"
rbld="$WORK/ecearth3/rebuild_nemo/rebuild_nemo"
cdftoolsbin="$WORK/cdftools/3.0/bin"
python=python

# number of parallel procs for IFS (max 12) and NEMO rebuild
if [[ -z $IFS_NPROCS ]] ; then
    IFS_NPROCS=12; NEMO_NPROCS=12
fi

# NEMO resolution
#if [ -z $NEMOCONFIG ] ; then
#Export NEMOCONFIG="ORCA1L75"
#fi

# where to find mesh and mask files 
export MESHDIR_TOP=/marconi_work/Pra13_3311/ecearth3/nemo

# where to find the results from the EC-EARTH experiment
# On our machine Nemo and IFS results are in separate directories
#export BASERESULTS=/marconi_scratch/userexternal/$USERexp/ece3/$expname/output

# cdo table for conversion GRIB parameter --> variable name
#export ecearth_table=$PROGDIR/script/ecearth.tab

# ---------- NEMO VAR/FILES MANGLING ----------------------

# NEMO files
export NEMO_SAVED_FILES="grid_T grid_U grid_V icemod grid_W" ; # which files are saved / we care for?

# NEMO variables
export nm_wfo="wfo"        ; # water flux 
export nm_sst="tos"        ; # SST (2D)
export nm_sss="sos"        ; # SS salinity (2D)
export nm_ssh="zos"        ; # sea surface height (2D)
export nm_iceconc="siconc" ; # Ice concentration as in icemod file (2D)
#export nm_icethic="sithick" ; # Ice thickness as in icemod file (2D)
export nm_icethic="sithic" ; # Ice thickness as in icemod file (2D)
export nm_tpot="thetao"    ; # pot. temperature (3D)
export nm_s="so"           ; # salinity (3D)
export nm_u="uo"           ; # X current (3D)
export nm_v="vo"           ; # Y current (3D)
