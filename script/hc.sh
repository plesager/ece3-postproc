#!/usr/bin/env bash

usage()
{
   echo "Usage:"
   echo "       hc.sh [-a account] [-r rundir] [-m] EXP YEAR1 YEAR2 YREF"
   echo
   echo "Submit to a job scheduler an HIRESCLIM2 postprocessing of experiment EXP"
   echo " (started in YREF) from YEAR1 to YEAR2. The script makes a wrapper around"
   echo " master_hiresclim.sh, and submit it through the job scheduler."
   echo
   echo "Submitted scripts and logs are in $SCRATCH/tmp_ecearth3"
   echo
   echo "Options are:"
   echo "   -a ACCOUNT  : specify a different special project for accounting (default $ECE3_POSTPROC_ACCOUNT)"
   echo "   -c          : check for success"
   echo "   -r RUNDIR   : fully qualified path to another user EC-Earth top RUNDIR"
   echo "                   that is RUNDIR/EXP/output must exists and be readable"
   echo "   -m          : run was performed with Monthly legs (yearly legs expected by default)"
}

set -e

# -- default options
account=$ECE3_POSTPROC_ACCOUNT

# -- options
while getopts "hcr:a:m" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        m)  options=${options}" -m"
            ;;
        r)  options=${options}" -r $OPTARG"
            ALT_RUNDIR="$OPTARG"
            ;;
        c)  checkit=1
            ;;
        a)  account=$OPTARG
            ;;
        *)  usage
            exit 1
    esac
done
shift $((OPTIND-1))

if [ $# -ne 4 ]; then
   usage
   exit 1
fi

# -- Sanity checks (from master_hiresclim.sh, repeated here for a "before submission" error catch)
[[ -z $ECE3_POSTPROC_TOPDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_RUNDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_MACHINE ]] && echo "User environment not set. See ../README." && exit 1 

# -- get submit command
CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}

. ${CONFDIR}/conf_hiresclim_${ECE3_POSTPROC_MACHINE}.sh

if [[ -n $ALT_RUNDIR ]]
then
    outdir=$ALT_RUNDIR/$1/output
else
    outdir=${ECE3_POSTPROC_RUNDIR}/$1/output
fi
[[ ! -d $outdir ]] && echo "User experiment output $outdir does not exist!" && exit 1


# -- check previous processing
if (( checkit ))
then
    for YEAR in $(eval echo {$2..$3})
    do 
        echo; echo "-- check $YEAR--"; echo
        cat ${ECE3_POSTPROC_RUNDIR}/$1/post/postcheck_$1_$YEAR.txt || \
            echo "*EE* check log at $SCRATCH/tmp_ece3_hiresclim2"
    done
    exit
fi


# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ece3_hiresclim2
mkdir -p $OUT/log

# -- Write and submit one script per year
for YEAR in $(eval echo {$2..$3})
do 
    tgt_script=$OUT/hc_$1_$YEAR.job
    sed "s/<EXPID>/$1/" < ${CONFDIR}/hc_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script

    [[ -n $account ]] && \
        sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
        sed -i "/<ACCOUNT>/ d" $tgt_script

    sed -i "s/<YEAR>/$YEAR/" $tgt_script
    sed -i "s|<YREF>|$4|" $tgt_script
    sed -i "s|<OUT>|$OUT|" $tgt_script
    sed -i "s|<OPTIONS>|${options}|" $tgt_script
    ${submit_cmd} $tgt_script
done
