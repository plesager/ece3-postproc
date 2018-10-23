#!/bin/bash
set -e

 ############################################
 # To be called from ../master_hiresclim.sh #
 ############################################

expname=$1
year=$2
yref=$3

if [ $# -lt 3 ]
then
  echo "Usage:   ./ifs_monthly.sh EXP YEAR YREF"
  echo "Example: ./ifs_monthly.sh io01 1990 1990"
  exit 1
fi

# temp working dir, within $TMPDIR so it is automatically removed
mkdir -p $SCRATCH/tmp_ecearth3/tmp
WRKDIR=$(mktemp -d $SCRATCH/tmp_ecearth3/tmp/hireclim2_${expname}_XXXXXX) # use template if debugging
cd $WRKDIR

NPROCS=${IFS_NPROCS:-12}

# update IFSRESULTS and get OUTDIR0
eval_dirs 1

# where to save (archive) the results
OUTDIR=$OUTDIR0/mon/Post_$year
mkdir -p $OUTDIR || exit -1

echo "*II* --- Analyzing monthly output -----"
echo "*II* Temporary directory is $WRKDIR"
echo "*II* Data directory is $IFSRESULTS"
echo "*II* Postprocessing with $NPROCS cores"
echo "*II* Postprocessed data directory is $OUTDIR"

# output filename root
out=$OUTDIR/${expname}_${year}

#grib filename extension, define in conf_hiresclim_xxx.sh (default "")
[[ -z "${GRB_EXT:-}" ]] && grb_ext="" || grb_ext=".grb"

# ICMSH
if [ -n "${FILTERSH-}" ]
then
    echo "$FILTERSH" > filtsh.txt
    for m1 in $(seq 1 $NPROCS 12)
    do
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            eval_dirs $m  
            grib_filter -o icmsh_${ym} filtsh.txt $IFSRESULTS/ICMSH${expname}+$ym${grb_ext} &
        done
        wait
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            $cdo -b F64 -t $ecearth_table splitvar -sp2gpl \
                -setdate,$year-$m-01 -settime,00:00:00 -timmean \
                icmsh_${ym} icmsh_${ym}_ &
        done
        wait
        rm icmsh_??????
    done
    rm filtsh.txt
else
    for m1 in $(seq 1 $NPROCS 12)
    do
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            eval_dirs $m
            $cdo -b F64 -t $ecearth_table splitvar -sp2gpl \
                -setdate,$year-$m-01 -settime,00:00:00 -timmean \
                $IFSRESULTS/ICMSH${expname}+$ym${grb_ext} icmsh_${ym}_ &
        done
        wait
    done
fi

for v in t u v z lnsp
do
   rm -f ${out}_${v}.nc
   [ -f icmsh_${year}01_$v.grb ] && $cdozip -r -R -t $ecearth_table cat icmsh_??????_$v.grb ${out}_${v}.nc
done

#part on surface pressure
if [[ -f ${out}_lnsp.nc ]] ; then
    $cdo chcode,152,134 ${out}_lnsp.nc temp_lnsp.nc
    $cdo -t $ecearth_table exp temp_lnsp.nc ${out}_sp.nc
    rm temp_lnsp.nc
fi


# ICMGG
if [ -n "${FILTERGG2D-}" ]
then
    echo "$FILTERGG2D" > filtgg2d.txt
    for m1 in $(seq 1 $NPROCS 12)
    do
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            eval_dirs $m  
            grib_filter -o icmgg2df_${ym} filtgg2d.txt $IFSRESULTS/ICMGG${expname}+$ym${grb_ext} &
        done
        wait
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            $cdo -b F64 setdate,$year-$m-01 -settime,00:00:00 -timmean \
                icmgg2df_$ym icmgg2d_${ym}.grb &
        done
        wait
    done
    pptime=$($cdo showtime -seltimestep,1,2 icmgg2df_${year}01  | \
        tr -s ' ' ':' | awk -F: '{print ($5-$2)*3600+($6-$3)*60+($7-$4)}' )

    echo "$FILTERGG3D" > filtgg3d.txt
    for m1 in $(seq 1 $NPROCS 12)
    do
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            eval_dirs $m  
            grib_filter -o icmgg3df_${ym} filtgg3d.txt $IFSRESULTS/ICMGG${expname}+$ym${grb_ext} &
        done
        wait
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            $cdo -b F64 setdate,$year-$m-01 -settime,00:00:00 -timmean \
                icmgg3df_$ym icmgg3d_${ym}.grb &
        done
        wait
    done

    rm -f icmgg_${year}.grb icmgg3d_${year}.grb
    $cdo cat icmgg2d_${year}??.grb icmgg_${year}.grb
    $cdo cat icmgg3d_${year}??.grb icmgg3d_${year}.grb
    rm icmgg2d_${year}??.grb icmgg3d_${year}??.grb icmgg2df_${year}?? icmgg3df_${year}??

    $cdozip -r -R -t $ecearth_table splitvar \
        -selvar,uas,vas,tas,ci,sstk,sd,tds,tcc,lcc,mcc,hcc,tclw,tciw,tcwv,msl,fal \
        icmgg_${year}.grb ${out}_

    $cdozip -r -R -t $ecearth_table selvar,q  icmgg3d_${year}.grb ${out}_q.nc
    rm filtgg2d.txt filtgg3d.txt

else
    for m1 in $(seq 1 $NPROCS 12)
    do
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            eval_dirs $m  
            $cdo -b F64 setdate,$year-$m-01 -settime,00:00:00 -timmean \
                $IFSRESULTS/ICMGG${expname}+$ym${grb_ext} icmgg_${ym}.grb &
        done
        wait
    done
    rm -f icmgg_${year}.grb
    $cdo cat icmgg_${year}??.grb icmgg_${year}.grb
    rm -f icmgg_${year}??.grb

    $cdozip -r -R -t $ecearth_table splitvar \
        -selvar,uas,vas,tas,ci,sstk,sd,tds,tcc,lcc,mcc,hcc,tclw,tciw,tcwv,msl,q,fal \
        icmgg_${year}.grb ${out}_

    #  post-processing timestep in seconds from first month
    eval_dirs 1  
    pptime=$($cdo showtime -seltimestep,1,2 $IFSRESULTS/ICMGG${expname}+${year}01${grb_ext} | \
        tr -s ' ' ':' | awk -F: '{print ($5-$2)*3600+($6-$3)*60+($7-$4)}' )
fi

# check timestep
if [ $pptime -le 0 ]
then
    pptime=21600 # default 6-hr output timestep
fi
echo "*II* Timestep is $pptime"

# precip and evap and runoff in kg m-2 s-1
$cdozip -R -r -t $ecearth_table mulc,1000 -divc,$pptime -selvar,ro \
   icmgg_${year}.grb ${out}_ro.nc
$cdozip -R -r -t $ecearth_table mulc,1000 -divc,$pptime -selvar,sf \
   icmgg_${year}.grb ${out}_sf.nc

# Assume that 2 (or 3) out of 3 (tp,lsp,cp) precipitation variables are
# available, derive the missing one if needed. 

if ( ! $cdo -t $ecearth_table showname icmgg_$year.grb | grep -Fwq totp )
then
    $cdo -t $ecearth_table setparam,228.128 -expr,"totp=1000*(lsp+cp)/$pptime" \
        icmgg_${year}.grb tmp_totp.grb
    $cdozip -r -R -t $ecearth_table copy tmp_totp.grb ${out}_totp.nc

    $cdozip -r -R -t $ecearth_table splitvar -mulc,1000 -divc,$pptime \
        -selvar,e,lsp,cp icmgg_${year}.grb ${out}_

    $cdo -R -t $ecearth_table setparam,80.128 -fldmean \
        -expr,"pme=1000*(lsp+cp+e)/$pptime" icmgg_${year}.grb tmp_pme.grb
    $cdozip -r -t $ecearth_table copy tmp_pme.grb ${out}_pme.nc

elif ( ! $cdo -t $ecearth_table showname icmgg_$year.grb | grep -Fwq lsp )
then
    $cdo -t $ecearth_table setparam,142.128 -expr,"lsp=1000*(totp-cp)/$pptime" \
        icmgg_${year}.grb tmp_lsp.grb
    $cdozip -r -R -t $ecearth_table copy tmp_lsp.grb ${out}_lsp.nc

    $cdozip -r -R -t $ecearth_table splitvar -mulc,1000 -divc,$pptime \
        -selvar,e,totp,cp icmgg_${year}.grb ${out}_

    $cdo -R -t $ecearth_table setparam,80.128 -fldmean \
        -expr,"pme=1000*(totp+e)/$pptime" icmgg_${year}.grb tmp_pme.grb
    $cdozip -r -t $ecearth_table copy tmp_pme.grb ${out}_pme.nc

elif ( ! $cdo -t $ecearth_table showname icmgg_$year.grb | grep -Fwq cp )
then
    $cdo -t $ecearth_table setparam,143.128 -expr,"cp=1000*(totp-lsp)/$pptime" \
        icmgg_${year}.grb tmp_cp.grb
    $cdozip -r -R -t $ecearth_table copy tmp_cp.grb ${out}_cp.nc

    $cdozip -r -R -t $ecearth_table splitvar -mulc,1000 -divc,$pptime \
        -selvar,e,lsp,totp icmgg_${year}.grb ${out}_

    $cdo -R -t $ecearth_table setparam,80.128 -fldmean \
        -expr,"pme=1000*(totp+e)/$pptime" icmgg_${year}.grb tmp_pme.grb
    $cdozip -r -t $ecearth_table copy tmp_pme.grb ${out}_pme.nc

else
    $cdozip -r -R -t $ecearth_table splitvar -mulc,1000 -divc,$pptime \
        -selvar,e,cp,lsp,totp icmgg_${year}.grb ${out}_

    $cdo -R -t $ecearth_table setparam,80.128 -fldmean \
        -expr,"pme=1000*(totp+e)/$pptime" icmgg_${year}.grb tmp_pme.grb
    $cdozip -r -t $ecearth_table copy tmp_pme.grb ${out}_pme.nc
fi

# divide fluxes by PP timestep
$cdozip -r -R -t $ecearth_table splitvar -divc,$pptime \
   -selvar,ssr,str,sshf,ssrd,strd,slhf,tsr,ttr,ewss,nsss,ssrc,strc,tsrc,ttrc \
   icmgg_${year}.grb ${out}_

# net SFC and TOA fluxes
$cdo -R -t $ecearth_table setparam,149.128 -fldmean \
   -expr,"snr=(ssr+str+slhf+sshf)/$pptime" icmgg_${year}.grb tmp_snr.grb
$cdozip -r -t $ecearth_table copy tmp_snr.grb ${out}_snr.nc
$cdo -R -t $ecearth_table setparam,150.128 -fldmean \
   -expr,"tnr=(tsr+ttr)/$pptime" icmgg_${year}.grb tmp_tnr.grb
$cdozip -r -t $ecearth_table copy tmp_tnr.grb ${out}_tnr.nc

# change file suffices
( cd $OUTDIR ; for f in $(ls *.nc4); do mv $f ${f/.nc4/.nc}; done )

set -x
rm $WRKDIR/*.grb
cd -
rmdir $WRKDIR
set +x
