#!/bin/bash

set -e

#Performance Indices by Reichler and Kim (2008) 
#Paolo Davini (ISAC-CNR) - <p.davini@isac.cnr.it> 
#Based on netcdf climatologies and on CDO
#December 2014

#Netcdf climatologies are derived from previous Grads files
#For 2D fields: missing values when field/variance ratio is larger than 10e8 (but SSS and SICE)
#For Zonal fields: missing values for 90S and 90N
#Special values for SSS and SICE variance derived from previous Grads-based script: to be checked

#Further modification
#1)apply correct IFS and NEMO masks
#2)Evaluate zonal field only from 1000hPa to 100hPa (as stated by RK08)
#3)Remove windstress mask for values greater than +-0.1 N/m^2

if [ $# -ne 3 ]
then
    echo "Usage:   ./PI3.sh EXP YEARSTART YEAREND"
    echo "Example: ./PI3.sh io01 1990 2000"
    exit 1
fi

exp=$1
year1=$2
year2=$3


# CLIMDIR defined by calling script
OBSDIR=$ECE3_POSTPROC_TOPDIR/ECmean/Climate_netcdf
outfile=$OUTDIR/PI2_RK08_${exp}_${year1}_${year2}.txt

TMPDIR=$(mktemp -d $SCRATCH/tmp_ecearth3.XXXXXX)

pilong=(1 2 3 4 5 6 7 8 9 10 11 12 13); ii=0

#variable list to create PIs
var2d="t2m msl qnet tp ewss nsss SST SSS SICE"
var3d="T U V Q"

rm -f $outfile

echo -e "Performance Indices - Reichler and Kim 2008 - CDO version" > $outfile
echo -e "NEW VERSION: windstress, land-sea masks and 100hpa corrections" >> $outfile
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
        $cdo addc,1 -setctomiss,1 -setmisstoc,0 $ocemask $CLIMDIR/land_mask2x2.nc
        landmask=$CLIMDIR/land_mask2x2.nc

        #oceanic IFS fields: apply NEMO mask
        if  [ $vv == "ewss" ] || [ $vv == "nsss" ] || [ $vv == "qnet" ] ; then
                $cdo mul $ocemask -div -sqr -sub $field $clim $var $TMPDIR/temp_$vv.nc
        fi

        #oceanic NEMO field: do not apply the mask
        if [ "$vv" == "SST" ] && (( do_ocean )) ; then
                $cdo div -sqr -sub $field $clim $var $TMPDIR/temp_$vv.nc
        fi

        #special SSS case
        if [ "$vv" == "SSS" ] && (( do_ocean )) ; then
                $cdo divc,3.0116 -sqr -sub $field $clim  $TMPDIR/temp_$vv.nc
        fi
        
#FIXME       #special SICE case
#FIXME       if [ "$vv" == "SICE" ] && (( do_ocean )) ; then
#FIXME               $cdo divc,0.1309 -sqr -sub $field $clim  $TMPDIR/temp_$vv.nc
#FIXME       fi

        #land fields: apply IFS mask
        if [ $vv == "t2m"  ] ; then
                $cdo mul $landmask -div -sqr -sub $field $clim $var $TMPDIR/temp_$vv.nc
        fi

        #global
        if [ "$vv" == "msl" ] || [ "$vv" == "tp" ] ; then
                $cdo div -sqr -sub $field $clim $var $TMPDIR/temp_$vv.nc
        fi

        #PIs and PI ratio with respect to CMIP3
        if [ -f $TMPDIR/temp_$vv.nc ] ; then
            pivalue=$( $cdonc outputf,%8.4f,1 -fldmean $TMPDIR/temp_$vv.nc ) 
            piratio=$( echo "scale=2; $pivalue/${cmip3}" | bc | xargs printf "%4.2f\n" )
        else
            piratio=0
        fi
        pilong[$ii]=$piratio;  ii=$(( ii + 1 ))

    #print only if exists
    if [ -z "$pivalue"  ] ; then pivalue="     N/A" ; fi

    #printing to file
    echo -e "$vv \t$pivalue \t$domain \t$dataset\t$cmip3\t$piratio" >>  $outfile

done

#creating pressure weights
w=(30 45 75 100 100 100 150 175 112.5 75 37.5)
$cdo splitlevel $OBSDIR/climate_ERA40_T_zonal.nc $TMPDIR/level

#loop to create the pressure netcdf file
filelist=$( ls $TMPDIR/level*nc )
i=0
for file in $filelist ; do
    value=${w[$i]}
    i=$(( i + 1 ))
    $cdo divc,1000 -setmisstoc,$value -setrtomiss,-10000,10000 $file ${file}2
done
rm -f $TMPDIR/pressure.nc
$cdo merge $TMPDIR/*nc2 $TMPDIR/pressure.nc

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
    $cdo zaxisdes $clim > $TMPDIR/axis.txt
    $cdo setzaxis,$TMPDIR/axis.txt -invertlev -zonmean $field $TMPDIR/new_${vv}.nc

    #computing PIs
    $cdo div -sqr -sub $TMPDIR/new_${vv}.nc $clim $var $TMPDIR/temp_$vv.nc
    pivalue=$( $cdo outputf,%8.4f,1 -fldmean -vertsum -sellevel,100,200,300,400,500,700,850,925,1000 -mul $TMPDIR/pressure.nc $TMPDIR/temp_$vv.nc )
    piratio=$( echo "scale=2; $pivalue/${cmip3}" | bc | xargs printf "%4.2f\n" )
    pilong[$ii]=$piratio; ii=$(( ii + 1 )); 
    
    #writing outputs
    echo -e "$vv \t$pivalue \tzonal \tERA40\t$cmip3\t$piratio" >>  $outfile

done

#computing for partial and total PI
varshort="0 1 3 9 10 11 12"
varlong="0 1 2 3 4 5 6 7 8 9 10 11 12"
PIlong=0; PIshort=0
echo ${pilong[@]}

#Computing partial PI (only for atmospheric fields)
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

#cleaning
rm $TMPDIR/*.nc $TMPDIR/*.nc2 $TMPDIR/*.txt
rmdir $TMPDIR
