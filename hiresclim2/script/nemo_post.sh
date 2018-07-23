#!/bin/bash
set -e

 ############################################
 # To be called from ../master_hiresclim.sh #
 ############################################

# This is the number of months in a leg. Only 1 and 12 tested yet.
mlegs=${months_per_leg}
if [[ $mlegs != 12 && $mlegs != 1 ]]
then
    echo "*EE* only yearly or monthly leg has been tested in NEMO postprocessing. Please review."
    exit 1
fi

# reading args
expname=$1
year=$2
yref=$3
nemo_extra=$4

# usage
if [ $# -lt 4 ]
then
  echo "Usage:   ./nemo_post.sh EXP YEAR YEAR_REF NEMO_EXTRA"
  echo "Example: ./nemo_post.sh io01 1990 1950 0"
  exit 1
fi

# temp working dir, within $TMPDIR so it is automatically removed or use XXXX template if debugging
mkdir -p $SCRATCH/tmp_ecearth3/tmp
WRKDIR=$(mktemp -d $SCRATCH/tmp_ecearth3/tmp/hireclim2_${expname}_XXXXXX) # use template if debugging
cd $WRKDIR

NOMP=${NEMO_NPROCS}

# Check on use of SBC file - can be set in your ../../../conf/conf_hiresclim_<MACHINE-NAME>.sh
echo "SBC file used: ${use_SBC:=1}"
(( $use_SBC )) && SBC='SBC' || SBC='grid_T'

# Check which version of CDFtools is used - can be set in your
# ../../../conf/conf_hiresclim_<MACHINE-NAME>.sh, but old syntax is
# assumed if not set.
echo "Use CDFTOOLS 4.x syntax: ${cdftools4:=0}"
if (( $cdftools4 )); then cdftools301=1; fi
echo "Use CDFTOOLS 3.0.1 syntax: ${cdftools301:=0}"

# update NEMORESULTS and get OUTDIR0
eval_dirs 1

# where to save (archive) the results
OUTDIR=$OUTDIR0/mon/Post_$year
mkdir -p $OUTDIR || exit -1

# output filename root
out=$OUTDIR/${expname}_${year}

skip_nino=0
case $NEMOCONFIG in
    ( ORCA1L46 )
    # depth layers for heat content (0-300m, 300-800m, 800m-bottom)
    depth_0_300='1 16'
    depth_300_800='17 22'
    depth_800_bottom='23 46'
    # Nino3.4 region (in ij coordinates)
    nino34_region='119 168 133 161'
    ;;
    ( ORCA1L75 )
    # depth layers for heat content (0-300m, 300-800m, 800m-bottom)
    depth_0_300='1 34'
    depth_300_800='35 44'
    depth_800_bottom='45 75'
    # Nino3.4 region (in ij coordinates)
    nino34_region='119 168 133 161' 
    skip_nino=0
    ;;
    ( ORCA025L75 )
    # depth layers for heat content (0-300m, 300-800m, 800m-bottom)
    depth_0_300='1 34'
    depth_300_800='35 44'
    depth_800_bottom='45 75'
    # Nino3.4 region (in ij coordinates for the 1442x1050 grid)
    nino34_region='469 669 507 547'
    skip_nino=0
    ;;
    ( * ) echo Stop: NEMOCONFIG=$NEMOCONFIG not defined ; exit -1 ;;
esac

# mask and mesh files
ln -s $MESHDIR/mask.nc
ln -s $MESHDIR/mesh_hgr.nc
ln -s $MESHDIR/mesh_zgr.nc
ln -s $MESHDIR/new_maskglo.nc

# Nemo output filenames start with...
froot=${expname}_1m_${year}0101_${year}1231

# rebuild or create yearly file from monthly legs if necessary
for t in grid_T grid_U grid_V icemod SBC
do
   if [ -f $NEMORESULTS/${froot}_${t}.nc ]
   then
      cp $NEMORESULTS/${froot}_${t}.nc .
   else
       if [[ $mlegs == 1 ]]
       then
           mfiles=""
           # build list of monthly files, could be less selective in the file list syntax
           for m in $(seq 1 12)
           do
               m0=`printf "%02d" $m`
               #additional evaluation for monthly files
               eval_dirs $m
               mfiles=$mfiles" "$NEMORESULTS/${expname}_1m_${year}${m0}01_${year}${m0}??_${t}.nc
           done
           eval_dirs 1
           ncrcat -3 $mfiles ${froot}_${t}.nc
       elif (( $(ls $NEMORESULTS/${froot}_${t}* | wc -w) ))
       then
           ln -s $NEMORESULTS/${froot}_${t}* .
           $rbld -t $NOMP ${froot}_$t  $(ls ${froot}_${t}_????.nc | wc -w)
           cp ${froot}_${t}.nc $NEMORESULTS
           rm -f ${froot}_${t}_????.nc
       else
           echo "WARNING: $t files are missing"
       fi
   fi
done

# ** AVAILABILITY
# 
# NEMO_SAVED_FILES and variable names are defined in your "./conf/<your-machine>/conf_hiresclim_<your-machine>.sh"

[[ $NEMO_SAVED_FILES =~ grid_T ]] && itf=1 || itf=0   # 1: means grid_T is available 
[[ $NEMO_SAVED_FILES =~ grid_U ]] && iuf=1 || iuf=0   # 1: means grid_U is available 
[[ $NEMO_SAVED_FILES =~ grid_V ]] && ivf=1 || ivf=0   # 1: means grid_V is available 
[[ $NEMO_SAVED_FILES =~ icemod ]] && iif=1 || iif=0   # 1: means icemod is available 

if [ ${itf} -eq 0 -o ${iif} -eq 0 ]; then
    echo "*EE*  grid_T and icemod files required for nemo_post.sh"
    exit 1
fi

# do all ncrename operations for grid_T in one step
rename_str=""
if [ "${nm_sst}"  != "sosstsst" ];  then rename_str=$rename_str" -v ${nm_sst},sosstsst" ; fi
if [ "${nm_sss}"  != "sosaline" ];  then rename_str=$rename_str" -v ${nm_sss},sosaline" ; fi
if [ "${nm_ssh}"  != "sossheig" ];  then rename_str=$rename_str" -v ${nm_ssh},sossheig" ; fi
if [ "${nm_tpot}" != "votemper" ];  then rename_str=$rename_str" -v ${nm_tpot},votemper"; fi
if [ "${nm_s}"    != "vosaline" ];  then rename_str=$rename_str" -v ${nm_s},vosaline"   ; fi

if [ "${rename_str}" != "" ];  then ncrename $rename_str ${froot}_grid_T.nc ; fi

if [ "${nm_wfo}"  != "sowaflup" ];  then ncrename -v ${nm_wfo},sowaflup  ${froot}_${SBC}.nc ; fi
if [ ${iuf} -eq 1 ]; then
    if [ "${nm_u}"   != "vozocrtx" ];  then ncrename -v ${nm_u},vozocrtx    ${froot}_grid_U.nc ; fi
fi
if [ ${ivf} -eq 1 ]; then
    if [ "${nm_v}"   != "vomecrty" ];  then ncrename -v ${nm_v},vomecrty    ${froot}_grid_V.nc ; fi
fi

# ICE
if (( $cdftools4 ))         # auxilliary file for newer CDFtools (4.0 master retrieved on 06-09-2017)
then
    if [ "${nm_iceconc}" != "siconc" ]; then
        ncrename -v ${nm_iceconc},siconc  ${froot}_icemod.nc  ${froot}_icemod_cdfnew.nc
    else
        cp ${froot}_icemod.nc  ${froot}_icemod_cdfnew.nc
    fi
    if [ "${nm_icethic}" != "sithic" ]; then
        ncrename -v ${nm_icethic},sithic  ${froot}_icemod_cdfnew.nc
    fi
fi
if [ "${nm_iceconc}" != "iiceconc" ]; then ncrename -v ${nm_iceconc},iiceconc  ${froot}_icemod.nc ; fi
if [ "${nm_icethic}" != "iicethic" ]; then ncrename -v ${nm_icethic},iicethic  ${froot}_icemod.nc ; fi

# SHACONEMO update (april 2018) changes dimension names in the icemod files
which ncdump
if ! ncdump -h ${froot}_icemod.nc | grep -q "^[[:blank:]]*x *="
then
    echo "*II* rename X,Y dimensions of icemod file(s)"
    if (( $cdftools4 ))
    then
        ncks -3 ${froot}_icemod_cdfnew.nc ${froot}_icemod_tmp.nc
        ncrename -O -d .x_grid_T,x -d .y_grid_T,y ${froot}_icemod_tmp.nc ${froot}_icemod_cdfnew.nc
        rm -f ${froot}_icemod_tmp.nc
    fi
    ncks -3 ${froot}_icemod.nc ${froot}_icemod_tmp.nc
    ncrename -7 -O -d .x_grid_T,x -d .y_grid_T,y ${froot}_icemod_tmp.nc ${froot}_icemod.nc
    rm -f ${froot}_icemod_tmp.nc
fi

# create time axis
$cdo showdate ${froot}_icemod.nc | tr '[:blank:]' '\n' | \
   awk -F '-' '/^[0-9]/ {print $1+($2-1)/12.}' > tmpdate

# save SST SSH SSS and means
#    To avoid segmentation fault at ECMWF (cca, Monday, June 19, 2017), must
#    remove piping and do it in two steps. Used to be:
#     $cdozip splitvar -selvar,sosstsst,sosaline,sossheig,sowaflup ${froot}_grid_T.nc ${out}_
#    Now:
tempf=$(mktemp $SCRATCH/tmp_ecearth3/tmp/hireclim2_nemo_XXXXXX)
$cdo selvar,sosstsst,sosaline,sossheig ${froot}_grid_T.nc $tempf
$cdozip selvar,sowaflup ${froot}_${SBC}.nc ${out}_sowaflup
$cdozip splitvar $tempf ${out}_
rm -f $tempf

for v in sosstsst sosaline sossheig # -- rename if needed, and average
do
   [[ -f ${out}_${v}.nc4 ]] && mv ${out}_${v}.nc4 ${out}_${v}.nc
   (( $cdftools4 )) && $cdftoolsbin/cdfmean -f ${froot}_grid_T.nc -v $v -p T \
           || $cdftoolsbin/cdfmean ${froot}_grid_T.nc $v T
   #$cdozip -selvar,mean_$v cdfmean.nc  ${out}_${v}_mean.nc
   $cdozip copy cdfmean.nc  ${out}_${v}_mean.nc
done
for v in sowaflup
do
   [[ -f ${out}_${v}.nc4 ]] && mv ${out}_${v}.nc4 ${out}_${v}.nc
   (( $cdftools4 )) && $cdftoolsbin/cdfmean -f ${froot}_${SBC}.nc -v $v -p T \
           || $cdftoolsbin/cdfmean ${froot}_${SBC}.nc $v T
   #$cdozip -selvar,mean_$v cdfmean.nc  ${out}_${v}_mean.nc
   $cdozip copy cdfmean.nc  ${out}_${v}_mean.nc
done


# save global salinity and temperature mean
for v in votemper vosaline; do
    (( $cdftools4 )) && $cdftoolsbin/cdfmean -f ${froot}_grid_T.nc -v $v -p T \
            || $cdftoolsbin/cdfmean ${froot}_grid_T.nc $v T 
    #$cdozip -selvar,mean_$v,mean_3D$v cdfmean.nc  ${out}_${v}_mean.nc
    $cdozip copy cdfmean.nc  ${out}_${v}_mean.nc
done

# ** ice diagnostics

tempf=$(mktemp $SCRATCH/tmp_ecearth3/tmp/hireclim2_nemo_XXXXXX)

$cdo selvar,iiceconc,iicethic ${froot}_icemod.nc $tempf
$cdozip splitvar $tempf ${out}_
rm -f $tempf

for v in iiceconc iicethic; do
    ff=${out}_${v}.nc
    if [ -f ${ff}4 ]; then mv ${ff}4 ${ff}; fi
done

if (( $cdftools4 ))
then
    $cdozip selvar,iiceconc,iicethic ${froot}_icemod.nc ${out}_ice.nc    
    $cdftoolsbin/cdficediags -i ${froot}_icemod_cdfnew.nc -lim3 -o ${out}_icediags.nc
else
    $cdozip selvar,iiceconc,iicethic ${froot}_icemod.nc ${out}_ice.nc
    $cdftoolsbin/cdficediags ${froot}_icemod.nc -lim3
    cp icediags.nc ${out}_icediags.nc
fi

# ** MOC
if ! ncdump -h ${froot}_grid_V.nc | grep -q "^[[:blank:]]*depthv *="
then
    echo "*II* 'olevel' dimension of grid_V file renamed 'depthv'"

    ncks -3 ${froot}_grid_V.nc ${froot}_grid_V_tmp.nc
    ncrename -O -d .olevel,depthv  ${froot}_grid_V_tmp.nc ${froot}_grid_V.nc
    rm -f ${froot}_grid_V_tmp.nc
fi

if (( $cdftools4 ))
then
    $cdftoolsbin/cdfmoc -v ${froot}_grid_V.nc -o ${out}_moc.nc
else
    $cdftoolsbin/cdfmoc ${froot}_grid_V.nc
    $cdozip copy moc.nc ${out}_moc.nc
fi

if [[ $nemo_extra == 1 ]] ; then

    # ** heat content
    tmpstring=tmpdate
    for l in 0_300 300_800 800_bottom
    do
        # when running cdftools 3.0.1, this is the only part where a newer syntax is required
        if (( $cdftools301 ))
        then
            eval "${cdftoolsbin}/cdfheatc -f ${froot}_grid_T.nc -zoom 0 0 0 0 \$depth_$l" | \
                awk '/Total Heat content        :/ {print $5}' > tmp_$l
        else
            eval "${cdftoolsbin}/cdfheatc ${froot}_grid_T.nc 0 0 0 0 \$depth_$l" | \
                awk '/Total Heat content        :/ {print $5}' > tmp_$l
        fi
        
        tmpstring+=" tmp_$l"
        $cdo -f nc settaxis,${year}-01-01,12:00:00,1mon -input,r1x1 ${out}_${l}_heatc.nc < tmp_$l
    done

    if (( $cdftools4 ))
    then
        # ** Nino3.4 SST
        (( ! $skip_nino )) &&
            $cdftoolsbin/cdfmean -f ${froot}_grid_T.nc -v sosstsst -p T -w $nino34_region 0 0 -o ${out}_sosstsst_nino34.nc

        # barotropic stream function
        #rhino: seg fault!    $cdftoolsbin/cdfpsi -u ${froot}_grid_U.nc -v ${froot}_grid_V.nc -o ${out}_psi.nc

        # mixed layer depth
        #rhino: seg fault!    $cdftoolsbin/cdfmxl -t ${froot}_grid_T.nc -o ${out}_mxl.nc

    else
        # ** Nino3.4 SST
        if (( ! $skip_nino )) ; then
            $cdftoolsbin/cdfmean ${froot}_grid_T.nc sosstsst T $nino34_region 0 0
            $cdozip copy cdfmean.nc  ${out}_sosstsst_nino34.nc
        fi

        # barotropic stream function
        $cdftoolsbin/cdfpsi ${froot}_grid_U.nc ${froot}_grid_V.nc
        $cdozip copy psi.nc ${out}_psi.nc

        # mixed layer depth
        # TODO fix this (crashes with cdftools 3.0.1)
        #  File bathy_level.nc is missing 
        # Read mbathy in mesh_zgr.nc ...
        #forrtl: error (73): floating divide by zero
        #$cdftoolsbin/cdfmxl ${froot}_grid_T.nc
        #$cdozip copy mxl.nc ${out}_mxl.nc

    fi

    # TODO : add case for newer cdftools syntax    
    if [[ $cdftools4 == 0 ]] ; then

        #compute potential and in situ density
        $cdftoolsbin/cdfsiginsitu ${froot}_grid_T.nc
        $cdftoolsbin/cdfsig0 ${froot}_grid_T.nc
        ncatted -a valid_min,vosigma0,m,f,0 -a valid_max,vosigma0,m,f,100 sig0.nc -o new_sig0.nc
        ncatted -a valid_min,vosigmainsitu,m,f,0 -a valid_max,vosigmainsitu,m,f,100 siginsitu.nc -o new_siginsitu.nc

        #0-350m upper ocean salinity and temperature
        $cdftoolsbin/cdfvertmean ${froot}_grid_T.nc vosaline T 0 350
        ncatted -a valid_max,vosaline_vert_mean,m,f,50 vertmean.nc -o new_vertmean.nc
        $cdozip chname,vosaline_vert_mean,mlsaline -setctomiss,0 new_vertmean.nc ${out}_mlsaline.nc
        rm new_vertmean.nc
        $cdftoolsbin/cdfvertmean ${froot}_grid_T.nc votemper T 0 350
        ncatted -a valid_min,votemper_vert_mean,m,f,-5 -a valid_max,votemper_vert_mean,m,f,50 vertmean.nc -o new_vertmean.nc
        $cdozip chname,votemper_vert_mean,mltemper -setctomiss,0 new_vertmean.nc ${out}_mltemper.nc
        rm new_vertmean.nc

        #0-350m upper ocean density (potential and in-situ)
        $cdftoolsbin/cdfvertmean new_siginsitu.nc vosigmainsitu T 0 350
        $cdozip chname,vosigmainsitu_vert_mean,mlsigmas -setctomiss,0 vertmean.nc ${out}_mlsigmas.nc
        $cdftoolsbin/cdfvertmean new_sig0.nc vosigma0 T 0 350
        $cdozip chname,vosigma0_vert_mean,mlsigma0 -setctomiss,0 vertmean.nc ${out}_mlsigma0.nc

        #surface currents
        $cdftoolsbin/cdfvertmean ${froot}_grid_U.nc vozocrtx U 0 10
        ncatted -a valid_min,vozocrtx_vert_mean,m,f,-10 -a valid_max,vozocrtx_vert_mean,m,f,10 vertmean.nc -o new_vertmean.nc
        $cdozip chname,vozocrtx_vert_mean,sfczoncu -setctomiss,0 new_vertmean.nc ${out}_sfczoncu.nc
        rm new_vertmean.nc
        $cdftoolsbin/cdfvertmean ${froot}_grid_V.nc vomecrty V 0 10
        ncatted -a valid_min,vomecrty_vert_mean,m,f,-10 -a valid_max,vomecrty_vert_mean,m,f,10 vertmean.nc -o new_vertmean.nc
        $cdozip chname,vomecrty_vert_mean,sfcmercu -setctomiss,0 new_vertmean.nc ${out}_sfcmercu.nc

        #zonally averaged profiles of temperatures and salinity
        $cdftoolsbin/cdfzonalmean ${froot}_grid_T.nc T new_maskglo.nc
        for vv in zotemper_glo zotemper_atl zotemper_inp zotemper_ind zotemper_pac \
                               zosaline_glo zosaline_atl zosaline_inp zosaline_ind zosaline_pac     ; do
            ncatted -a valid_min,$vv,m,f,-10 -a valid_max,$vv,m,f,40 zonalmean.nc -o tmp_zonalmean.nc
            mv tmp_zonalmean.nc zonalmean.nc ; rm -f tmp_zonalmean.nc
        done
        $cdozip selvar,nav_lon,nav_lat,zotemper_glo,zotemper_atl,zotemper_inp,zotemper_ind,zotemper_pac zonalmean.nc ${out}_zotemper.nc
        $cdozip selvar,nav_lon,nav_lat,zosaline_glo,zosaline_atl,zosaline_inp,zosaline_ind,zosaline_pac zonalmean.nc ${out}_zosaline.nc

        #zonally averaged profiles of density
        $cdftoolsbin/cdfzonalmean new_sig0.nc T new_maskglo.nc
        $cdozip copy zonalmean.nc ${out}_zosigma0.nc
        $cdftoolsbin/cdfzonalmean new_siginsitu.nc T new_maskglo.nc
        $cdozip copy zonalmean.nc ${out}_zosigmas.nc

        #regular-1grid-defined yearly-averaged multilevel T,S and sigma0 and sigmainsitu
        $cdozip setctomiss,0 -yearmean -selvar,votemper,vosaline ${froot}_grid_T.nc temp0.nc
        $cdozip remapbil,global_1 -setctomiss,0 -yearmean -setgrid,temp0.nc -selvar,vosigmainsitu new_siginsitu.nc temp1.nc
        $cdozip -b 32 remapbil,global_1 temp0.nc temp2.nc
        $cdozip remapbil,global_1 -setctomiss,0 -yearmean -setgrid,temp0.nc -selvar,vosigma0 new_sig0.nc temp3.nc
        $cdozip merge temp1.nc temp2.nc temp3.nc fulloce.nc
        mv fulloce.nc ${out}_fulloce.nc

    fi # $cdftools4 == 0

fi # $nemo_extra == 1

cd -
rm -rf $WRKDIR
