#! /usr/bin/env bash

# wrapper script that call scripts for PI and RK analysis
# firstly interpolate on common 2x2 grid hiresclim outputs
# hence computes RK08 diagnostics and finally produces
# global mean values for radiation and some selected fields

# Paolo Davini (ISAC-CNR) - <p.davini@isac.cnr.it> - December 2014
#   22 May 2017 - Ph. Le Sager

set -e

if [ $# -lt 3 ]
then
  echo "Usage:   ./EC-mean.sh exp YEARSTART YEAREND [ALT_RUNDIR]"
  echo "Example: ./EC-mean.sh io01 1990 2000"
  exit 1
fi

# experiment name
exp=$1
# years to be processed
year1=$2
year2=$3

# load cdo, netcdf and dir for results
. $ECE3_POSTPROC_TOPDIR/conf/conf_ecmean_${ECE3_POSTPROC_MACHINE}.sh

if [ $# -eq 4 ]; then           # optional alternative top rundir 
   ALT_RUNDIR=$4
fi

############################################################
# HARDCODED OPTIONS
############################################################
# None

############################################################
# TEMP dirs
############################################################

# Where to store the 2x2 climatologies
export CLIMDIR=$(mktemp -d) # $SCRATCH/tmp_ecearth3/post_${exp}_model2x2_XXXXXX)
mkdir -p $CLIMDIR || true

TMPDIR=$(mktemp -d) # $SCRATCH/tmp_ecearth3.XXXXXX)

############################################################
# Checking settings dependent only on the ECE3_POSTPROC_* variables, i.e. env
############################################################
# Where the program is placed
PIDIR=$ECE3_POSTPROC_TOPDIR/ECmean

# Base directory of HiresClim2 postprocessing outputs
if [[ -n $ALT_RUNDIR ]]
then
    export DATADIR=$ALT_RUNDIR/${exp}/post/mon/
else
    export DATADIR="${ECE3_POSTPROC_RUNDIR}/${exp}/post/mon/"
fi
[[ ! -d $DATADIR ]] && echo "*EE* Experiment HiresClim2 output dir $DATADIR does not exist!" && exit 1

# -- nemo
do_ocean=0
[[ -r $DATADIR/Post_${year1}/${exp}_${year1}_sosstsst.nc ]] && do_ocean=1 && \
    echo "*II* ecmean accounts for nemo output"
export do_ocean

# -- mask files

# first, find IFS horizontal resolution from one of the processed output
fname=$(ls -1 $DATADIR/Post_$year1/*t.nc | tail -1)
res=$(cdo griddes $fname | sed -rn "s/ysize.*= ([0-9]+)/\1/p")
(( res-=1 ))

# 2x2 grids for interpolation are included in the Climate_netcdf folder
# (derived from IFS land sea mask). Masks are used by ./global_mean.sh and by
# ./post2x2.sh scripts. They are computed from the original initial conditions
# of IFS (using var 172):
export maskfile=$ECE3_POSTPROC_DATADIR/ifs/T${res}L91/19900101/ICMGGECE3INIT

[[ ! -r $maskfile ]] && echo "*EE* cannot read IFS initial condition: $maskfile" && exit 1

############################################################
# Call postprocessings
############################################################
cd $PIDIR/scripts/ 

printf " ----------------------------------- Post 2x2\n"
./post2x2.sh $exp $year1 $year2

printf "\n\n ----------------------------------- old PI2\n"
./oldPI2.sh $exp $year1 $year2

printf "\n\n----------------------------------- PI3\n"
./PI3.sh $exp $year1 $year2

printf "\n\n----------------------------------- Global Mean\n"
./global_mean.sh $exp $year1 $year2

# Rearranging in a single table the PI from the old and the new versions
cat $OUTDIR/PIold_RK08_${exp}_${year1}_${year2}.txt $OUTDIR/PI2_RK08_${exp}_${year1}_${year2}.txt > $TMPDIR/out.txt
rm $OUTDIR/PI2_RK08_${exp}_${year1}_${year2}.txt $OUTDIR/PIold_RK08_${exp}_${year1}_${year2}.txt
mv $TMPDIR/out.txt $OUTDIR/PI2_RK08_${exp}_${year1}_${year2}.txt 
#not needed rm -rf $TMPDIR
#not needed  
#not needed # Deleting the 2x2 climatology to save space
#not needed rm $CLIMDIR/*.nc
#not needed rmdir $CLIMDIR

cd $OUTDIR/..
touch globtable.txt globtable_cs.txt
$PIDIR/tab2lin_cs.sh $exp $year1 $year2 >> ./globtable_cs.txt
$PIDIR/tab2lin.sh $exp $year1 $year2 >> ./globtable.txt

[[ ! -e gregory.txt ]] && \
    cat "                  net TOA, net Sfc, t2m[tas], SST" >> gregory.txt
$PIDIR/gregory.sh $exp $year1 $year2 >> ./gregory.txt


#finalizing
cd -
echo "table produced"

cd $OUTDIR/..
\rm -f ecmean_$exp.tar 
\rm -f ecmean_$exp.tar.gz
tar cvf ecmean_$exp.tar $exp
gzip ecmean_$exp.tar

#TODO ectrans -remote sansone -source ecmean_$exp.tar.gz  -verbose -overwrite
#TODO ectrans -remote sansone -source ~/EXPERIMENTS.${ECE3_POSTPROC_MACHINE}.$USERme.dat -verbose -overwrite
