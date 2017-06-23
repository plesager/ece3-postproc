#!/bin/bash
set -ex

 ############################################
 # To be called from ../master_hiresclim.sh #
 ############################################

mlegs=${monthly_leg}  # env variable (1 if using monthly legs, 0 yearly)

#reading args
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
WRKDIR=$(mktemp -d $SCRATCH/tmp_ecearth3/post_hireclim2_XXXXXX) 
cd $WRKDIR

#where to get the files
NEMORESULTS=$BASERESULTS/nemo/$(printf %03d $((year-${yref}+1)))

NOMP=${NEMO_NPROCS}

# Nemo output filenames start with...
froot=${expname}_1m_${year}0101_${year}1231

# where to save (archive) the results
OUTDIR=$OUTDIR0/mon/Post_$year
mkdir -p $OUTDIR || exit -1

# output filename root
out=$OUTDIR/${expname}_${year}

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
    nino34_region='470 668 519 479'
    ;;
    ( ORCA025L75 )
    # depth layers for heat content (0-300m, 300-800m, 800m-bottom)
    depth_0_300='1 34'
    depth_300_800='35 44'
    depth_800_bottom='45 75'
    # Nino3.4 region (in ij coordinates)
    nino34_region='470 668 519 479' # TODO NEED UPDATE WRONG INDICES !!!
    ;;
    ( * ) echo Stop: NEMOCONFIG=$NEMOCONFIG not defined ; exit -1 ;;
esac


# mask and mesh files
ln -s $MESHDIR/mask.nc
ln -s $MESHDIR/mesh_hgr.nc
ln -s $MESHDIR/mesh_zgr.nc
ln -s $MESHDIR/new_maskglo.nc

# rebuild if necessary
for t in grid_T grid_U grid_V icemod 
do
   if [ -f $NEMORESULTS/${froot}_${t}.nc ]
   then
      cp $NEMORESULTS/${froot}_${t}.nc .
   else
      ln -s $NEMORESULTS/${froot}_${t}* .
      $rbld -t $NOMP ${froot}_$t  $(ls ${froot}_${t}_????.nc | wc -w)
      cp ${froot}_${t}.nc $NEMORESULTS
      rm -f ${froot}_${t}_????.nc
   fi
done

# ** AVAILABILITY

# NEMO files - TODO: should this be retrieved from a dir list, or should exist for processing to go forward?
NEMO_SAVED_FILES="grid_T grid_U grid_V icemod"

itf=1   # 1: means grid_T is available 
iuf=1   # 1: means grid_U is available 
ivf=1   # 1: means grid_V is available 
iif=1   # 1: means icemod is available 

if [ ${itf} -eq 0 -o ${iif} -eq 0 ]; then
    echo "*EE*  grid_T and icemod files required for nemo_post.sh"
    exit 1
fi


# NEMO variables as currently named in EC-Earth output
nm_wfo="wfo"        ; # water flux 
nm_sst="tos"        ; # SST (2D)
nm_sss="sos"        ; # SS salinity (2D)
nm_ssh="zos"        ; # sea surface height (2D)
nm_iceconc="siconc" ; # Ice concentration as in icemod file (2D)
nm_icethic="sithic" ; # Ice thickness as in icemod file (2D)
nm_tpot="thetao"    ; # pot. temperature (3D)
nm_s="so"           ; # salinity (3D)
nm_u="uo"           ; # X current (3D)
nm_v="vo"           ; # Y current (3D)

if [ "${nm_sst}"  != "sosstsst" ];  then ncrename -v ${nm_sst},sosstsst  ${froot}_grid_T.nc ; fi
if [ "${nm_sss}"  != "sosaline" ];  then ncrename -v ${nm_sss},sosaline  ${froot}_grid_T.nc ; fi
if [ "${nm_ssh}"  != "sossheig" ];  then ncrename -v ${nm_ssh},sossheig  ${froot}_grid_T.nc ; fi
if [ "${nm_wfo}"  != "sowaflup" ];  then ncrename -v ${nm_wfo},sowaflup  ${froot}_grid_T.nc ; fi
if [ "${nm_tpot}" != "votemper" ];  then ncrename -v ${nm_tpot},votemper ${froot}_grid_T.nc ; fi
if [ "${nm_s}"    != "vosaline" ];  then ncrename -v ${nm_s},vosaline    ${froot}_grid_T.nc ; fi
if [ ${iuf} -eq 1 ]; then
    if [ "${nm_u}"   != "vozocrtx" ];  then ncrename -v ${nm_u},vozocrtx    ${froot}_grid_U.nc ; fi
