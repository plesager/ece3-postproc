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
ln -s $MESHDIR/new_maskglo.nc # TODO NEED FILE FOR HIRES !!!

# rebuild if necessary
for t in grid_T grid_U grid_V icemod 
do
   if [ -f $NEMORESULTS/${froot}_${t}.nc ]
   then
      ln -s $NEMORESULTS/${froot}_${t}.nc .
   else
      ln -s $NEMORESULTS/${froot}_${t}* .
      $rbld -t $NOMP ${froot}_$t  $(ls ${froot}_${t}_????.nc | wc -w)
      cp ${froot}_${t}.nc $NEMORESULTS
      rm -f ${froot}_${t}_????.nc
   fi
done

# create time axis
$cdo showdate ${froot}_icemod.nc | tr '[:blank:]' '\n' | \
   awk -F '-' '/^[0-9]/ {print $1+($2-1)/12.}' > tmpdate

# save SST SSH SSS and means (removed sowaflup["Net Upward Water Flux"], not readily available anymore)
#    Replaced sosstsst,sosaline,sossheig with tos,sos,zos
#    To avoid segmentation fault at ECMWF (cca, Monday, June 19, 2017), must
#    remove piping and do it in two steps. Used to be:
#     $cdozip splitvar -selvar,tos,sos,zos ${froot}_grid_T.nc ${out}_
#    Now:
tempf=$(mktemp $SCRATCH/tmp_ecearth3/post_hireclim2_nemo_XXXXXX)
$cdo selvar,tos,sos,zos ${froot}_grid_T.nc $tempf
$cdozip splitvar $tempf ${out}_
rm -f $tempf

for v in tos sos zos
do
   mv ${out}_${v}.nc4 ${out}_${v}.nc
   $cdftoolsbin/cdfmean ${froot}_grid_T.nc $v T
   #$cdozip -selvar,mean_$v cdfmean.nc  ${out}_${v}_mean.nc
   $cdozip copy cdfmean.nc  ${out}_${v}_mean.nc
done

# save global salinity and temperature mean
#OLD: for v in votemper vosaline; do
for v in thetao so; do
    $cdftoolsbin/cdfmean ${froot}_grid_T.nc $v T 
    #$cdozip -selvar,mean_$v,mean_3D$v cdfmean.nc  ${out}_${v}_mean.nc
    $cdozip copy cdfmean.nc  ${out}_${v}_mean.nc
done

# ** ice diagnostics
# OLD $cdozip splitvar -selvar,iiceconc,iicethic   ${froot}_icemod.nc ${out}_

tempf=$(mktemp $SCRATCH/tmp_ecearth3/post_hireclim2_ice_XXXXXX)
$cdo selvar,siconc,sithick ${froot}_icemod.nc $tempf
$cdozip splitvar $tempf ${out}_
rm -f $tempf

#$cdozip splitvar -selvar,siconc,sithick   ${froot}_icemod.nc ${out}_

for v in siconc sithick; do
    ff=${out}_${v}.nc
    if [ -f ${ff}4 ]; then mv ${ff}4 ${ff}; fi
done


# ** heat content
# FORTRAN RUNTIME ERROR FIXME eval "$cdftoolsbin/cdfheatc ${froot}_grid_T.nc 0 0 0 0 0 0 " | \
# FORTRAN RUNTIME ERROR FIXME       awk '/Total Heat content        :/ {print $5}' > tmpheat
# FORTRAN RUNTIME ERROR FIXME $cdo -f nc settaxis,${year}-01-01,12:00:00,1mon -input,r1x1 ${out}_heatc.nc < tmpheat

# ** Nino3.4 SST
#TODO FIX INDICES $cdftoolsbin/cdfmean ${froot}_grid_T.nc tos T $nino34_region 0 0
#TODO FIX INDICES $cdozip copy cdfmean.nc  ${out}_tos_nino34.nc

# ** MOC
# WRONG AUXILIARY FILE? $cdftoolsbin/cdfmoc ${froot}_grid_V.nc
# WRONG AUXILIARY FILE? $cdozip copy moc.nc ${out}_moc.nc
#
# Got following error:
#   ....
#   e3t_0 has           4 dimensions
#   Variable            1  is zomsfglo
#   Variable            2  is zomsfatl
#   Variable            3  is zomsfinp
#   Variable            4  is zomsfind
#   Variable            5  is zomsfpac
#   Variable            6  is zomsfinp0
#    Problem in getvar for tmaskatl
#   ERROR in NETCDF routine, status=         -57
#   NetCDF: Start+count exceeds dimension bound                                     


# ** barotropic stream function
#TODO MISSING VARIABLE $cdftoolsbin/cdfpsi ${froot}_grid_U.nc ${froot}_grid_V.nc
#TODO MISSING VARIABLE $cdozip copy psi.nc ${out}_psi.nc

# ** mixed layer depth
#TODO MISSING VARIABLE $cdftoolsbin/cdfmxl ${froot}_grid_T.nc
#TODO MISSING VARIABLE $cdozip copy mxl.nc ${out}_mxl.nc

