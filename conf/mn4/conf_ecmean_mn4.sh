#!/bin/bash

# For autosubmit these variables must be set elsewhere (in the calling script or .bashrc)
# ECE3_POSTPROC_POSTDIR ECE3_POSTPROC_DIAGDIR

# --- PATTERN TO FIND POST-PROCESSED DATA FROM HIRESCLIM2
# 
# Must include ${EXPID} and be single-quoted
#
[[ -z ${ECE3_POSTPROC_POSTDIR:-} ]] && export ECE3_POSTPROC_POSTDIR='$SCRATCH/ECEARTH-RUNS/${EXPID}/post'

# --- TOOLS -----
# Required programs, including compression options
module purge
module load intel/2017.4 impi/2017.4 mkl/2017.4
module load netcdf hdf5 CDO/1.8.2

export cdo=cdo
export cdozip="$cdo -f nc4c -z zip"
export cdonc="$cdo -f nc"

# job scheduler submit command
submit_cmd="sbatch"
#submit_cmd="bash"

# preferred type of CDO interpolation (curvilinear grids are obliged to use bilinear)
export remap="remapcon2"
#export remap="remapbil"


# --- PROCESSING TO PERFORM (uncomment to change default)
#
# process 3D vars (most of which which are in SH files) ? 
# set to 0 if you only want simple diags e.g. Gregory plots or if using the reduced outclass
# ECE3_POSTPROC_ECM_3D_VARS=1
#
# compute clear sky fluxes, set to 0 if using the reduced outclass
# ECE3_POSTPROC_ECM_CLEAR_FLUX=1

# note : the following variables are not available when using BSC reduced output
# ssrc strc tsrc ttrc ssrc strc lcc mcc hcc ewss nsss
# various [ -f ] tests are used to ignore them
# you must also set ECE3_POSTPROC_ECM_3D_VARS=0 and ECE3_POSTPROC_ECM_CLEAR_FLUX=0
# lcc mcc and hcc will appear as N/A in the tables, others are not really important

# --- OUTPUT -----
#
# [1] Where to save the diagnostics.
#     Can include ${EXPID} and then must be single-quoted.
#     
#     Tables for one simulation will be in ${ECE3_POSTPROC_DIAGDIR}/table/${EXPID}
#     Summary tables for several simulations will be in ${ECE3_POSTPROC_DIAGDIR}/table/
#     
[[ -z ${ECE3_POSTPROC_DIAGDIR:-} ]] && export ECE3_POSTPROC_DIAGDIR='$HOME/ecearth3/diag/'

# [2] Where to save the climatology (769M IFS, 799M IFS+NEMO). 
#
# By default, if this is commented or empty, it is next to hiresclim2 monthly
# means output in the "post" dir:
# 
#     CLIMDIR=${ECE3_POSTPROC_POSTDIR}/clim-${year1}-${year2}
#
# where year1 and year2 are your script argument.
#
#CLIMDIR0=<my favorite path to store climatology data>

# [3] Where to save the extracted PIs for REPRODUCIBILITY tests
#
#     Can include ${STEMID} as ensemble ID.
#     Must be single-quoted if to be evaluated later.
#
export ECE3_POSTPROC_PI4REPRO='$HOME/ecearth3/diag/${STEMID}'

