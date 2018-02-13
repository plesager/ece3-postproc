#!/bin/bash

usage()
{
    echo "Usage: ts.sh [-a account] [-r rundir] [-c] EXP"
    echo
    echo "Submit to a job scheduler the computation of timeseries for experiment EXP"
    echo
    echo "This is basically a wrapper around the timeseries.sh script."
    echo 
    echo "Options are:"
    echo "   -c          : check if processing was successful"
    echo "   -a account  : specify a different special project for accounting (default $ECE3_POSTPROC_ACCOUNT)"
    echo "   -r RUNDIR   : fully qualified path to another user EC-Earth top RUNDIR"
    echo "                   that is RUNDIR/EXP/post must exists and be readable"
}

set -ue

# -- default option
account=$ECE3_POSTPROC_ACCOUNT
ALT_RUNDIR=""
checkit=0

while getopts "h?cr:a:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
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

# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ecearth3_ts
mkdir -p $OUT/log

CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}

# -- get OUTDIR, submit command
. ${CONFDIR}/conf_ecmean_${ECE3_POSTPROC_MACHINE}.sh

# -- check input dir exist (from EC-mean.sh, repeated here for a "before submission" error catch)
if [[ -n $ALT_RUNDIR ]]
then
    indir=$ALT_RUNDIR/$1/post/mon/
else
    indir="${ECE3_POSTPROC_RUNDIR}/$1/post/mon/"
fi
[[ ! -d $indir ]] && echo "*EE* Experiment HiresClim2 output dir $indir does not exist!" && exit 1


# -- check previous processing
# if (( checkit ))
# then
#     echo "Checking ${HOME}/EC-Earth3/diag/table/globtable.txt..."
#     grep $1.$2-$3. ${HOME}/EC-Earth3/diag/table/globtable.txt || \
#             echo "*EE* check log at $SCRATCH/tmp_ecearth3_ts"
#     exit
# fi


# -- submit script
tgt_script=$OUT/ts_$1.job

sed "s/<EXPID>/$1/" < ${CONFDIR}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script

[[ -n $account ]] && \
    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
    sed -i "/<ACCOUNT>/ d" $tgt_script

sed -i "s/<JOBID>/ts/" $tgt_script
sed -i "s/<Y1>//" $tgt_script
sed -i "s|<OUT>|$OUT|" $tgt_script

echo ../timeseries/timeseries.sh $1 $ALT_RUNDIR >> $tgt_script

echo ${submit_cmd} $tgt_script
#qstat -wu $USER

#echo; echo "*II* Launched timeseries analysis for experiment $1 of user $USERexp"; echo