# ** ice diagnostics
# OLD $cdozip selvar,iiceconc,iicethic \
#TODO RENAME VARIABLE SICONC TO IICECONC EXPECTED BY CDFTOOLS $cdozip selvar,siconc,sithick \
#TODO RENAME VARIABLE SICONC TO IICECONC EXPECTED BY CDFTOOLS    ${froot}_icemod.nc ${out}_ice.nc
#TODO RENAME VARIABLE SICONC TO IICECONC EXPECTED BY CDFTOOLS $cdftoolsbin/cdficediags ${froot}_icemod.nc -lim3
#TODO RENAME VARIABLE SICONC TO IICECONC EXPECTED BY CDFTOOLS cp icediags.nc ${out}_icediags.nc

if [ $nemo_extra == 1 ] ; then

    # compute potential and in situ density
    $cdftoolsbin/cdfsiginsitu ${froot}_grid_T.nc
    $cdftoolsbin/cdfsig0 ${froot}_grid_T.nc
    ncatted -a valid_min,vosigma0,m,f,0 -a valid_max,vosigma0,m,f,100 sig0.nc -o new_sig0.nc
    ncatted -a valid_min,vosigmainsitu,m,f,0 -a valid_max,vosigmainsitu,m,f,100 siginsitu.nc -o new_siginsitu.nc

    # 0-350m upper ocean salinity and temperature
    $cdftoolsbin/cdfvertmean ${froot}_grid_T.nc so T 0 350
    ncatted -a valid_max,so_vert_mean,m,f,50 vertmean.nc -o new_vertmean.nc
    $cdozip chname,so_vert_mean,mlsaline -setctomiss,0 new_vertmean.nc ${out}_mlsaline.nc
    rm new_vertmean.nc
    $cdftoolsbin/cdfvertmean ${froot}_grid_T.nc thetao T 0 350
    ncatted -a valid_min,thetao_vert_mean,m,f,-5 -a valid_max,thetao_vert_mean,m,f,50 vertmean.nc -o new_vertmean.nc
    $cdozip chname,thetao_vert_mean,mltemper -setctomiss,0 new_vertmean.nc ${out}_mltemper.nc
    rm new_vertmean.nc

    # 0-350m upper ocean density (potential and in-situ)
    $cdftoolsbin/cdfvertmean new_siginsitu.nc vosigmainsitu T 0 350
    $cdozip chname,vosigmainsitu_vert_mean,mlsigmas -setctomiss,0 vertmean.nc ${out}_mlsigmas.nc
    $cdftoolsbin/cdfvertmean new_sig0.nc vosigma0 T 0 350
    $cdozip chname,vosigma0_vert_mean,mlsigma0 -setctomiss,0 vertmean.nc ${out}_mlsigma0.nc

    # surface currents
    $cdftoolsbin/cdfvertmean ${froot}_grid_U.nc vozocrtx U 0 10
    ncatted -a valid_min,vozocrtx_vert_mean,m,f,-10 -a valid_max,vozocrtx_vert_mean,m,f,10 vertmean.nc -o new_vertmean.nc
    $cdozip chname,vozocrtx_vert_mean,sfczoncu -setctomiss,0 new_vertmean.nc ${out}_sfczoncu.nc
    rm new_vertmean.nc
    $cdftoolsbin/cdfvertmean ${froot}_grid_V.nc vomecrty V 0 10
    ncatted -a valid_min,vomecrty_vert_mean,m,f,-10 -a valid_max,vomecrty_vert_mean,m,f,10 vertmean.nc -o new_vertmean.nc
    $cdozip chname,vomecrty_vert_mean,sfcmercu -setctomiss,0 new_vertmean.nc ${out}_sfcmercu.nc

    # zonally averaged profiles of temperatures and salinity
    $cdftoolsbin/cdfzonalmean ${froot}_grid_T.nc T new_maskglo.nc
    for vv in zotemper_glo zotemper_atl zotemper_inp zotemper_ind zotemper_pac \
        zosaline_glo zosaline_atl zosaline_inp zosaline_ind zosaline_pac     ; do
        ncatted -a valid_min,$vv,m,f,-10 -a valid_max,$vv,m,f,40 zonalmean.nc -o tmp_zonalmean.nc
        mv tmp_zonalmean.nc zonalmean.nc ; rm -f tmp_zonalmean.nc
    done
    $cdozip selvar,nav_lon,nav_lat,zotemper_glo,zotemper_atl,zotemper_inp,zotemper_ind,zotemper_pac zonalmean.nc ${out}_zotemper.nc
    $cdozip selvar,nav_lon,nav_lat,zosaline_glo,zosaline_atl,zosaline_inp,zosaline_ind,zosaline_pac zonalmean.nc ${out}_zosaline.nc

    # zonally averaged profiles of density
    $cdftoolsbin/cdfzonalmean new_sig0.nc T new_maskglo.nc
    $cdozip copy zonalmean.nc ${out}_zosigma0.nc
    $cdftoolsbin/cdfzonalmean new_siginsitu.nc T new_maskglo.nc
    $cdozip copy zonalmean.nc ${out}_zosigmas.nc

    # regular-1grid-defined yearly-averaged multilevel T,S and sigma0 and sigmainsitu
    $cdozip setctomiss,0 -yearmean -selvar,thetao,so ${froot}_grid_T.nc temp0.nc
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
