#!/bin/bash

set -ex

#Performance Indices by Reichler and Kim (2008) 
#Paolo Davini (ISAC-CNR) - <p.davini@isac.cnr.it> 
#Based on netcdf climatologies and on CDO
#December 2014

#Netcdf climatologies are derived from previous Grads files
#For 2D fields: missing values when field/variance ratio is larger than 10e8 (but SSS and SICE)
#For Zonal fields: missing values for 90S and 90N
#Special values for SSS and SICE variance derived from previous Grads-based script: to be checked

if [ $# -lt 3 ]
then
    echo "Usage:   ${0##*/} EXP YEARSTART YEAREND LPRIMAVERA"
    echo "Example: ${0##*/} io01 1990 2000"
    exit 1
fi

exp=$1
year1=$2
year2=$3
primavera=$4

# CLIMDIR defined by calling script
OBSDIR=$ECE3_POSTPROC_TOPDIR/ECmean/Climate_netcdf
outfile=${OUTDIR}/${exp}/PIold_RK08_${exp}_${year1}_${year2}.txt

mkdir -p $SCRATCH/tmp_ecearth3/tmp
TMPDIR=$(mktemp -d $SCRATCH/tmp_ecearth3/tmp/ecmean_${exp}_XXXXXX)

#initializing array for PIs
pilong=(1 2 3 4 5 6 7 8 9 10 11 12 13); ii=0

#variable list to create PIs
var2d="t2m msl qnet tp ewss nsss SST SSS SICE"
var3d="T U V Q"

rm -f $outfile

echo -e "Performance Indices - Reichler and Kim 2008 - CDO version" > $outfile
echo -e "OLD VERSION: minor errors in the code" >> $outfile
echo -e "$exp $year1 $year2" >> $outfile
echo -e "" >> $outfile
echo -e "Field \t\tPI \tDomain\tDataset\tCMIP3\tRatioCMIP3" >> $outfile

for vv in $var2d ; do

    case $vv in
        "tp")           dataset="CMAP"          ;       domain="global" ; cmip3=38.87   ;;
        "t2m")          dataset="CRU"           ;       domain="land"   ; cmip3=25.13   ;;
        "msl")          dataset="COADS"         ;       domain="global" ; cmip3=11.69   ;;
        "qnet")         dataset="OAFLUX"        ;       domain="ocean"  ; cmip3=14.24   ;;
        "ewss")         dataset="DASILVA"       ;       domain="ocean"  ; cmip3=4.03    ;;
        "nsss")         dataset="DASILVA"       ;       domain="ocean"  ; cmip3=3.10    ;;
        "SST")          dataset="GISS"          ;       domain="ocean"  ; cmip3=17.21   ;;
        "SICE")         dataset="GISS"          ;       domain="ocean"  ; cmip3=0.34    ;;
        "SSS")          dataset="levitus"       ;       domain="ocean"  ; cmip3=0.22    ;;
    esac

    clim=$OBSDIR/climate_${dataset}_$vv.nc
    var=$OBSDIR/variance_${dataset}_$vv.nc
    field=$CLIMDIR/${vv}_mean_2x2.nc
    ocemask=$CLIMDIR/ocean_mask2x2.nc

    #special weird treatment of the wind stress (old method)
    if  [ $vv == "ewss" ] || [ $vv == "nsss" ] ; then
        $cdonc div -sqr -setrtomiss,0.1,10 -setrtomiss,-10,-0.1 -sub $field $clim $var $TMPDIR/temp_$vv.nc
    fi

    if  [ $vv == "qnet" ] ; then
        $cdonc div -sqr -sub $field $clim $var $TMPDIR/temp_$vv.nc
    fi      

    #ocean with mask
    if [ "$vv" == "SST" ] && (( do_ocean )) ; then
        $cdonc div -sqr -sub $field $clim $var $TMPDIR/temp_$vv.nc
    fi

    #special SSS case
    if [ "$vv" == "SSS" ] && (( do_ocean )) ; then
        $cdonc divc,3.0116 -sqr -sub $field $clim  $TMPDIR/temp_$vv.nc
    fi
    
    #special SICE case
    if [ "$vv" == "SICE" ] && (( do_ocean )) ; then
        $cdonc divc,0.1309 -sqr -sub $field $clim  $TMPDIR/temp_$vv.nc
    fi

    #land
    if [ $vv == "t2m"  ] ; then
        $cdonc div -sqr -sub $field $clim $var $TMPDIR/temp_$vv.nc
    fi

    #global
    if [ "$vv" == "msl" ] || [ "$vv" == "tp" ] ; then
        $cdonc div -sqr -sub $field $clim $var $TMPDIR/temp_$vv.nc
    fi

    #PIs and PI ratio with respect to CMIP3
    if [ -f $TMPDIR/temp_$vv.nc ] ; then
        pivalue=$( $cdonc outputf,%8.4f,1 -fldmean $TMPDIR/temp_$vv.nc ) 
        piratio=$( echo "scale=2; $pivalue/${cmip3}" | bc | xargs printf "%4.2f\n" )
    else
        piratio=0
    fi
    pilong[$ii]=$piratio ii=$(( ii + 1 ));

    #print only if exists
    if [ -z "$pivalue"  ] ; then pivalue="     N/A" ; fi

    echo -e "$vv \t$pivalue \t$domain \t$dataset\t$cmip3\t$piratio" >>  $outfile

