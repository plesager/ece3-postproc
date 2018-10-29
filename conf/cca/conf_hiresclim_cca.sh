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

# to avoid using ncdump that comes with HDF4 if loaded
module unload hdf

# for a working ncdump, remove modules that may be in the way and load
# recommended netcdf4
for mm in $(module -t list 2>&1| grep hdf5); do module unload $(echo ${mm} | sed "s|(.*||"); done
module load netcdf4/4.4.1

for soft in netcdf python cdo cdftools
do
    if ! module -t list 2>&1 | grep -q $soft
    then
        module load $soft
    fi
done
module unload nco
module load nco/4.3.7

cdo=cdo
cdozip="$cdo -f nc4c -z zip"
rbld="/perm/ms/nl/nm6/trunk/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

cdftoolsbin="${CDFTOOLS_DIR}/bin"
python=python

# Set this to 1 if a newer syntax is used ("cdfmean -f file ..." instead
# of "cdfmean file ..."). Set both to 1 if using version 4 of cdftools, only the second if using 3.0.1. 
cdftools4=0
cdftools301=0

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

# NEMO monthly output files - Without the  <exp>_1m_YYYY0101_YYYY1231_  prefix
# 
# In some version of EC-Earth, NEMO 'wfo' variable is output in the SBC
# files. If NEMO_SBC_FILES is non-null, the script will look in that file for
# 'wfo', else it will look in the T2D file.
#
# If 3D variables on the T grid are in the same file as the 2D variables,
# specify only the NEMO_T2D_FILES.
 
#-- ECE-3.2.3 --#  NEMO_SBC_FILES="SBC"
#-- ECE-3.2.3 --#  NEMO_T2D_FILES="grid_T"
#-- ECE-3.2.3 --#  NEMO_T3D_FILES=""
#-- ECE-3.2.3 --#  NEMO_U3D_FILES="grid_U"
#-- ECE-3.2.3 --#  NEMO_V3D_FILES="grid_V"
#-- ECE-3.2.3 --#  LIM_T_FILES=icemod
#-- ECE-3.2.3 --#  
#-- ECE-3.2.3 --#  # NEMO variables as currently named in EC-Earth output
#-- ECE-3.2.3 --#  export nm_wfo="wfo"        ; # water flux 
#-- ECE-3.2.3 --#  export nm_sst="tos"        ; # SST (2D)
#-- ECE-3.2.3 --#  export nm_sss="sos"        ; # SS salinity (2D)
#-- ECE-3.2.3 --#  export nm_ssh="zos"        ; # sea surface height (2D)
#-- ECE-3.2.3 --#  export nm_iceconc="siconc" ; # Ice concentration as in icemod file (2D)
#-- ECE-3.2.3 --#  export nm_icethic="sithic" ; # Ice thickness as in icemod file (2D) --- ! use "sithic" for EC-Earth 3.2.3, and "sithick" for PRIMAVERA
#-- ECE-3.2.3 --#  export nm_tpot="thetao"    ; # pot. temperature (3D)
#-- ECE-3.2.3 --#  export nm_s="so"           ; # salinity (3D)
#-- ECE-3.2.3 --#  export nm_u="uo"           ; # X current (3D)
#-- ECE-3.2.3 --#  export nm_v="vo"           ; # Y current (3D)


#### Herafter is a version that works with the branch
#### r5717-cmip6-nemo-namelists (see issue #518)

# NEMO monthly output files - Without the  <exp>_1m_YYYY0101_YYYY1231_  prefix
# 
# In some version of EC-Earth, NEMO 'wfo' variable is output in the SBC
# files. If NEMO_SBC_FILES is non-null, the script will look in that file for
# 'wfo', else it will look in the T2D file.
 
NEMO_SBC_FILES=''
NEMO_T2D_FILES="opa_grid_T_2D"
NEMO_T3D_FILES="opa_grid_T_3D"
NEMO_U3D_FILES="opa_grid_U_3D"
NEMO_V3D_FILES="opa_grid_V_3D"
LIM_T_FILES="lim_grid_T_2D"

# NEMO variables as currently named in EC-Earth output
export nm_wfo="wfonocorr"  ; # water flux                               [opa_grid_T_2D]
export nm_sst="tos"        ; # SST (2D)                                 [opa_grid_T_2D]
export nm_sss="sos"        ; # SS salinity (2D)                         [opa_grid_T_2D]
export nm_ssh="zos"        ; # sea surface height (2D)                  [opa_grid_T_2D]
export nm_iceconc="siconc" ; # Ice concentration as in icemod file (2D) [lim_grid_T_2D]
export nm_icethic="sithick"; # Ice thickness as in icemod file (2D)     [lim_grid_T_2D]
export nm_tpot="thetao"    ; # pot. temperature (3D)                    [opa_grid_T_3D]
export nm_s="so"           ; # salinity (3D)                            [opa_grid_T_3D]
export nm_u="uo"           ; # X current (3D)                           [opa_grid_U_3D]
export nm_v="vo"           ; # Y current (3D)                           [opa_grid_V_3D]
