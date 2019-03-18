#!/usr/bin/env bash

######################################
# Configuration file for AMWG script #
######################################

# --- INPUT -----
#
# Where to find monthly averages from hiresclim (i.e. data are in $ECE3_POSTPROC_POSTDIR/mon)
# 
# Token ${USERexp} can be used to replace any part of the path through the -u
# option at the command line.  Provide a default value if making use of that
# feature.
# 
export ECE3_POSTPROC_POSTDIR='/scratch/ms/nl/${USER}/ECEARTH-RUNS/${EXPID}/post'
#
# NEMO resolution, and where to find its mesh and mask files
# 
export NEMOCONFIG="ORCA1L75"
export NEMO_MESH_DIR="/perm/ms/nl/nm6/ECE3-DATA/post-proc/$NEMOCONFIG"
#
# AMWG NCAR data
# 
export NCAR_DATA=/perm/ms/it/ccjh/ecearth3/amwg_data
export DATA_OBS="${NCAR_DATA}/obs_data_5.5"


# --- OUTPUT -----
#
# [1] Where to store all output (climatology, netcdf diag files, diagnostic plots)
#
# -- Climatology will be generated in ${EMOP_CLIM_DIR}/clim_${expname}_${YEAR1}-${YEAR2}
#      <expname>_01_climo.nc  <expname>_04_climo.nc  <expname>_07_climo.nc  <expname>_10_climo.nc  <expname>_ANN_climo.nc
#      <expname>_02_climo.nc  <expname>_05_climo.nc  <expname>_08_climo.nc  <expname>_11_climo.nc  <expname>_DJF_climo.nc
#      <expname>_03_climo.nc  <expname>_06_climo.nc  <expname>_09_climo.nc  <expname>_12_climo.nc  <expname>_JJA_climo.nc
#       
#      Each file should contain 12 monthly records for 8 3D fields and 46 2D fields !!!
#
# -- Netcdf files for the diagnostic will end up in ${EMOP_CLIM_DIR}/history/${expname}
# -- Diagnostic plots are in ${EMOP_CLIM_DIR}/diag_${expname}_${YEAR1}-${YEAR2}
#    where a TAR file (diag_${expname}.tar) is available

export EMOP_CLIM_DIR=$SCRATCH/amwg

#
#  [2] The diagnostic tar file can be put on a remote machine RHOST (login: RUSER)
#      in the WWW_DIR_ROOT/amwg/${EXPID} directory, using ssh and scp.
#       =>  Set RHOST="" to disable this functionality. (Do not comment! Used in csh script!)
export RHOST=
export RUSER=sager
export WWW_DIR_ROOT="/usr/people/sager/ECEARTH/diag"


#######################
# Required software   #
#######################
# Need a working ncdump! A couple of ideas:
# 
#  IDEA #1: load netcdf/4.3.0, but need to check that .bashrc is not loading a
#  module that conflict with netcdf/4.3.0:
#   
for mm in $(module -t list 2>&1| grep hdf5); do module unload $(echo ${mm} | sed "s|(.*||"); done
#   
#  IDEA #2: load netcdf4, but still need to check that netcdf is not loaded:
# for mm in $(module -t list 2>&1| grep netcdf); do module unload $(echo ${mm} | sed "s|(.*||"); done

for soft in netcdf/4.3.0 nco cdo python ncl cdftools
do
    if ! module -t list 2>&1 | grep -q $soft
    then
        module load $soft
    fi
done

# The CDFTOOLS set of executables should be found into:
export CDFTOOLS_BIN="${CDFTOOLS_DIR}/bin"

# The rebuild_nemo (provided with NEMO), that somebody has built (relies on flio_rbld.exe):
export RBLD_NEMO="${PERM}/trunk/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

export PYTHON=python
export cdo=cdo

# job scheduler submit command
submit_cmd="qsub"


######################################################
# List of stuffs needed for script NCARIZE_b4_AMWG.sh
######################################################

# In case of coupled simulation, for ocean fields, should we extrapolate
# sea-values over continents for cleaner plots?
#    > will use DROWN routine of SOSIE interpolation package "mask_drown_field.x"
#i_drown_ocean_fields 1 ; # 1  > do it / 0  > don't

export i_drown_ocean_fields="1" ; # 1  > do it / 0  > don't
export MESH_MASK_ORCA="mask.nc"
export SOSIE_DROWN_EXEC=

# Ocean fields:
export LIST_V_2D_OCE="sosstsst iiceconc"

# 2D Atmosphere fields (ideally):
#export LIST_V_2D_ATM="ps \
               #msl \
               #uas \
               #vas \
               #tas \
               #e stl1 \
               #tcc totp cp lsp ewss nsss sshf slhf ssrd strd \
               #ssr str tsr ttr tsrc ttrc ssrc strc lcc mcc hcc \
               #tcwv tclw tciw fal"
#
# Those we have:
export LIST_V_2D_ATM="msl uas vas tas e sp \
                tcc totp cp lsp ewss nsss sshf slhf ssrd strd \
                ssr str tsr ttr tsrc ttrc ssrc strc lcc mcc hcc \
                tcwv tclw tciw fal"

# 3D Atmosphere fields (ideally):
export LIST_V_3D_ATM="q r t u v z"

# Those we have:
#export LIST_V_3D_ATM="q t u v z"
