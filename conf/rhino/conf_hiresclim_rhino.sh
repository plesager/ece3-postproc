#!/bin/bash

# Configuration file for hiresclim script
# 
# Add here machine dependent set up that do NOT necessarily depends on any of
#    the following general user settings:
#    ECE3_POSTPROC_TOPDIR, ECE3_POSTPROC_RUNDIR, or ECE3_POSTPROC_DATADIR

submit_cmd="sbatch"

cdo=cdo
cdozip="$cdo -f nc4c -z zip"
rbld="/nfs/home/users/sager/primavera/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"
python=python

# CDFtools - note that you cannot use the "cdftools light" from the barakuda package
cdftoolsbin="/nfs/home/users/sager/installed/CDFTOOLS/bin"

# Set this to 1 if a newer syntax is used ("cdfmean -f file ..." instead
# of "cdfmean file ..."). 
newercdftools=1
newercdftools2=1

# number of parallel procs for IFS (max 12) and NEMO rebuild. Default to 12.
if [ -z $IFS_NPROCS ] ; then
    IFS_NPROCS=12; NEMO_NPROCS=12
fi

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP=${ECE3_POSTPROC_DATADIR}/post-proc

# NEMO 'wfo' variable can be in the SBC files instead of T files, then
# set this flag to 1
export use_SBC=1

# Set to 0 for not to rebuild 3D relative humidity
rh_build=0

# Base dir to archive (ie just make a copy of) the monthly results. Daily results, if any, are left in scratch. 
STOREDIR=
