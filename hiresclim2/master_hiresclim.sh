#!/usr/bin/env bash

# Wrapper of postprocessing utility 
# Requires:     1) CDO with netcdf4 for IFS postprocessing
#               2) rebuildndemo and cdftools for NEMO postprocessing    
#               3) python for relative humidity
#               4) nco for supplementary NEMO diags

# Produces IFS postprocessing on monthly, daily and 6hrs basis
# together with  monthly averages for NEMO

# Whatever option you add, the user should not have to edit his file.

set -eu

usage()
{
  echo "Usage:   ./master_hiresclim.sh [-m months_per_leg] [-u userexp] EXP YEAR YREF"
  echo "Example: ./master_hiresclim.sh io01 1995 1990"
}

#########################
# options and arguments #
#########################

months_per_leg=12                  # nb of months per legs. Default: yearly legs.
#ALT_RUNDIR=""
#ALT_POSTDIR=""

while getopts "h?m:r:u:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        m)  months_per_leg=$OPTARG
            ;;
        u)  USERexp=$OPTARG
	    ;;
    esac
done
shift $((OPTIND-1))

if [ $# -ne 3 ]; then
   usage 
   exit 1
fi

if (( 12 % $months_per_leg ))
then
    echo "*EE* there is not a full number of legs in one year. Cannot process."
    exit 1
fi

expname=$1
year=$2
yref=$3
export months_per_leg

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment ECE3_POSTPROC_TOPDIR not set. See ../README." && exit 1

 # load utilities
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# load user and machine specifics
. $ECE3_POSTPROC_TOPDIR/conf/$ECE3_POSTPROC_MACHINE/conf_hiresclim_$ECE3_POSTPROC_MACHINE.sh

########## POST-PROCESSING OPTIONS ###############

# build 3D relative humidity; require python with netCDF4 module. [ON by default]
echo "*II* Rebuild 3D relative humidity: ${rh_build:=1}"

# IFS monthly [ON by default]
# IFS daily and 6hrs flag for u,v,t,z 3d field + tas, totp extraction [OFF by default]
ifs_monthly=${ECE3_POSTPROC_HC_IFS_MONTHLY:-1}
ifs_monthly_mma=${ECE3_POSTPROC_HC_IFS_MONTHLY_MMA:-0}
ifs_daily=${ECE3_POSTPROC_HC_IFS_DAILY:-0}
ifs_6hrs=${ECE3_POSTPROC_HC_IFS_6HRS:-0}

# NEMO [ON by default (applied only if available), Extra (require nco) OFF by default]
nemo=${ECE3_POSTPROC_HC_NEMO:-1}
nemo_extra=${ECE3_POSTPROC_HC_NEMO_EXTRA:-0}

########## HARDCODED OPTIONS ###############

# TODO add option to compute variables only needed for ECMean
#nemo_basic=0

# copy monthly results in a second folder
store=0

# summary? save a postcheck file
fstore=1

############################################################
# dirs and auxiliary files
############################################################

# location
PROGDIR=$ECE3_POSTPROC_TOPDIR/hiresclim2

# cdo table for conversion GRIB parameter --> variable name
export ecearth_table=$PROGDIR/script/ecearth.tab

# get the experiment directories
eval_dirs 1

# create output dir for results
mkdir -p $OUTDIR0

# does IFS output exist?
[[ ! -d $IFSRESULTS ]] && \
    echo "*EE* IFS output dir ($IFSRESULTS) for experiment $expname does not exist!" &&  \
    exit 1

# does NEMO output exist? if interested, find resolution
NEMOCONFIG=""
if [[ -e ${NEMORESULTS} && $nemo == 1 ]]
then 
    nemo=1
  
    a_file=$(ls -1 ${NEMORESULTS}/*grid_V* | head -n1) 
    ysize=$(cdo griddes $a_file | grep ysize | awk '{print $3}')

    case $ysize in
        1050)
            NEMOCONFIG=ORCA025L75
            ;;
        292)
            NEMOCONFIG=ORCA1L75
            ;;
        *)
            echo '*EE* Unaccounted NEMO resolution: ysize=$ysize' && exit 1
    esac
    
    export NEMOCONFIG
    echo "*II* hiresclim2 accounts for nemo output"
else
    nemo=0
fi

INFODIR=$OUTDIR0

# where to find mesh and mask files 
export MESHDIR=${MESHDIR_TOP}/$NEMOCONFIG

cd $PROGDIR/script

######################################
#-----here start the computations----#
######################################

    start1=$(date +%s)
    if [ $ifs_monthly == 1 ] ; then 
        . ./ifs_monthly.sh $expname $year $yref
    fi

    if [ $ifs_monthly_mma == 1 ] ; then 
        . ./ifs_monthly_mma.sh $expname $year $yref
    fi

    if [ $ifs_daily == 1 ] ; then
        . ./ifs_daily.sh $expname $year $yref
    fi

    if [ $ifs_6hrs == 1 ] ; then
        . ./ifs_6hrs.sh $expname $year $yref
    fi

    if [ $nemo == 1 ] ; then
        . ./nemo_post.sh $expname $year $yref $nemo_extra
    fi

    if [ $rh_build == 1 ] ; then
        export OUTDIR0
        $python ../rhbuild/build_RH_new.py $expname $year
    fi

    end1=$(date +%s)
    runtime=$((end1-start1));
    hh=$(echo "scale=3; $runtime/3600" | bc)
    echo "*II* One year postprocessing runtime is $runtime sec (or $hh hrs) "
    echo; echo

    if [ $fstore == 1 ] ; then      
        mkdir -p $INFODIR
        echo "$expname for $year has been postprocessed successfully" > $INFODIR/postcheck_${expname}_${year}.txt
        echo "Postprocessing lasted for $runtime sec (or $hh hrs)" >> $INFODIR/postcheck_${expname}_${year}.txt
        echo "Configuration: MON: $ifs_monthly ; DAY: $ifs_daily ; 6HRS: $ifs_6hrs; "  >> $INFODIR/postcheck_${expname}_${year}.txt
        echo $(date) >> $INFODIR/postcheck_${expname}_${year}.txt
    fi

# copy monthly data
if [ $store == 1 ] ; then

    mkdir -p $STOREDIR/${expname}
    cp -r --update $OUTDIR0/mon/ ${STOREDIR}/${expname}
fi

exit 0
