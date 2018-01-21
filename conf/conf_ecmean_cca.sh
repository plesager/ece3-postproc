#!/bin/bash

# Required programs, including compression options
module -s load cdo

export cdo=cdo
export cdozip="$cdo -f nc4c -z zip"
export cdonc="$cdo -f nc"

# job scheduler submit command
submit_cmd="qsub"

# preferred type of CDO interpolation (curvilinear grids are obliged to use bilinear)
export remap="remapcon2"

# Where to save the table produced
export OUTDIR=${HOME}/EC-Earth3/diag/table/${exp}
mkdir -p $OUTDIR

# Where to save the climatology (769M AMIP, ??? NEMO). 
# By default, if this is commented or empty, it is in you rundir next to hiresclim2 monthly means output:
# 
#     CLIMDIR=${ECE3_POSTPROC_RUNDIR}/${exp}/post/clim
#     
# Note that it is needed for reproducibility tests for example.

#CLIMDIR=<my favorite path to store data>
