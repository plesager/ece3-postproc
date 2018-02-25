#!/bin/ksh

 ###############################################################################
 # Configuration file for timeseries script                                    #
 #                                                                             #
 # Add here machine dependent set up that do NOT necessarily depends on any of #
 #    the following sticky general user settings:                              #
 #    ECE3_POSTPROC_TOPDIR, ECE3_POSTPROC_RUNDIR, or ECE3_POSTPROC_DATADIR     #
 ###############################################################################

# Where to store produced time-series (<RUN>, if used, is replaced by the experiment 4-letter name)

#export EMOP_CLIM_DIR=${HOME}/ecearth3/diag/
#mkdir -p $EMOP_CLIM_DIR
#export DIR_TIME_SERIES="${EMOP_CLIM_DIR}/timeseries/<RUN>"

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="/gpfs/projects/bsc32/bsc32051/ECE3-DATA/post-proc"

# About web page, on remote server host:
#     =>  set RHOST="" to disable this function...
export RHOST=""
export RUSER=""
export WWW_DIR_ROOT=""

############################
# Required software   #
############################

set +xuve
module purge
module load intel/2017.4 impi/2017.4 mkl/2017.4
module load gsl netcdf hdf5 CDO/1.8.2 udunits nco python/2.7.13
module list
set -xuve
export CDFTOOLS_DIR=/gpfs/projects/bsc32/opt/cdftools-2.1/intel-13/bin

# support for GRIB_API?
# Set the directory where the GRIB_API tools are installed
# Note: cdo had to be compiled with GRIB_API support for this to work
# This is only required if your highest level is above 1 hPa,
# otherwise leave GRIB_API_BIN empty (or just comment the line)!
# export GRIB_API_BIN="/home/john/bin"

# The CDFTOOLS set of executables should be found into:
export CDFTOOLS_BIN="${CDFTOOLS_DIR}/bin"

# The rebuild_nemo (provided with NEMO), that somebody has built (relies on flio_rbld.exe):
export RBLD_NEMO="/gpfs/projects/bsc32/repository/apps/rebuild_nemo/rebuild_nemo"

export PYTHON=python
export cdo=cdo
export NCAP=ncap
