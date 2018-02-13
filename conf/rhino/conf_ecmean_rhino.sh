#!/bin/bash

# Require cdo, including compression options
export cdo=cdo
export cdozip="$cdo -f nc4c -z zip"
export cdonc="$cdo -f nc"

# job scheduler submit command
submit_cmd="sbatch"

# preferred type of CDO interpolation (curvilinear grids are obliged to use bilinear)
export remap="remapcon2"

# Where to save the table produced
export OUTDIR=${HOME}/EC-Earth/diag/table/${exp}
mkdir -p $OUTDIR

# process 3D vars (most of which which are in SH files) ? 
# set to 0 if you only want simple diags e.g. Gregory plots
export do_3d_vars=1
