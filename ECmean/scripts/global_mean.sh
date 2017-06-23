#!/bin/bash

set -ex

#Computes global averages of radiative fluxes (plus a few selected fields) 
#Starting from the HiresClim postprocessed output
#P. Davini (ISAC-CNR) - <p.davini@isac.cnr.it> 
#L. Filippi (ISAC-CNR) - <f.filippi@isac.cnr.it>
#December 2014

if [ $# -ne 3 ]
then
    echo "Usage:   ./global_mean.sh EXP YEARSTART YEAREND"
    echo "Example: ./global_mean.sh io01 1990 2000"
    exit 1
fi

# experiment name
exp=$1
# years to be processed
year1=$2
year2=$3

############################################
# No need to touch below this line/
############################################
WRKDIR=$(mktemp -d $SCRATCH/tmp_ecearth3_ecmean.XXXXXX)
nyears=$((year2-year1))

# -- ATMOSPHERE

# FIXME if (( do_ocean  ))              # 'heatc' only available from nemo
# FIXME then
# FIXME     varlist1="tsr ttr ssr ssrd str strd sshf slhf ssrc strc tas tcc lcc mcc hcc msl totp e tsrc ttrc ssrc strc ro sf tcwv tciw tclw heatc"
# FIXME else
    varlist1="tsr ttr ssr ssrd str strd sshf slhf ssrc strc tas tcc lcc mcc hcc msl totp e tsrc ttrc ssrc strc ro sf tcwv tciw tclw"
# FIXME fi

cdoformat="%9.4f,1"

for vv in ${varlist1}; do

    rm -f  $WRKDIR/${exp}_${vv}_singlefile.nc

    for (( year=$year1; year<=$year2; year++)); do
        indir=$DATADIR/Post_$year
        $cdonc cat $indir/${exp}_${year}_${vv}.nc $WRKDIR/full_field.nc
    done

    $cdo fldmean -timmean $WRKDIR/full_field.nc  $WRKDIR/mean_${vv}.nc

    if [ "${vv}" == e ] || [ "${vv}" == totp ] || [ "${vv}" == ro ] || [ "${vv}" == ssr ] || [ "${vv}" == str ] || [ "${vv}" == slhf ] || [ "${vv}" == sshf ] || [ "${vv}" == sf ] ; then 
        $cdo timmean $WRKDIR/full_field.nc $WRKDIR/mean_global_${vv}.nc 
    fi

    if [ "${vv}" == tas ] ; then
        $cdo trend -fldmean -yearmean $WRKDIR/full_field.nc $WRKDIR/a_${vv}.nc $WRKDIR/b_${vv}.nc
        tas_trend=$( $cdo output -mulc,100  $WRKDIR/b_${vv}.nc )
    fi

    if [ "${vv}"  == heatc ] ; then 
        $cdo yearmean $WRKDIR/full_field.nc  $WRKDIR/timeseries_${vv}.nc 
    fi

    rm $WRKDIR/full_field.nc 
done

# -- OCEAN 
if (( do_ocean  ))
then
    # ocean variables to be analzyed
    varlist2="sosstsst sossheig sosaline sowaflup"

    for vv in ${varlist2}; do

        rm -f  $WRKDIR/${exp}_${vv}_singlefile.nc

        for (( year=$year1; year<=$year2; year++)); do
            indir=$DATADIR/Post_$year
            $cdonc cat $indir/${exp}_${year}_${vv}_mean.nc $WRKDIR/full_field.nc
        done
        
        $cdo selvar,mean_${vv} $WRKDIR/full_field.nc $WRKDIR/varfile.nc
        $cdo timmean $WRKDIR/varfile.nc  $WRKDIR/mean_${vv}.nc

        rm $WRKDIR/full_field.nc $WRKDIR/varfile.nc
    done

    #delta ssh
    year=$year1
    indir=$DATADIR/Post_$year
    $cdo timmean $indir/${exp}_${year1}_sossheig_mean.nc $WRKDIR/first.nc
    
    year=$year2
    indir=$DATADIR/Post_$year
    $cdo timmean $indir/${exp}_${year2}_sossheig_mean.nc $WRKDIR/last.nc
fi

#creating a mask
$cdonc -R selcode,172 $maskfile $WRKDIR/temp_mask.nc
$cdo ltc,0.5 $WRKDIR/temp_mask.nc  $WRKDIR/ocean_mask.nc
$cdo ltc,0.5 $WRKDIR/ocean_mask.nc  $WRKDIR/land_mask.nc

#move to $WRKDIR 
cd $WRKDIR

#totp, e, pme and runoff for land and ocean
$cdo add mean_global_totp.nc mean_global_e.nc pme.nc
$cdo mulc,361 -mulc,1e6 -fldmean -ifthen ocean_mask.nc mean_global_totp.nc mean_totpocean.nc
$cdo mulc,148 -mulc,1e6 -fldmean -ifthen land_mask.nc mean_global_totp.nc mean_totpland.nc
$cdo mulc,361 -mulc,1e6 -fldmean -ifthen ocean_mask.nc pme.nc mean_peocean.nc
$cdo mulc,148 -mulc,1e6 -fldmean -ifthen land_mask.nc pme.nc mean_peland.nc
$cdo mulc,148 -mulc,1e6 -fldmean -ifthen land_mask.nc mean_global_ro.nc mean_ro.nc

#Snowmelt LH flux and surface heat fluxes for ocean
$cdo fldmean -ifthen ocean_mask.nc mean_global_ssr.nc mean_ssr_ocean.nc
$cdo fldmean -ifthen ocean_mask.nc mean_global_str.nc mean_str_ocean.nc
$cdo fldmean -ifthen ocean_mask.nc mean_global_sshf.nc mean_sshf_ocean.nc
$cdo fldmean -ifthen ocean_mask.nc mean_global_slhf.nc mean_slhf_ocean.nc
$cdo fldmean -mulc,334000 -ifthen ocean_mask.nc mean_global_sf.nc mean_sf_ocean.nc

#Snowmelt LH flux and surface heat fluxes for atmosphere
$cdo fldmean -ifthen land_mask.nc mean_global_ssr.nc mean_ssr_land.nc
$cdo fldmean -ifthen land_mask.nc mean_global_str.nc mean_str_land.nc
$cdo fldmean -ifthen land_mask.nc mean_global_sshf.nc mean_sshf_land.nc
$cdo fldmean -ifthen land_mask.nc mean_global_slhf.nc mean_slhf_land.nc
$cdo fldmean -mulc,334000 -ifthen land_mask.nc mean_global_sf.nc mean_sf_land.nc

#net surface fluxes for land and ocean
net_surface_ocean=$( $cdo outputf,$cdoformat -add mean_ssr_ocean.nc -add  mean_str_ocean.nc -add  mean_sshf_ocean.nc -sub  mean_slhf_ocean.nc mean_sf_ocean.nc )
net_surface_land=$( $cdo outputf,$cdoformat -add mean_ssr_land.nc -add  mean_str_land.nc -add  mean_sshf_land.nc -sub  mean_slhf_land.nc mean_sf_land.nc )

# FIXME #estimated flux to the ocean from heat content
# FIXME if (( do_ocean  ))
# FIXME then
# FIXME     if [ $year2 -ne $year1 ]
# FIXME     then
# FIXME         $cdo sub -selyear,$year2 $WRKDIR/timeseries_heatc.nc -selyear,$year1  $WRKDIR/timeseries_heatc.nc  $WRKDIR/delta_heatc.nc 
# FIXME         ocean_flux=$( $cdo outputf,$cdoformat -divc,86400 -divc,365.25 -divc,$nyears -divc,361 -divc,1e12 $WRKDIR/delta_heatc.nc )
# FIXME     else
        ocean_flux=0.
# FIXME     fi
# FIXME fi

#radiative variables
net_TOA=$( $cdo outputf,$cdoformat -add mean_tsr.nc mean_ttr.nc )
surface_SW_up=$( $cdo outputf,$cdoformat -sub mean_ssr.nc mean_ssrd.nc )
surface_LW_up=$( $cdo outputf,$cdoformat -sub mean_str.nc mean_strd.nc )
net_surface=$( $cdo outputf,$cdoformat -add mean_sshf.nc -add mean_slhf.nc -add mean_ssr.nc mean_str.nc )
net_TOA_clear=$( $cdo outputf,$cdoformat -add mean_tsrc.nc mean_ttrc.nc )
net_surface_clear=$( $cdo outputf,$cdoformat -add mean_sshf.nc -add mean_slhf.nc -add mean_ssrc.nc mean_strc.nc )
SW_cloud_forcing=$( $cdo outputf,$cdoformat -sub mean_tsr.nc mean_tsrc.nc )
LW_cloud_forcing=$( $cdo outputf,$cdoformat -sub mean_ttr.nc mean_ttrc.nc )
Snow_LH=$( $cdo outputf,$cdoformat -mulc,334000 mean_sf.nc )

#TOA-SFC
TOA_SFC=$( echo " " $( echo $net_TOA - $net_surface | bc | awk '{printf "%9.4f", $0}' ) )

#Corrected fluxes (including snowmelt)
corrected_net_surface=$( echo " " $( echo $net_surface - $Snow_LH | bc | awk '{printf "%9.4f", $0}' ) )
corrected_TOA_SFC=$( echo " " $( echo $net_TOA - $net_surface + $Snow_LH | bc | awk '{printf "%9.4f", $0}' ) )

#Writing variables to file: part on radiation
varlist="tsr ttr net_TOA ssr str sshf slhf SW_cloud_forcing LW_cloud_forcing net_surface corrected_net_surface TOA_SFC corrected_TOA_SFC Snow_LH Snow_LH_ocean Snow_LH_land net_surface_ocean net_surface_land  ocean_flux" 

echo -e "${exp} ${year1} ${year2}" > ${OUTDIR}/Global_Mean_Table_${exp}_${year1}_$year2.txt
echo -e "Radiation" >> ${OUTDIR}/Global_Mean_Table_${exp}_${year1}_$year2.txt
echo -e "Variable \t \t${exp}\t \tECE2 \tTRENBERTH09" >> ${OUTDIR}/Global_Mean_Table_${exp}_${year1}_$year2.txt

for vv in ${varlist}; do

    case ${vv} in

        "tsr")                  varname="TOA net SW" ;          ecval=242.6 ;   trenval=239.4 ;         expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "ttr")                  varname="TOA net LW" ;          ecval=-242.7 ;  trenval=-238.5 ;        expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "net_TOA")              varname="Net TOA   " ;          ecval=-0.1 ;    trenval=0.9 ;           expval=${net_TOA} ;;
        "ssr")                  varname="Sfc Net SW" ;          ecval=163.1 ;   trenval=161.2 ;         expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "ssrd")                 varname="Sfc SW Down" ;         ecval=186.4 ;   trenval=184 ;           expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "surface_SW_up")        varname="Sfc SW Up" ;           ecval=-23.3 ;   trenval=-23 ;           expval=${surface_SW_up} ;;
        "str")                  varname="Sfc Net LW" ;          ecval=-61.5 ;   trenval=-63 ;           expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "strd")                 varname="Sfc LW Down" ;         ecval=335.8 ;   trenval=333 ;           expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "surface_LW_up")        varname="Sfc LW Up" ;           ecval=-397.3 ;  trenval=-396 ;          expval=${surface_LW_up} ;;
        "sshf")                 varname="SH Flux   " ;          ecval=-18.3 ;   trenval=-17 ;           expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "slhf")                 varname="LH Flux   " ;          ecval=-82.7 ;   trenval=-80 ;           expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "net_surface")          varname="NetSfc(noSnow) " ;     ecval=0.6 ;     trenval=0.9 ;           expval=${net_surface} ;;
        "corrected_net_surface") varname="NetSfc      " ;       ecval=0.6 ;     trenval=0.9 ;           expval=${corrected_net_surface} ;;
        "net_surface_clear")    varname="Sfc Net Cl.sky" ;      ecval="N/A" ;   trenval="N/A" ;         expval=${net_surface_clear} ;;
        "net_TOA_clear")        varname="TOA Net Cl.sky" ;      ecval="N/A" ;   trenval="N/A" ;         expval=${net_TOA_clear} ;;
        "SW_cloud_forcing")     varname="SW Cl.Forcing" ;       ecval="N/A" ;   trenval="N/A" ;         expval=${SW_cloud_forcing} ;;
        "LW_cloud_forcing")     varname="LW Cl.Forcing" ;       ecval="N/A" ;   trenval="N/A" ;         expval=${LW_cloud_forcing} ;;
        "TOA_SFC")              varname="TOA-sfc(noSnow)" ;     ecval="-0.7" ;  trenval="0" ;           expval=${TOA_SFC} ;;        
        "Snow_LH")              varname="Snow LH     " ;        ecval="N/A" ;   trenval="N/A" ;         expval=${Snow_LH} ;;
        "Snow_LH_ocean")        varname="Snow LH Ocean" ;       ecval="N/A" ;   trenval="N/A" ;         expval=$( $cdo outputf,$cdoformat mean_sf_ocean.nc) ;;
        "Snow_LH_land")         varname="Snow LH Land" ;        ecval="N/A" ;   trenval="N/A" ;         expval=$( $cdo outputf,$cdoformat mean_sf_land.nc) ;;
        "corrected_TOA_SFC")    varname="TOA-sfc     " ;        ecval="N/A" ;   trenval="N/A" ;         expval=${corrected_TOA_SFC} ;;
        "ocean_flux")           varname="SfcOce(HC)" ;          ecval="N/A" ;   trenval="N/A" ;         expval=${ocean_flux} ;;
        "net_surface_ocean")    varname="SfcOce(Fluxes)" ;      ecval="N/A" ;   trenval="N/A" ;         expval=${net_surface_ocean} ;;
        "net_surface_land")     varname="SfcLand(Fluxes)" ;     ecval="N/A" ;   trenval="N/A" ;         expval=${net_surface_land} ;;
        "tcwv")                 varname="TotWatVap " ;          ecval="??" ;    trenval="??" ;          expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "tclw")                 varname="TotLiqWat " ;          ecval="??" ;    trenval="??" ;          expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;
        "tciw")                 varname="TotIceWat " ;          ecval="??" ;    trenval="??" ;          expval=$( $cdo outputf,$cdoformat mean_${vv}.nc ) ;;

    esac

    #print only if exists
    if [ -z "$expval"  ] ; then expval="     N/A" ; fi

    echo -e "${varname}\t\t${expval}\t${ecval}\t${trenval}" >> ${OUTDIR}/Global_Mean_Table_${exp}_${year1}_$year2.txt
