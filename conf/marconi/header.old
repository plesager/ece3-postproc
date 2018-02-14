#!/bin/bash
#PBS -N <JOBID>_<EXPID>
#PBS -l walltime=<TOTTIME>
#PBS -A <ACCOUNT>
#PBS -l select=1:ncpus=<THREADS>:mem=<MEM>
#PBS -m a
#PBS -j oe
#PBS -o /marconi_scratch/userexternal/<USERme>/log/<JOBID>_<EXPID>.out
#PBS -S /bin/bash

set -ex
cd $PBS_O_WORKDIR
###PBS -l select=1:ncpus=12:mpiprocs=1:mem=24GB

# Where to find the user configuration file
. $HOME/ecearth3/post/conf/conf_users.sh

# Specific modules needed
module unload cdo hdf5 netcdf python numpy
module load  hdf5/1.8.17--intel--pe-xe-2017--binary netcdf/4.4.1--intel--pe-xe-2017--binary cdo  python/2.7.12 numpy/1.11.2--python--2.7.12 nco/4.6.7 

# For hiresclim
NEMO_NPROCS=<NEMO_PROCS>
IFS_NPROCS=<IFS_PROCS>

cd $SCRIPTDIR
