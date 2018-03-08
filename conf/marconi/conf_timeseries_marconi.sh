#!/bin/bash


# --- TOOLS -----
# Required programs, including compression options
module unload cdo hdf5 netcdf python numpy
module load hdf5/1.8.17--intel--pe-xe-2017--binary netcdf/4.4.1--intel--pe-xe-2017--binary cdo python/2.7.12 numpy/1.11.2--python--2.7.12

export ${USERexp:=$USER}
export ECE3_POSTPROC_DIAGDIR='$HOME/ecearth3/diag'
export ECE3_POSTPROC_POSTDIR='/marconi_scratch/userexternal/${USER}/ece3/${EXPID}/post'
export MESHDIR_TOP="/marconi_work/Pra13_3311/ecearth3/nemo"


# The CDFTOOLS set of executables should be found into:
export CDFTOOLS_BIN="$WORK/opt/bin"

# The scrip "rebuild" as provided with NEMO (relies on flio_rbld.exe):
export RBLD_NEMO="$WORK/ecearth3/rebuild_nemo/rebuild_nemo"

#python
export PYTHON="python"

# job scheduler submit command
submit_cmd="sbatch"


