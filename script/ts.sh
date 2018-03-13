#!/bin/bash

usage()
{
    echo "Usage: ts.sh [-a account] [-u userexp] [-r ALT_RUNDIR] [-c] EXP"
    echo
    echo "Submit to a job scheduler the computation of timeseries for experiment EXP"
    echo
    echo "This is basically a wrapper around the timeseries.sh script."
    echo 
    echo "Options are:"
    echo "   -c          : check if processing was successful"
    echo "   -a account  : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT:-unknown})"
    echo "   -u USERexp  : alternative user owner of the experiment, default $USER"
    echo "   -r ALT_RUNDIR : fully qualified path to another user EC-Earth top RUNDIR"
    echo "                   that is RUNDIR/EXP/post must exists and be readable"
}

set -ue

# -- default option
account="${ECE3_POSTPROC_ACCOUNT-}"
checkit=0

while getopts "h?cur:a:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        u)  USERexp=$OPTARG
            ;;
        r)  ALT_RUNDIR=$OPTARG
            ;;
        c)  checkit=1
            ;;
        a)  account=$OPTARG
            ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 1 ]; then
    usage 
    exit 0
fi

# set variables which can be eval'd
EXPID=$1

# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT/log

CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}

# -- get OUTDIR, submit command
. ${CONFDIR}/conf_timeseries_${ECE3_POSTPROC_MACHINE}.sh

# -- add here options for submit commands
case "${submit_cmd}" in
        sbatch) queue_cmd="squeue -u $USER  -o %.16j" ;;
esac

#!! TOLGO, c'Ã in timeseries.sh
# -- check input dir exist (from EC-mean.sh, repeated here for a "before submission" error catch)
#if [[ -n $ALT_RUNDIR ]]
#then
#    indir=`eval echo ${ALT_RUNDIR}`/mon/
#else
#    indir=`eval echo ${ECE3_POSTPROC_POSTDIR}`/mon
#fi
#[[ ! -d $indir ]] && echo "*EE* Experiment HiresClim2 output dir $indir does not exist!" && exit 1


# -- submit script
tgt_script=$OUT/ts_$1.job

sed "s/<EXPID>/$1/" < ${CONFDIR}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script

[[ -n $account ]] && \
    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
    sed -i "/<ACCOUNT>/ d" $tgt_script

sed -i "s/<JOBID>/ts/" $tgt_script
sed -i "s/<Y1>//" $tgt_script
sed -i "s|<OUT>|$OUT|" $tgt_script

echo ../timeseries/timeseries.sh $1 $USERexp >> $tgt_script

${submit_cmd} $tgt_script

