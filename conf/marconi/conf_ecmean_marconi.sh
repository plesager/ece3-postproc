#!/bin/bash

# --- TOOLS -----
# Required programs, including compression options
module unload cdo hdf5 netcdf python numpy
module load  hdf5/1.8.17--intel--pe-xe-2017--binary netcdf/4.4.1--intel--pe-xe-2017--binary cdo  python/2.7.12 numpy/1.11.2--python--2.7.12 nco/4.6.7

# --- PATTERN TO FIND POST-PROCESSED DATA FROM HIRESCLIM2
# 
# Must include ${EXPID} and be single-quoted
#
export ECE3_POSTPROC_POSTDIR='${CINECA_SCRATCH}/ece3/${EXPID}/post'


# --- TOOLS -----
# Required programs, including compression options
cdo="/cineca/prod/opt/tools/cdo/1.8.2/intel--pe-xe-2017--binary/bin/cdo -L"

export cdo=cdo
export cdozip="$cdo -f nc4c -z zip"
export cdonc="$cdo -f nc"

# job scheduler submit command
export submit_cmd="sbatch"

#preferred type of CDO interpolation (curvilinear grids are obliged to use bilinear)
export remap="remapcon2"


# --- PROCESS -----
#
# process 3D vars (most of which which are in SH files) ? 
# set to 0 if you only want simple diags e.g. Gregory plots
export do_3d_vars=1


# --- OUTPUT -----
#
# [1] Where to save the diagnostics.
#     Can include ${EXPID} and then must be single-quoted.
#     
#     Tables for one simulation will be in ${ECE3_POSTPROC_DIAGDIR}/table/${EXPID}
#     Summary tables for several simulations will be in ${ECE3_POSTPROC_DIAGDIR}/table/
#     
export ECE3_POSTPROC_DIAGDIR='$HOME/ecearth3/diag'

# [2] Where to save the climatology (769M IFS, 799M IFS+NEMO). 
#
# By default, if this is commented or empty, it is next to hiresclim2 monthly
# means output in the "post" dir:
# 
#     CLIMDIR=${ECE3_POSTPROC_POSTDIR}/clim-${year1}-${year2}
#
# where year1 and year2 are your script argument.
#
#CLIMDIR0=<my favorite path to store climatoloy data>
export CLIMDIR0='${CINECA_SCRATCH}/tmp/${EXPID}/post/model2x2_${year1}_${year2}'


# [3] Where to save the extracted PIs for REPRODUCIBILITY tests
#
#     Can include ${STEMID} as ensemble ID.
#     Must be single-quoted if to be evaluated later.
#
export ECE3_POSTPROC_PI4REPRO='$HOME/ecearth3/diag/${STEMID}'
