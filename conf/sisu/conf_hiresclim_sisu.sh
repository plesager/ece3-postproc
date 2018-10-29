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
export IFSRESULTS0='/wrk/${USER}/ece-3.2.3-r/classic/${EXPID}/output/ifs/${LEGNB}'
export NEMORESULTS0='/wrk/${USER}/ece-3.2.3-r/classic/${EXPID}/output/nemo/${LEGNB}'

# --- PATTERN TO DEFINE WHERE TO SAVE POST-PROCESSED DATA
# 
# Should include ${EXPID} and be single-quoted
#
export ECE3_POSTPROC_POSTDIR='/wrk/${USER}/ece-3.2.3-r/classic/post/${EXPID}'
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
#export FILTERGG2D="if ( (!(typeOfLevel is \"isobaricInhPa\") && !(typeOfLevel is \"isobaricInPa\") && !(typeOfLevel is \"potentialVorticity\" ) && ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800))) ) { write; }"
#export FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") && ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) ))) { write; }"
#export FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"


# --- TOOLS (required programs, including compression options) -----
# Load python environment
module load python

submit_cmd="sbatch"

export cdo="$USERAPPL/bioconda_env/nctools/bin/cdo"
shopt -s expand_aliases    
alias cdo="$USERAPPL/bioconda_env/nctools/bin/cdo"
alias ncrename="$USERAPPL/bioconda_env/nco/bin/ncrename"
alias ncdump="$USERAPPL/bioconda_env/nco/bin/ncdump"
alias ncks="$USERAPPL/bioconda_env/nco/bin/ncks"

cdozip="$cdo -f nc4c -z zip"
rbld="$USERAPPL/NEMO-tools/TOOLS/REBUILD_NEMO/rebuild_nemo"
python=python

# CDFtools - note that you cannot use the "cdftools light" from the barakuda package
cdftoolsbin="$USERAPPL/CDFTOOLS/bin"

# By default the older (3.0.0) CDFTOOLS syntax is used.
# If you use version 4 or 3.0.1 (or 3.0.2), set the corresponding flag to 1.
cdftools4=0
cdftools301=1

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP=${ECE3_POSTPROC_DATADIR}/post-proc

# Set to 0 for not to rebuild 3D relative humidity
rh_build=1

# Base dir to archive (ie just make a copy of) the monthly results. Daily results, if any, are left in scratch. 
STOREDIR=

IFS_NPROCS=12 
NEMO_NPROCS=12

# ---------- NEMO VAR/FILES MANGLING ----------------------

# NEMO monthly output files - Without the  <exp>_1m_YYYY0101_YYYY1231_  prefix
# 
# In some version of EC-Earth, NEMO 'wfo' variable is output in the SBC
# files. If NEMO_SBC_FILES is non-null, the script will look in that file for
# 'wfo', else it will look in the T2D file.
#
# If 3D variables on the T grid are in the same file as the 2D variables,
# specify only the NEMO_T2D_FILES.

NEMO_SBC_FILES="SBC"
NEMO_T2D_FILES="grid_T"
NEMO_T3D_FILES=""
NEMO_U3D_FILES="grid_U"
NEMO_V3D_FILES="grid_V"
LIM_T_FILES=icemod

# NEMO variables as currently named in EC-Earth output
export nm_wfo="wfo"         ; # water flux 
export nm_sst="tos"         ; # SST (2D)
export nm_sss="sos"         ; # SS salinity (2D)
export nm_ssh="zos"         ; # sea surface height (2D)
export nm_iceconc="siconc"  ; # Ice concentration as in icemod file (2D)
export nm_icethic="sithic"  ; # Ice thickness as in icemod file (2D)  --- ! use "sithic" for EC-Earth 3.2.3, and "sithick" for PRIMAVERA
export nm_tpot="thetao"     ; # pot. temperature (3D)
export nm_s="so"            ; # salinity (3D)
export nm_u="uo"            ; # X current (3D)
export nm_v="vo"            ; # Y current (3D)

#--CMIP6--#  #### Herafter is a version that works with the branch
#--CMIP6--#  #### r5717-cmip6-nemo-namelists (see issue #518)
#--CMIP6--#   
#--CMIP6--#  # NEMO monthly output files - Without the  <exp>_1m_YYYY0101_YYYY1231_  prefix
#--CMIP6--#  # 
#--CMIP6--#  # In some version of EC-Earth, NEMO 'wfo' variable is output in the SBC
#--CMIP6--#  # files. If NEMO_SBC_FILES is non-null, the script will look in that file for
#--CMIP6--#  # 'wfo', else it will look in the T2D file.
#--CMIP6--#   
#--CMIP6--#  NEMO_SBC_FILES=''
#--CMIP6--#  NEMO_T2D_FILES="opa_grid_T_2D"
#--CMIP6--#  NEMO_T3D_FILES="opa_grid_T_3D"
#--CMIP6--#  NEMO_U3D_FILES="opa_grid_U_3D"
#--CMIP6--#  NEMO_V3D_FILES="opa_grid_V_3D"
#--CMIP6--#  LIM_T_FILES="lim_grid_T_2D"
#--CMIP6--#   
#--CMIP6--#  # NEMO variables as currently named in EC-Earth output
#--CMIP6--#  export nm_wfo="wfonocorr"  ; # water flux                               [opa_grid_T_2D]
#--CMIP6--#  export nm_sst="tos"        ; # SST (2D)                                 [opa_grid_T_2D]
#--CMIP6--#  export nm_sss="sos"        ; # SS salinity (2D)                         [opa_grid_T_2D]
#--CMIP6--#  export nm_ssh="zos"        ; # sea surface height (2D)                  [opa_grid_T_2D]
#--CMIP6--#  export nm_iceconc="siconc" ; # Ice concentration as in icemod file (2D) [lim_grid_T_2D]
#--CMIP6--#  export nm_icethic="sithick"; # Ice thickness as in icemod file (2D)     [lim_grid_T_2D]
#--CMIP6--#  export nm_tpot="thetao"    ; # pot. temperature (3D)                    [opa_grid_T_3D]
#--CMIP6--#  export nm_s="so"           ; # salinity (3D)                            [opa_grid_T_3D]
#--CMIP6--#  export nm_u="uo"           ; # X current (3D)                           [opa_grid_U_3D]
#--CMIP6--#  export nm_v="vo"           ; # Y current (3D)                           [opa_grid_V_3D]
