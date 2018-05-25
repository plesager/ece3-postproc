#!/bin/bash

########################################
# Configuration file for ECMEAN script #
########################################

# --- INPUT -----
#
# Where to find monthly averages from hiresclim (i.e. data are in $ECE3_POSTPROC_POSTDIR/mon)
# 
# Must include ${EXPID} and be single-quoted
#
# Token ${USERexp} can be used (and set through -u option at the command line).
# Provide default if using it. 
# 
[[ -z ${ECE3_POSTPROC_POSTDIR:-} ]] && export ECE3_POSTPROC_POSTDIR='$SCRATCH/ECEARTH-RUNS/${EXPID}/post'

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
#     This is used only by the reproducibility/collect_ens.sh script
#
export ECE3_POSTPROC_PI4REPRO='$HOME/ecearth3/diag/${STEMID}'

