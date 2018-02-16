#!/bin/bash

# --- TOOLS -----
# Required programs, including compression options
module -s load cdo

export cdo=cdo
export cdozip="$cdo -f nc4c -z zip"
export cdonc="$cdo -f nc"

# job scheduler submit command
submit_cmd="qsub"

# preferred type of CDO interpolation (curvilinear grids are obliged to use bilinear)
export remap="remapcon2"


# --- PROCESS -----

# process 3D vars (most of which which are in SH files) ? 
# set to 0 if you only want simple diags e.g. Gregory plots
export do_3d_vars=1


# --- OUTPUT -----

# [1] Where to save the table produced.
#     Tables will be in the ${OUTDIR}/${exp} dir
# 
export OUTDIR=${HOME}/ECEARTH/diag/table

# [2] Where to save the climatology (769M IFS, ??? NEMO). 
#
# By default, if this is commented or empty, it is in your rundir next to
# hiresclim2 monthly means output:
# 
#     CLIMDIR=${ECE3_POSTPROC_RUNDIR}/${exp}/post/clim-${year1}-${year2}
#
# where exp, year1 and year2 are your scritp argument.
#     
# Note that the clim data are used to derived the K&S indices, but can also be
# used afterwards for reproducibility tests for example.

#CLIMDIR=<my favorite path to store climatoloy data>

