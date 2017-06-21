#!/usr/bin/env bash

# Wrapper of postprocessing utility 
# Requires:     1) CDO with netcdf4 for IFS postprocessing
#               2) rebuildndemo and cdftools for NEMO postprocessing    
#               3) python for relative humidity
#               4) nco for supplementary NEMO diags

# Produces IFS postprocessing on monthly, daily and 6hrs basis
# together with  monthly averages for NEMO

# TODO: make the oft-used harcoded options either automatic if possible or
# command line option??Ideally user should not have to edit his file.

set -e

usage()
{
  echo "Usage:   ./master_hiresclim.sh [-r rundir] [-m] EXP YEAR YREF"
  echo "Example: ./master_hiresclim.sh io01 1995 1990"
}

#########################
# options and arguments #
#########################

monthly_leg=0

while getopts "h?mr:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        r)  ALT_RUNDIR=$OPTARG
            ;;
        m)  monthly_leg=1
            ;;
    esac
done
shift $((OPTIND-1))

if [ $# -ne 3 ]; then
   usage 
   exit 1
fi

expname=$1
year=$2
yref=$3
export monthly_leg

# load user/machine specifics
[[ -z $ECE3_POSTPROC_TOPDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_RUNDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_MACHINE ]] && echo "User environment not set. See ../README." && exit 1 

. $ECE3_POSTPROC_TOPDIR/conf/conf_hiresclim_$ECE3_POSTPROC_MACHINE.sh


########## HARDCODED OPTIONS ###############

# Flags: 0 is false, 1 is true
# monthly flag for standard hiresclim
# daily and 6hrs flag for u,v,t,z 3d field + tas,totp extraction
ifs_monthly=1
ifs_daily=0
ifs_6hrs=0

# NEMO extra-fields; extra-fields require NCO
nemo_extra=0

# build 3D relative humidity; require python
rh_build=1

# copy monthly results in a second folder
store=0

# summary? save a postcheck file
fstore=1

############################################################
# settings that depend only on the ECE3_POSTPROC_* variables
############################################################

# location
PROGDIR=$ECE3_POSTPROC_TOPDIR/hiresclim2

# cdo table for conversion GRIB parameter --> variable name
export ecearth_table=$PROGDIR/script/ecearth.tab

# where to find the results from the EC-EARTH experiment
if [[ -n $ALT_RUNDIR ]]
then
    export BASERESULTS=$ALT_RUNDIR/$expname/output
else
    export BASERESULTS=${ECE3_POSTPROC_RUNDIR}/$expname/output
fi
[[ ! -d $BASERESULTS ]] && echo "*EE* Experiment output dir $BASERESULTS does not exist!" && exit 1

# where to produce the results
export OUTDIR0=${ECE3_POSTPROC_RUNDIR}/$expname/post
mkdir -p $OUTDIR0

############################################################

# test if it was a coupled run, and find resolution
nemo=0
cf=${BASERESULTS}/nemo
if [ -e ${cf} ]
then 
    nemo=1
    
    a_file=$(ls -1 ${BASERESULTS}/nemo/001/*grid_V* | head -n1)
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

    if [ $ifs_daily == 1 ] ; then
        . ./ifs_daily.sh $expname $year
    fi

    if [ $ifs_6hrs == 1 ] ; then
        . ./ifs_6hrs.sh $expname $year
    fi

    if [ $nemo == 1 ] ; then
        . ./nemo_post.sh $expname $year $yref $nemo_extra
    fi

    if [ $rh_build == 1 ] ; then
        $python ../rhbuild/build_RH_new.py $expname $year
    fi

    end1=$(date +%s)
    runtime=$((end1-start1));
    hh=$(echo "scale=3; $runtime/3600" | bc)
    echo "One year postprocessing runtime is $runtime sec (or $hh hrs) "
    echo; echo

    if [ $fstore == 1 ] ; then      
        mkdir -p $INFODIR
        echo "$expname for $year has been postprocessed successfully" > $INFODIR/postcheck_${expname}_${year}.txt
        echo "Postprocessing lasted for $runtime sec (or $hh hrs)" >> $INFODIR/postcheck_${expname}_${year}.txt
        echo "Configuration: MON: $ifs_monthly ; DAY: $ifs_daily ; 6HRS: $ifs_6hrs; CDX: $ifs_3hrs_cdx ; SMON: $ifs_smon ; NONLIN: $ifs_nonlinear"  >> $INFODIR/postcheck_${expname}_${year}.txt
                echo $(date) >> $INFODIR/postcheck_${expname}_${year}.txt
    fi

# copy monthly data
if [ $store == 1 ] ; then

    mkdir -p $STOREDIR/${expname}
    cp -r --update $OUTDIR0/mon/ ${STOREDIR}/${expname}
fi

exit 0