done 

#Writing variables to file: part on global mean of variables
echo -e >> ${OUTDIR}/Global_Mean_Table_${exp}_${year1}_$year2.txt
echo -e >> ${OUTDIR}/Global_Mean_Table_${exp}_${year1}_$year2.txt
echo -e "Global Mean" >> ${OUTDIR}/Global_Mean_Table_${exp}_${year1}_$year2.txt
echo -e "Variable   \tunits                  \t${exp}         \tObservations" >> ${OUTDIR}/Global_Mean_Table_${exp}_${year1}_$year2.txt

varlist2="tas tas_trend tcc lcc mcc hcc totp totpocean totpland e pe ro peland peocean seatrend seatrend2 sowaflup sosstsst sossheig sosaline"

for vv in ${varlist2}; do

    eraval=""
    datas=""
    expval=''
    case ${vv} in

        "tas")          varname="Air T at 2m    ";      units="K         ";     expval=`$cdo output mean_${vv}.nc`; eraval=287.575 ; datas="ERAI(1990-2010)";;
        "tas_trend")    varname="Trend T at 2m  ";      units="K/100y    ";     expval=${tas_trend} ;;
        "tcc")          varname="Tot Cloud Cover";      units="0-1       ";     expval=`$cdo output mean_${vv}.nc`; eraval=0.60461 ; datas="ERAI(1990-2010)";;
        "lcc")          varname="Low CC         ";      units="0-1       ";     expval=`$cdo output mean_${vv}.nc`; eraval=0.36627 ; datas="ERAI(1979-2006)";;
        "mcc")          varname="Medium CC      ";      units="0-1       ";     expval=`$cdo output mean_${vv}.nc`; eraval=0.17451 ; datas="ERAI(1979-2006)";;
        "hcc")          varname="High CC        ";      units="0-1       ";     expval=`$cdo output mean_${vv}.nc`; eraval=0.28723 ; datas="ERAI(1979-2006)";;

        "msl")          varname="MSLP           ";      units="Pa        ";     expval=`$cdo output mean_${vv}.nc`; eraval=101135   ; datas="ERAI(1990-2010)";;
        "totp")         varname="Tot Precipit.  ";      units="mm/day    ";     expval=`$cdo output -mulc,86400 mean_${vv}.nc`; eraval=2.92339; datas="ERAI(1990-2010)";;
        "totpocean")    varname="Tot Pr. Ocean  ";      units="10^6 kg/s ";     expval=`$cdo output mean_${vv}.nc`;;
        "totpland")     varname="Tot Pr. Land   ";      units="10^6 kg/s ";     expval=`$cdo output mean_${vv}.nc`;;
        "e")            varname="Evaporation    ";      units="mm/day    ";     expval=`$cdo output -mulc,86400 mean_${vv}.nc`;;
        "pe")           varname="P-E            ";      units="mm/day    ";     expval=`$cdo output -mulc,86400 -add mean_totp.nc mean_e.nc`;;
        "ro")           varname="Runoff         ";      units="10^6 kg/s ";     expval=`$cdo output mean_${vv}.nc`;;
        "peland")       varname="P-E (land)     ";      units="10^6 kg/s ";     expval=`$cdo output mean_peland.nc`;;
        "peocean")      varname="P-E (ocean)    ";      units="10^6 kg/s ";     expval=`$cdo output mean_peocean.nc`;;
        "seatrend")     varname="Sea Exp. Trend ";      units="m/100y    ";    (( do_ocean )) && expval=`$cdo output -mulc,0.0087 -add mean_peocean.nc mean_ro.nc`;;
        "seatrend2")    varname="Sea Real Trend ";      units="m/100y    ";    (( do_ocean )) && expval=`$cdo output -selvar,mean_sossheig -divc,$nyears -mulc,100 -sub last.nc first.nc `;;
        "sosstsst")     varname="SST            ";      units="°C        ";    (( do_ocean )) && expval=`$cdo output mean_${vv}.nc`;
                                                                               (( do_ocean )) && eraval=18.4147 ; datas="HadISST(1990-2010)";;
        "sosaline")     varname="SSS            ";      units="psu       ";    (( do_ocean )) && expval=`$cdo output mean_${vv}.nc`;;
        "sossheig")     varname="SSH            ";      units="m         ";    (( do_ocean )) && expval=`$cdo output mean_${vv}.nc`;;
        "sowaflup")     varname="Nemo Water Flux";      units="m/100y    ";    (( do_ocean )) && expval=`$cdo output -mulc,-0.0087 -mulc,361 -mulc,1e6 mean_${vv}.nc`;;

    esac

    # meaningful print
    if [ -z "$expval"  ] ; then expval="     N/A" ; fi

    echo -e "${varname}\t${units}\t${expval}\t\t${eraval}\t$datas" >> ${OUTDIR}/Global_Mean_Table_${exp}_${year1}_$year2.txt
done

#cleaning and exiting
rm $WRKDIR/*.nc
cd -
rmdir $WRKDIR


