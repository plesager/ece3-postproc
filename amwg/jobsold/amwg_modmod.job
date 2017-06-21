#!/bin/ksh
#PBS -N amwg_taj4
#PBS -q ns
#PBS -l EC_billing_account=spnltune
#PBS -l EC_total_tasks=1
#PBS -l EC_threads_per_task=1
#PBS -l EC_memory_per_task=12GB
#PBS -l EC_hyperthreads=1
#PBS -l walltime=03:00:00
#PBS -j oe
#PBS -e /scratch/ms/it/ccjh/log/amwg_taj4.err
#PBS -o /scratch/ms/it/ccjh/log/amwg_taj4.out
#PBS -S /bin/bash

set -uex
cd $PBS_O_WORKDIR
module load netcdf nco cdo python ncl

##########################
## Configuration file
##########################

. $HOME/ecearth3/post/conf/conf_users.sh
. $CONFDIR/conf_amwg_$MACHINE.sh

expname1=taj1
expname2=taj2
year1=1991
year2=1999
resolution=N128 #aka T255

#Configuration file
conf=$MACHINE

PROGDIR=$EMOP_DIR
cd $PROGDIR/ncarize
bash $PROGDIR/ncarize/ncarize_pd.sh -C $conf -R $expname2 -g $resolution -i ${year1} -e ${year2}
cd $PROGDIR/amwg_diag
bash $PROGDIR/amwg_diag/diag_mod_vs_mod.sh -C $conf -R $expname1,$expname2 -P ${year1}-${year2},${year1}-${year2}

DIAGS=$EMOP_CLIM_DIR/diag_${expname}_${year1}-${year2}
cd $DIAGS
tar cvfz diag_${expname}.tar ${expname}-obs_${year1}-${year2}
ectrans -remote sansone -source diag_${expname}.tar -verbose -overwrite
