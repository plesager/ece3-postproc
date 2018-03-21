#!/bin/bash

set -ue

usage()
{
    echo "Usage: ts.sh [-a account] [-u userexp] [-r POSTDIR] [-c] EXP"
    echo
    echo "Submit to a job scheduler the computation of timeseries for experiment EXP"
    echo
    echo "This is basically a wrapper around the timeseries.sh script."
    echo 
    echo "Options are:"
    echo "   -c          : check if processing was successful"
    echo "   -a account  : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT:-unknown})"
    echo "   -r POSTDIR  : overwrite ECE3_POSTPROC_POSTDIR "
    echo "   -u USERexp  : alternative 'user' owner of the experiment, default to $USER"
    echo "                  overwrite USERexp token."
    echo
    echo "   ECE3_POSTPROC_POSTDIR and USERexp default values should be set in"
    echo "   your conf_timeseries_$ECE3_POSTPROC_MACHINE.sh file"
}

# -- default option
account="${ECE3_POSTPROC_ACCOUNT-}"
ALT_RUNDIR=
checkit=0
options=

while getopts "h?cu:r:a:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        r)  options="${options} -r $OPTARG"
            ALT_RUNDIR=$OPTARG
            ;;
        u)  options="${options} -u $OPTARG"
            USERexp=$OPTARG
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


# -- Check that base directory of HiresClim2 postprocessing output exists (repeated here for a "before submission" error catch)
if [[ -n $ALT_RUNDIR ]]
then
    INDATA=`eval echo ${ALT_RUNDIR}`/mon
else
    INDATA=`eval echo ${ECE3_POSTPROC_POSTDIR}`/mon
fi
[[ ! -d $INDATA ]] && echo "*EE* Experiment HiresClim2 output dir $INDATA does not exist!" && exit 1


# -- check previously computed TS

if (( checkit ))
then
    diagdir=$(eval echo ${ECE3_POSTPROC_DIAGDIR})
    set +e

    printf "\n\tchecking TimeSeries results for Atmosphere:\n"
    ls -lt ${diagdir}/timeseries/${EXPID}/atmosphere/${EXPID}_????_????_time-series_atmo.nc
    ls -lt ${diagdir}/timeseries/${EXPID}/atmosphere/index.html

    printf "\n\tchecking TimeSeries results for Ocean:\n"
    ls -lt ${diagdir}/timeseries/${EXPID}/ocean/${EXPID}_????_????_time-series_ocean.nc
    ls -lt ${diagdir}/timeseries/${EXPID}/ocean/index.html

    printf "\n\tLog file: $OUT/log/ts_${EXPID}_.out"
    printf "\n\tDo you want to check this log w/ less? "
    read -n 1 answer
    [[ $answer == "y" ]] || [[ $answer == "Y" ]] && less $OUT/log/ts_${EXPID}_.out

    set -e
    exit
fi


# -- submit script
tgt_script=$OUT/ts_$1.job

sed "s/<EXPID>/$1/" < ${CONFDIR}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script

[[ -n $account ]] && \
    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
    sed -i "/<ACCOUNT>/ d" $tgt_script

sed -i "s/<JOBID>/ts/" $tgt_script
sed -i "s/<Y1>//" $tgt_script
sed -i "s|<OUT>|$OUT|" $tgt_script

echo ../timeseries/timeseries.sh ${options} $1 >> $tgt_script

${submit_cmd} $tgt_script

