#!/usr/bin/env bash

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
[[ -z ${ECE3_POSTPROC_POSTDIR:-} ]] && export ECE3_POSTPROC_POSTDIR='/scratch/ms/nl/${USER}/ECEARTH-RUNS/${EXPID}/post'
#
# Where to find mesh and mask files for NEMO.
# Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="/gpfs/projects/bsc32/repository/ece3-postproc"

# --- OUTPUT -----
#
# [1] # Where to store time-series plots
#     Can include ${EXPID} and then must be single-quoted.
#     
#     Timeseries for one simulation will be in ${ECE3_POSTPROC_DIAGDIR}/timeseries/${EXPID}
#     available in two netCDF files and two html pages (one for atmosphere and one for ocean)
#     
#     (See also ./conf_ecmean_rhino.sh for a similar 'diagdir')
#     
[[ -z ${ECE3_POSTPROC_DIAGDIR:-} ]] && export ECE3_POSTPROC_DIAGDIR='$HOME/ecearth3/diag/'
#
#  [2] The output can be put on a remote machine RHOST (login: RUSER)
#      in the WWW_DIR_ROOT/time_series/${EXPID} directory, using ssh and scp.
#       =>  Comment or set RHOST="" to disable this function...
#export RHOST=pc170547
export RUSER=
export WWW_DIR_ROOT=


############################
# Required software   #
############################

set +xuve
module purge
module load intel/2017.4 impi/2017.4 mkl/2017.4
module load gsl netcdf hdf5 CDO/1.8.2 udunits nco python/2.7.13
module list
set -xuve

# The CDFTOOLS set of executables should be found into:
export CDFTOOLS_DIR=/gpfs/projects/bsc32/opt/cdftools-3.0.1/intel-2017.4
export CDFTOOLS_BIN="${CDFTOOLS_DIR}/bin"

# The rebuild_nemo (provided with NEMO), that somebody has built (relies on flio_rbld.exe):
export RBLD_NEMO="/gpfs/projects/bsc32/repository/apps/rebuild_nemo/rebuild_nemo"

export PYTHON=python
export cdo=cdo

# job scheduler submit command
submit_cmd="sbatch"
