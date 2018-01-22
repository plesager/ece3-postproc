#!/bin/bash

#################################
# GENERAL SETTING FOR ALL TOOLS #
#################################

# first four are mandatory
export ECE3_POSTPROC_TOPDIR=/home/ms/nl/nm6/ECEARTH/postproc/ece3-postproc # where the sofware is installed
export ECE3_POSTPROC_RUNDIR=/scratch/ms/nl/nm6/ECEARTH-RUNS                # where your EC-Earth3 runs are (as set in config-run.xml) 
export ECE3_POSTPROC_DATADIR=/perm/ms/nl/nm6/ECE3-DATA                     # where the EC-Earth3 data are  (as set in config-run.xml) 
export ECE3_POSTPROC_MACHINE=cca                                           # HPC machine name

# HPC account if commented, your default one is used. At ECMWF, this is the
# 1st one in the list you get with "account -l $USER} on ecgate)
export ECE3_POSTPROC_ACCOUNT=nlchekli

# load/define the libraries (scheduler command, rebuild_nemo, cdo, ...)
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/config-${ECE3_POSTPROC_MACHINE}.sh
# if you want to use your own, overwrite it after this line


###############################
# MONTHLY MEANS (hiresclim2)  #
###############################

# -- Filter IFS output (to be applied through a grib_filter call)
# 
# Useful when there are output with different timestep.
# Comment if no filtering/change for different output

#FILTERGG2D="if ( (!(typeOfLevel is \"isobaricInhPa\") && !(typeOfLevel is \"isobaricInPa\") && !(typeOfLevel is \"potentialVorticity\" ))) { write; }"
#FILTERGG3D="if ( ((typeOfLevel is \"isobaricInhPa\") || (typeOfLevel is \"isobaricInPa\") )) { write; }"
#FILTERSH="if ( ((dataTime == 0000) || (dataTime == 0600) || (dataTime == 1200)  || (dataTime == 1800) )) { write; }"


# NOT IMPLEMENTED YET !!!!
# Base dir to archive (ie just make a copy of) the monthly results.
# Daily results, if any, are left in scratch. 
STOREDIR=/home/hpc/pr45de/di56bov/work/ecearth3/post/hiresclim/


#####################################
# GLOBAL FLUXES AND MORE (EC-mean)  #
#####################################

# - Where to save the table produced
export OUTDIR=${HOME}/EC-Earth3/diag/table-twan/${exp}
mkdir -p $OUTDIR

# - Where to save the climatology (769M AMIP, ??? NEMO).
# 
# By default, if this is commented or empty, it is in you rundir next to
# hiresclim2 monthly means output: 
# 
#     CLIMDIR=${ECE3_POSTPROC_RUNDIR}/${exp}/post/clim-${year1}-${year2}
#
# where exp, year1 and year2 are your scritp argument.
#     
# Note that it is needed for reproducibility tests for example.

#CLIMDIR=<my favorite path to store climatoloy data>


########
# AMWG #
########

# Where to find raw EC-Earth output (should contain "ifs" and "nemo" sub-directories...)
# => use "<RUN>" for run name:
#export ECEARTH_OUT_DIR="/nobackup/rossby17/rossby/joint_exp/swedens2/<RUN>"

# Root path to a temporary filesystem:
export TMPDIR_ROOT=$SCRATCH/tmp/timeseries

# *** EMOP_CLIM_DIR: where to store the AMWG-friendly climatology files:
export EMOP_CLIM_DIR=$SCRATCH/amwg

# Where to store time-series produced by script
export DIR_TIME_SERIES="${EMOP_CLIM_DIR}/timeseries"

# AMWG NCAR data? Use Jost's copy for now
export NCAR_DATA=/perm/ms/it/ccjh/ecearth3/amwg_data
export DATA_OBS="${NCAR_DATA}/obs_data_5.5"

export NEMOCONFIG="ORCA1L75"
export NEMO_MESH_DIR="/perm/ms/it/$USER0/ecearth3/nemo/$NEMOCONFIG"

# About web page, on remote server host:
#     =>  set RHOST="" to disable this function...
export RHOST=""
export RUSER=""
export WWW_DIR_ROOT=""

# -- List of stuffs needed for script NCARIZE_b4_AMWG.sh

# In case of coupled simulation, for ocean fields, should we extrapolate
# sea-values over continents for cleaner plots?
#    > will use DROWN routine of SOSIE interpolation package "mask_drown_field.x"
#i_drown_ocean_fields 1 ; # 1  > do it / 0  > don't

export i_drown_ocean_fields="1" ; # 1  > do it / 0  > don't
export MESH_MASK_ORCA="mask.nc"


# Ocean fields:
export LIST_V_2D_OCE="sosstsst iiceconc"


# 2D Atmosphere fields (ideally):
#export LIST_V_2D_ATM="ps \
               #msl \
               #uas \
               #vas \
               #tas \
               #e stl1 \
               #tcc totp cp lsp ewss nsss sshf slhf ssrd strd \
               #ssr str tsr ttr tsrc ttrc ssrc strc lcc mcc hcc \
               #tcwv tclw tciw fal"
#
# Those we have:
export LIST_V_2D_ATM="msl uas vas tas e sp \
                tcc totp cp lsp ewss nsss sshf slhf ssrd strd \
                ssr str tsr ttr tsrc ttrc ssrc strc lcc mcc hcc \
                tcwv tclw tciw fal"


# 3D Atmosphere fields (ideally):
export LIST_V_3D_ATM="q r t u v z"

# Those we have:
#export LIST_V_3D_ATM="q t u v z"



##############
# TIMESERIES #
##############
# Where to store produced time-series (<RUN>, if used, is replaced by the experiment 4-letter name)

export EMOP_CLIM_DIR=${HOME}/EC-Earth3/diag/
mkdir -p $EMOP_CLIM_DIR

export DIR_TIME_SERIES="${EMOP_CLIM_DIR}/timeseries/<RUN>"