fi
if [ ${ivf} -eq 1 ]; then
    if [ "${nm_v}"   != "vomecrty" ];  then ncrename -v ${nm_v},vomecrty    ${froot}_grid_V.nc ; fi
fi
if [ "${nm_iceconc}" != "iiceconc" ]; then ncrename -v ${nm_iceconc},iiceconc  ${froot}_icemod.nc ; fi
if [ "${nm_icethic}" != "iicethic" ]; then ncrename -v ${nm_icethic},iicethic  ${froot}_icemod.nc ; fi


# create time axis
$cdo showdate ${froot}_icemod.nc | tr '[:blank:]' '\n' | \
   awk -F '-' '/^[0-9]/ {print $1+($2-1)/12.}' > tmpdate

# save SST SSH SSS and means
#    To avoid segmentation fault at ECMWF (cca, Monday, June 19, 2017), must
#    remove piping and do it in two steps. Used to be:
#     $cdozip splitvar -selvar,sosstsst,sosaline,sossheig,sowaflup ${froot}_grid_T.nc ${out}_
#    Now:
tempf=$(mktemp $SCRATCH/tmp_ecearth3/post_hireclim2_nemo_XXXXXX)
$cdo selvar,sosstsst,sosaline,sossheig,sowaflup ${froot}_grid_T.nc $tempf
$cdozip splitvar $tempf ${out}_
rm -f $tempf

for v in sosstsst sosaline sossheig sowaflup
do
   mv ${out}_${v}.nc4 ${out}_${v}.nc
   $cdftoolsbin/cdfmean ${froot}_grid_T.nc $v T
   #$cdozip -selvar,mean_$v cdfmean.nc  ${out}_${v}_mean.nc
   $cdozip copy cdfmean.nc  ${out}_${v}_mean.nc
done

# save global salinity and temperature mean
for v in votemper vosaline; do
    $cdftoolsbin/cdfmean ${froot}_grid_T.nc $v T 
    #$cdozip -selvar,mean_$v,mean_3D$v cdfmean.nc  ${out}_${v}_mean.nc
    $cdozip copy cdfmean.nc  ${out}_${v}_mean.nc
done

# ** ice diagnostics

tempf=$(mktemp $SCRATCH/tmp_ecearth3/post_hireclim2_ice_XXXXXX)
$cdo selvar,iiceconc,iicethic ${froot}_icemod.nc $tempf
$cdozip splitvar $tempf ${out}_
rm -f $tempf

for v in iiceconc iicethic; do
    ff=${out}_${v}.nc
    if [ -f ${ff}4 ]; then mv ${ff}4 ${ff}; fi
done


# ** heat content
tmpstring=tmpdate
for l in 0_300 300_800 800_bottom
do
    eval "${cdftoolsbin}/cdfheatc ${froot}_grid_T.nc 0 0 0 0 \$depth_$l" | \
        awk '/Total Heat content        :/ {print $5}' > tmp_$l
   tmpstring+=" tmp_$l"
   $cdo -f nc settaxis,${year}-01-01,12:00:00,1mon -input,r1x1 ${out}_${l}_heatc.nc < tmp_$l
done

# ** Nino3.4 SST
$cdftoolsbin/cdfmean ${froot}_grid_T.nc sosstsst T $nino34_region 0 0
$cdozip copy cdfmean.nc  ${out}_sosstsst_nino34.nc

# ** MOC
$cdftoolsbin/cdfmoc ${froot}_grid_V.nc
$cdozip copy moc.nc ${out}_moc.nc

# barotropic stream function
$cdftoolsbin/cdfpsi ${froot}_grid_U.nc ${froot}_grid_V.nc
$cdozip copy psi.nc ${out}_psi.nc

# mixed layer depth
$cdftoolsbin/cdfmxl ${froot}_grid_T.nc
$cdozip copy mxl.nc ${out}_mxl.nc

# ice diagnostics
$cdozip selvar,iiceconc,iicethic \
   ${froot}_icemod.nc ${out}_ice.nc
$cdftoolsbin/cdficediags ${froot}_icemod.nc -lim3
cp icediags.nc ${out}_icediags.nc


if [ $nemo_extra == 1 ] ; then

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

fi

# rm $TMPDIR/nam_rebuild
# rm $TMPDIR/*nc
# rm $TMPDIR/tmp*
# rm $TMPDIR/*txt


cd -
rm -rf $WRKDIR
