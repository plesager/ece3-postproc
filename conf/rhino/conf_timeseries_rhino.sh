#!/usr/bin/bash

#############################################
# Configuration file for timeseries script  #
#############################################

# --- INPUT -----
#
# Where to find monthly averages from hireclim (i.e. data are in $ECE3_POSTPROC_POSTDIR/mon)
# 
# Token ${USERexp} can be used (and set through -u option at the command line).
# Provide default if using it. 
# 
export ECE3_POSTPROC_POSTDIR='/lustre3/projects/CMIP6/${USER}/rundirs/${EXPID}/post'
#
# Where to find mesh and mask files for NEMO.
# Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP=${ECE3_POSTPROC_DATADIR}/post-proc

# --- OUTPUT -----
#
# [1] # Where to store time-series plots
#     Can include ${EXPID} and then must be single-quoted.
#     
#     Timeseries for one simulation will be in ${ECE3_POSTPROC_DIAGDIR}/${EXPID}
#     See ./conf_ecmean_rhino.sh
#     
export ECE3_POSTPROC_DIAGDIR="$HOME/EC-Earth/diag/"


######################
# Required software  #
######################
#  nco netcdf python cdo cdftools

# The CDFTOOLS set of executables should be found into:
export CDFTOOLS_BIN="/nfs/home/users/sager/installed/CDFTOOLS/bin"

# The rebuild_nemo (provided with NEMO), that somebody has built (relies on flio_rbld.exe):
export RBLD_NEMO="/nfs/home/users/sager/primavera/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

export PYTHON=/nfs/home/users/sager/anaconda2/bin/python
export cdo=cdo

# job scheduler submit command
submit_cmd="sbatch"
