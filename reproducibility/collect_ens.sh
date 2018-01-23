#!/bin/bash
#
# Purpose
# =======
#    Extract the Reichler & Kim performance indices for a set of variables and
#    from all members of an ensemble.
#    The result is one file per variable, format expected by the R scripts.
#
#    Option to tar the results with the 2x2 climatology of all runs
# Author: Martin Ménégoz
#         Updated by Francois Massonnet (last update: November 2017)
#
# P. Le Sager (Jan 2018) - added to and adapted for the ece3-postproc tools suite package 

set -o errexit

usage()
{
    echo
    echo "Usage:   ${0##*/} [-t] STEM  NB_MEMBER  YEAR_START  YEAR_END"
    echo
    echo "   STEM       : 3-letters STEM name of the ENSEMBLE experiments (\${STEM}1, \${STEM}2, ...)"
    echo "   NB_MEMBER  : number of members (maximum 9)"
    echo "   YEAR_START : start year of the run"
    echo "   YEAR_END   : end year of the run"
    echo
    echo "Options are:"
    echo "   -t         : tar the PI index results, with the 2x2 climatology, for easy sharing."
}

do_tar=0
while getopts "h?t" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        t)  
            do_tar=1
            ;;
        *)  
            usage
            exit 1
    esac
done
shift $((OPTIND-1))

# --- Check and store args

if [ $# -ne 4 ]
then
    echo; echo "*EE* not enough arguments !!"; echo
    usage
    exit 1
fi

if [[ ! $1 =~ ^[a-Z_0-9]{3}$ ]]
then
    echo; echo "*EE* argument STEM name (=$1) should be a 3-character string"; echo
    usage
    exit 1
fi

if [[ ! $2 =~ ^[1-9]$ ]]
then
    echo ;echo "*EE* argument NB_MEMBER (=$2) should be between 1 and 9"; echo
    usage
    exit 1
fi

if [[ ! $3 =~ ^[0-9]{4}$ ]]
then
    echo ;echo "*EE* argument YEAR_START (=$3) should be a 4-digit integer"; echo
    usage
    exit 1
fi

if [[ ! $4 =~ ^[0-9]{4}$ ]]
then
    echo; echo "*EE* argument YEAR_END (=$4) should be a 4-digit integer"; echo
    usage
    exit 1
fi

root=$1
nb=$2
year1=$3
year2=$4

# --- Get location of the tables to parse 
. $ECE3_POSTPROC_TOPDIR/conf/$ECE3_POSTPROC_MACHINE/conf_ecmean_${ECE3_POSTPROC_MACHINE}.sh

TABLEDIR=${OUTDIR}/${root}      # ensemble table dir
mkdir -p $TABLEDIR

# --- Location of EC-mean 2x2 climatologies

if [[ -n $CLIMDIR ]] 
then
    echo "we may have a problem: not fully implemented"
else
    # Assume default location for 2x2 climatology (See ECmean/EC-mean.sh)
    CLIMDIR=${ECE3_POSTPROC_RUNDIR}/${root}[1-$nb]/post/clim-${year1}-${year2}
    CLIMTOPDIR=${ECE3_POSTPROC_RUNDIR}
fi

# --- Extract PIs into one file per variable

var2d="t2m msl qnet tp ewss nsss SST SSS SICE T U V Q"

for var in ${var2d}
do
    for k in $(eval echo {1..$nb})
    do
        cat ${TABLEDIR}${k}/PI2_RK08_${root}${k}_${year1}_${year2}.txt | grep "^${var} " | \
            tail -1  | \
            awk {'print $2'} >> $TABLEDIR/${root}_${year1}_${year2}_${var}.txt
    done
done

# --- Archive everything needed for comparison with another ensemble

if (( do_tar ))
then
    arch=$SCRATCH/reprod-${root}-${year1}-${year2}.tar

    cd $OUTDIR
    tar -cvf $arch ${root}

    cd $CLIMTOPDIR
    if [[ -d ${root}1/post/clim-${year1}-${year2} ]]
    then
        tar --append -vf $arch ${root}[1-$nb]/post/clim-${year1}-${year2}
    else
        echo "*EE* 2x2 EC-mean climatology is missing!!"
    fi
fi
