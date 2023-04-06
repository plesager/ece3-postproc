#!/bin/bash

 ######################################
 # Configuration file for HIRESCLIM2  #
 ######################################

# --- PATTERN TO FIND MODEL OUTPUT
# 
# Must include $EXPID and be single-quoted
#
# Must include $LEGNB or $year
#
# Optional variable: $USERexp, which can be specified at the command
# line (witho option -u) to overwrite a default value that you specify
# here. Useful to specify any part of the path from the CLI.

export USERexp=${USERexp:-"$SCRATCH/ecearth3/"}

export IFSRESULTS0='${USERexp}/${EXPID}/output/ifs/${LEGNB}'
export NEMORESULTS0='${USERexp}/${EXPID}/output/nemo/${LEGNB}'

# --- PATTERN TO DEFINE WHERE TO SAVE POST-PROCESSED DATA
# 
# Should include ${EXPID} and be single-quoted
#
export ECE3_POSTPROC_POSTDIR='$SCRATCH/ecearth3/${EXPID}/post'

# --- PROCESSING TO PERFORM (uncomment to change default)
# ECE3_POSTPROC_HC_IFS_MONTHLY=1
# ECE3_POSTPROC_HC_IFS_MONTHLY_MMA=0
# ECE3_POSTPROC_HC_IFS_DAILY=0
# ECE3_POSTPROC_HC_IFS_6HRS=0
# ECE3_POSTPROC_HC_NEMO=1         # applied only if available
# ECE3_POSTPROC_HC_NEMO_EXTRA=0   # require nco

# --- Switch between CMIP6 (1) or default (0) output. If set to 1 (use
#      -6 when calling hc.sh), grib_filtering is applied to IFS
#      output, and NEMO file/variable names used in the
#      "ctr/cmip6-output-control-files" are expected
[[ -z ${CMIP6:-} ]] && CMIP6=0

# --- Filter IFS output (to be applied through a grib_filter call)
#      Useful when there are output with different timestep and/or level types.
#      Comment or set CMIP=0 for no filtering.

if (( CMIP6 ))
then
    FILTERGG2D="if ( param is \"182.128\" || param is \"165.128\" || param is \"166.128\" || param is \"167.128\" || param is \"31.128\" || param is \"34.128\" || param is \"141.128\" || param is \"168.128\" || param is \"164.128\" || param is \"186.128\" || param is \"187.128\" || param is \"188.128\" || param is \"78.128\" || param is \"79.128\" || param is \"137.128\" || param is \"151.128\" || param is \"243.128\" || param is \"205.128\" || param is \"144.128\" || param is \"142.128\" || param is \"143.128\" || param is \"228.128\" || param is \"176.128\" || param is \"177.128\" || param is \"146.128\" || param is \"147.128\" || param is \"178.128\" || param is \"179.128\" || param is \"180.128\" || param is \"181.128\" || param is \"169.128\" || param is \"175.128\" || param is \"208.128\" || param is \"209.128\" || param is \"210.128\" || param is \"211.128\" ) { write; }"
    FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") )) { write; }"
    FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"
fi

# --- TOOLS (required programs, including compression options) -----
# python required only to rebuild relative humidity
# nco provides ncrename used for nemo post-processing
# prgenv/intel needed because used to compile CDFTOOLS

submit_cmd="sbatch"

for soft in prgenv/intel netcdf4 python3 cdo nco
do
    if ! module -t list 2>&1 | grep -q $soft
    then
        module load $soft
    fi
done

python=python3

cdo=cdo
cdozip="$cdo -f nc4c -z zip"
rbld="$PERM/ecearth3/ec-earth3/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

# CDFtools - note that you cannot use the "cdftools light" from the barakuda package
cdftoolsbin="$PERM/CDFTOOLS/bin"

# By default the older (3.0.0) CDFTOOLS syntax is used.
# If you use version 4 or 3.0.1 (or 3.0.2), set the corresponding flag to 1.
cdftools4=1
cdftools301=0

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP=${ECE3_POSTPROC_DATADIR}/post-proc

# Set to 0 for not to rebuild 3D relative humidity (need to convert rhbuild/build_RH_new.py to python3)
rh_build=0

# Base dir to archive (ie just make a copy of) the monthly results. Daily results, if any, are left in scratch. 
STOREDIR=

# ---------- NEMO VAR/FILES MANGLING ----------------------
#
# NEMO monthly output files - Without the  <exp>_1m_YYYY0101_YYYY1231_  prefix
# 
# In some version of EC-Earth, NEMO 'wfo' variable is output in the SBC
# files. If NEMO_SBC_FILES is non-null, the script will look in that file for
# 'wfo', else it will look in the T2D file.
#
# If 3D variables on the T grid are in the same file as the 2D variables,
# specify only the NEMO_T2D_FILES.

if (( CMIP6 ))
then

    #### Herafter is a version that works with the r5717-cmip6-nemo-namelists
    #### branch (see issue #518) 
    
    NEMO_SBC_FILES=''
    NEMO_T2D_FILES="opa_grid_T_2D"
    NEMO_T3D_FILES="opa_grid_T_3D"
    NEMO_U3D_FILES="opa_grid_U_3D"
    NEMO_V3D_FILES="opa_grid_V_3D"
    LIM_T_FILES="lim_grid_T_2D"

    # variables as currently named in EC-Earth output
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

else
    #-- Default ECE-3.2.3 --#

    NEMO_SBC_FILES="SBC"
    NEMO_T2D_FILES="grid_T"
    NEMO_T3D_FILES=""
    NEMO_U3D_FILES="grid_U"
    NEMO_V3D_FILES="grid_V"
    LIM_T_FILES=icemod

    # variables as currently named in EC-Earth output
    export nm_wfo="wfo"        ; # water flux 
    export nm_sst="tos"        ; # SST (2D)
    export nm_sss="sos"        ; # SS salinity (2D)
    export nm_ssh="zos"        ; # sea surface height (2D)
    export nm_iceconc="siconc" ; # Ice concentration as in icemod file (2D)
    export nm_icethic="sithick" ; # Ice thickness as in icemod file (2D) --- ! use "sithic" for EC-Earth 3.2.3, and "sithick" for PRIMAVERA
    export nm_tpot="thetao"    ; # pot. temperature (3D)
    export nm_s="so"           ; # salinity (3D)
    export nm_u="uo"           ; # X current (3D)
    export nm_v="vo"           ; # Y current (3D)
fi
