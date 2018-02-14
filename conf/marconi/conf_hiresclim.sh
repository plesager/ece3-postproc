#!/bin/bash

# configuration file for hiresclim script
# add here machine dependent set up
# It expects USER* variables defined in conf_users.sh

############################
#---standard definitions---#
############################

JOBMAXHOURS=24

# Comment if no filtering/change for different output
FILTERGG2D="if ( (!(typeOfLevel is \"isobaricInhPa\") && !(typeOfLevel is \"isobaricInPa\") && !(typeOfLevel is \"potentialVorticity\" ))) { write; }"
FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") )) { write; }"
FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"

ROOT=/marconi/home/userexternal/$USER0
#program folder
if [ -z $PROGDIR ] ; then
PROGDIR=$ROOT/ecearth3/post/hiresclim2
fi

# required programs, including compression options
#cdo="$ROOT/$USER0/opt/bin/cdo -L"
cdo="/cineca/prod/opt/tools/cdo/1.8.2/intel--pe-xe-2017--binary/bin/cdo -L"
cdozip="$cdo -f nc4c -z zip"
rbld="$WORK/ecearth3/rebuild_nemo/rebuild_nemo"
cdftoolsbin="$WORK/cdftools/3.0/bin"
python="python"

# number of parallel procs for IFS (max 12) and NEMO rebuild
if [ -z $IFS_NPROCS ] ; then
IFS_NPROCS=12; NEMO_NPROCS=12
fi

# NEMO resolution
if [ -z $NEMOCONFIG ] ; then
export NEMOCONFIG="ORCA1L75"
fi

# where to find mesh and mask files 
export MESHDIR=$ROOT/ecearth3/nemo/$NEMOCONFIG

# where to find the results from the EC-EARTH experiment
# On our machine Nemo and IFS results are in separate directories
export BASERESULTS=/marconi_scratch/userexternal/$USERexp/ece3/$expname/output

# cdo table for conversion GRIB parameter --> variable name
export ecearth_table=$PROGDIR/script/ecearth.tab

# NEMO files
export NEMO_SAVED_FILES="grid_T grid_U grid_V icemod grid_W" ; # which files are saved / we care for?

# NEMO variables
export nm_wfo="wfo"        ; # water flux 
export nm_sst="tos"        ; # SST (2D)
export nm_sss="sos"        ; # SS salinity (2D)
export nm_ssh="zos"        ; # sea surface height (2D)
export nm_iceconc="siconc" ; # Ice concentration as in icemod file (2D)
export nm_icethic="sithick" ; # Ice thickness as in icemod file (2D)
export nm_tpot="thetao"    ; # pot. temperature (3D)
export nm_s="so"           ; # salinity (3D)
export nm_u="uo"           ; # X current (3D)
export nm_v="vo"           ; # Y current (3D)


# where to produce the results
export OUTDIR0=/marconi_scratch/userexternal/$USERme/ece3/$expname/post
mkdir -p $OUTDIR0

#where to archive the monthly results (daily are kept in scratch)
#STOREDIR=/home/hpc/pr45de/di56bov/work/ecearth3/post/hiresclim/${expname}
#mkdir -p $STOREDIR || exit -1

# create a temporary directory
export TMPDIR=/marconi_scratch/userexternal/$USERme/tmp/post_${expname}_$RANDOM
mkdir -p $TMPDIR || exit -1

echo Script is running in $PROGDIR
echo Temporary files are in $TMPDIR
echo Output are placed in $OUTDIR0
echo IFS procs are $IFS_NPROCS and NEMO procs are $NEMO_NPROCS
echo 
echo
