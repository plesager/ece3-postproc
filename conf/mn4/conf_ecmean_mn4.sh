#!/bin/bash

# Required programs, including compression options
module purge
module load intel/2017.4 impi/2017.4 mkl/2017.4
module load netcdf hdf5 CDO/1.8.2

export cdo=cdo
export cdozip="$cdo -f nc4c -z zip"
export cdonc="$cdo -f nc"

# job scheduler submit command
submit_cmd="sbatch"

# preferred type of CDO interpolation (curvilinear grids are obliged to use bilinear)
export remap="remapcon2"
#export remap="remapbil"

# Where to save the table produced. Tables will be in the ${OUTDIR}/${exp} dir
export OUTDIR=${HOME}/ecearth3/diag/table

# Where to save the climatology (769M AMIP, ??? NEMO). 
# By default, if this is commented or empty, it is in you rundir next to hiresclim2 monthly means output:
# 
#     CLIMDIR=${ECE3_POSTPROC_RUNDIR}/${exp}/post/clim-${year1}-${year2}
#
# where exp, year1 and year2 are your scritp argument.
#     
# Note that it is needed for reproducibility tests for example.

#CLIMDIR=<my favorite path to store climatoloy data>

# process 3D vars (most of which which are in SH files) ? 
# set to 0 if you only want simple diags e.g. Gregory plots
export do_3d_vars=1
