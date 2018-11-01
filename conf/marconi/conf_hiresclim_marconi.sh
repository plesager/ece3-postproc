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
# optional variable are $USERexp/$USER, $LEGNB, $year
export ${USERexp:=$USER}
export IFSRESULTS0='/marconi_scratch/userexternal/${USERexp}/ece3/${EXPID}/output/Output_${year}/IFS'
export NEMORESULTS0='/marconi_scratch/userexternal/${USERexp}/ece3/${EXPID}/output/Output_${year}/NEMO'

# --- PATTERN TO DEFINE WHERE TO SAVE POST-PROCESSED DATA
# 
# Must include ${EXPID} and be single-quoted
#
export ECE3_POSTPROC_POSTDIR='/marconi_scratch/userexternal/${USER}/ece3/${EXPID}/post'

# --- PROCESSING TO PERFORM (uncomment to change default)
# ECE3_POSTPROC_HC_IFS_MONTHLY=1
# ECE3_POSTPROC_HC_IFS_MONTHLY_MMA=0
# ECE3_POSTPROC_HC_IFS_DAILY=0
# ECE3_POSTPROC_HC_IFS_6HRS=0
# ECE3_POSTPROC_HC_NEMO=1         # applied only if available
# ECE3_POSTPROC_HC_NEMO_EXTRA=0   # require nco

# --- Switch between CMIP6 (1) or default (0) output. If set to 1,
#      grib_filtering is applied, and NEMO files/variable name from
#      r5717-cmip6-nemo-namelists are used.
CMIP6=1

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
cdftoolsbin="$WORK/opt/bin"
python=python

# By default the older (3.0.0) CDFTOOLS syntax is used.
# If you use version 4 or 3.0.1 (or 3.0.2), set the corresponding flag to 1.
cdftools4=0
cdftools301=0

# Set to 0 for not to rebuild 3D relative humidity
rh_build=1

# number of parallel procs for IFS (max 12) and NEMO rebuild
#if [[ -z $IFS_NPROCS ]] ; then
IFS_NPROCS=12; NEMO_NPROCS=12
#fi

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
    export nm_icethic="sithic" ; # Ice thickness as in icemod file (2D) --- ! use "sithic" for EC-Earth 3.2.3, and "sithick" for PRIMAVERA
    export nm_tpot="thetao"    ; # pot. temperature (3D)
    export nm_s="so"           ; # salinity (3D)
    export nm_u="uo"           ; # X current (3D)
    export nm_v="vo"           ; # Y current (3D)
fi
