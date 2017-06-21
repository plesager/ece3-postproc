#!/bin/bash

#reading args
expname=$1
year=$2

#usage
if [ $# -lt 2 ]
then
  echo "Usage:   ./ifs_6hrs.sh EXP YEAR"
  echo "Example: ./ifs_6hrs.sh io01 1990"
  exit 1
fi


if [ $# -ne 3 ]; then 
# definition of variables is done in config.sh
. ../config.sh
else 
. $3
fi

#go to the tempdir
cd $TMPDIR

#where to get the files
IFSRESULTS=$BASERESULTS/Output_$year/IFS

# where to save (archive) the results
OUTDIR=$OUTDIR0/6hrs/Post_$year
mkdir -p $OUTDIR || exit -1

# output filename root
out=$OUTDIR/${expname}_${year}

#spectral variables
for m1 in $(seq 1 $NPROCS 12)
do
   for m in $(seq $m1 $((m1+NPROCS-1)) )
   do
      ym=$(printf %04d%02d $year $m)
                $cdo -t $ecearth_table splitvar -sp2gpl \
                   -settime,12:00:00 -sellevel,100000,85000,70000,50000,30000,10000,5000,1000 -selvar,t,u,v,z  \
                   $IFSRESULTS/ICMSH${expname}+$ym icmsh_${ym}_6hrs_ &
   done
   wait
done

#concatenate t u v z
for v in t u v z
do
   rm -f ${out}_${v}_6hrs.nc
   $cdozip -r -t $ecearth_table cat icmsh_??????_6hrs_$v.grb ${out}_${v}_6hrs.nc

done

#precipitation and surface temperature
for v in lsp cp tas ; do
  for m1 in $(seq 1 $NPROCS 12)
  do
     for m in $(seq $m1 $((m1+NPROCS-1)) )
     do
       ym=$(printf %04d%02d $year $m)

         $cdo -t $ecearth_table selvar,${v} $IFSRESULTS/ICMGG${expname}+$ym icmgg_${ym}_6hrs_${v}.grb &
   done
   wait
done
done

#concatenate and store
for v in tas ; do
     rm -f ${out}_${v}_6hrs.nc
     $cdozip -R -r -t $ecearth_table cat icmgg_${year}??_6hrs_${v}.grb ${out}_${v}_6hrs.nc
done

for v in lsp cp ; do
     rm -f ${v}_6hrs.grb
     $cdo -r -t $ecearth_table cat icmgg_${year}??_6hrs_${v}.grb ${v}_6hrs.grb
done

#  post-processing timestep in seconds
pptime=$($cdo showtime -seltimestep,1,2 $IFSRESULTS/ICMGG${expname}+${year}01 | \
   tr -s ' ' ':' | awk -F: '{print ($5-$2)*3600+($6-$3)*60+($7-$4)}' )

# precip and evap and runoff in kg m-2 s-1
   $cdo -b F32 -t $ecearth_table setparam,228.128 -mulc,1000 -divc,$pptime -add lsp_6hrs.grb cp_6hrs.grb tmp_totp_6hrs.grb
   $cdozip -r -R -t $ecearth_table copy tmp_totp_6hrs.grb ${out}_totp_6hrs.nc

rm $TMPDIR/*.grb
cd -
rmdir $TMPDIR