done

#creating pressure weights
w=(30 45 75 100 100 100 150 175 112.5 75 37.5)
$cdonc splitlevel $OBSDIR/climate_ERA40_T_zonal.nc $TMPDIR/level

filelist=$( ls $TMPDIR/level*nc )
i=0
for file in $filelist ; do
    value=${w[$i]}
    i=$(( i + 1 ))
    $cdonc divc,1000 -setmisstoc,$value -setrtomiss,-10000,10000 $file ${file}2
done
rm -f $TMPDIR/pressure.nc
$cdonc merge $TMPDIR/*nc2 $TMPDIR/pressure.nc

#loop on var3d
for vv in $var3d ; do

    case $vv in
        "T")     cmip3=38.89   ;;
        "U")     cmip3=12.07    ;;
        "V")     cmip3=8.25     ;;
        "Q")     cmip3=29.41    ;;
    esac

    dataset="ERA40"
    clim=$OBSDIR/climate_${dataset}_${vv}_zonal.nc
    var=$OBSDIR/variance_${dataset}_${vv}_zonal.nc
    field=$CLIMDIR/${vv}_mean_2x2.nc

    #axis correction, Pa to hPa
    $cdonc zaxisdes $clim > $TMPDIR/axis.txt
    $cdonc setzaxis,$TMPDIR/axis.txt -invertlev -zonmean $field $TMPDIR/new_${vv}.nc

    if [[ ${primavera} == 1 ]]; then
        #Dei 44 lev, seleziono solo gli 11 da confrontare con OBS-dataset_ERA40 
        $cdonc div -sqr -sub -sellevel,1000,5000,10000,20000,30000,40000,50000,70000,85000,92500,100000 $TMPDIR/new_${vv}.nc $clim $var $TMPDIR/temp_$vv.nc
        
        #Converto da Pa (file tempp_$vv.nc) a mbar/hPa (file temp_$vv.nc) in accordo con file pressure.nc
        $cdonc setzaxis,$TMPDIR/axis.txt $TMPDIR/tempp_$vv.nc $TMPDIR/temp_$vv.nc
    else
        $cdonc div -sqr -sub $TMPDIR/new_${vv}.nc $clim $var $TMPDIR/temp_$vv.nc
    fi

    pivalue=$( $cdonc outputf,%8.4f,1 -fldmean -vertsum -mul $TMPDIR/pressure.nc $TMPDIR/temp_$vv.nc )
    piratio=$( echo "scale=2; $pivalue/${cmip3}" | bc | xargs printf "%4.2f\n" )
    pilong[$ii]=$piratio; ii=$(( ii + 1 )); 
    
    echo -e "$vv \t$pivalue \tzonal \tERA40\t$cmip3\t$piratio" >>  $outfile

done

#computing for partial and total PI
varshort="0 1 3 9 10 11 12"
varlong="0 1 2 3 4 5 6 7 8 9 10 11 12"
PIlong=0; PIshort=0
echo ${pilong[@]}

#Computint partial PI (only for atmospheric fields)
for vv in $varshort ; do
    PIshort=$( echo "scale=4; $PIshort+${pilong[$vv]}" | bc -l ) ;
done
PIshort=$( echo "scale=4; $PIshort/7" | bc | xargs printf "%6.4f\n" )

#Computing full PI (for full fields)
for vv in $varlong ; do
    PIlong=$( echo "scale=4; $PIlong+${pilong[$vv]}" | bc ) ; 
done
PIlong=$( echo "scale=4; $PIlong/13" | bc | xargs printf "%6.4f\n" )

#print only if exists
if [ "${pilong[8]}" == "0.00" ] ;  then PIlong="N/A" ; fi


#printing outputs
echo -e "" >>  $outfile
echo -e "Total Performance Index is : $PIlong"  >>  $outfile
echo -e "Partial PI (atm only) is   : $PIshort"  >>  $outfile
echo -e "" >> $outfile

#cleaning
rm $TMPDIR/*.nc $TMPDIR/*.nc2 $TMPDIR/*.txt
rmdir $TMPDIR
