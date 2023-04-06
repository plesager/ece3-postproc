#!/bin/bash

set -ue

usage()
{
    cat << EOT >&2
  Usage: ts.sh [-a account] [-d dependency] [-u userexp] [-r POSTDIR] [-c] [-w] EXP

  Submit to a job scheduler the computation of timeseries for experiment EXP

  This is basically a wrapper around the timeseries.sh script.

  Options are:
     -l          : local (run on the local node, do not submit to compute node)
     -c          : check if processing was successful
     -a account  : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT:-unknown})
     -d depend   : add dependency between this job and other jobs
     -r POSTDIR  : overwrite ECE3_POSTPROC_POSTDIR
     -u USERexp  : alternative 'user' owner of the experiment, overwrite USERexp token
     -w          : create plots and Webpages to display them

     ECE3_POSTPROC_POSTDIR and USERexp default values should be set in
     your conf_timeseries_$ECE3_POSTPROC_MACHINE.sh file
EOT
}

# -- default option
account="${ECE3_POSTPROC_ACCOUNT-}"
dependency=
ALT_RUNDIR=
checkit=0
nosub=0
options=
web=0

while getopts "h?clu:r:a:d:w" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        d)  dependency=$OPTARG
            ;;
        l)  nosub=1
            ;;
        r)  options="${options} -r $OPTARG"
            ALT_RUNDIR=$OPTARG
            ;;
        u)  options="${options} -u $OPTARG"
            USERexp=$OPTARG
            ;;
        w)  options="${options} -w"
            web=1
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
[[ -z $dependency ]] && [[ ! -d $INDATA ]] && echo "*EE* Experiment HiresClim2 output dir $INDATA does not exist!" && exit 1


# -- check previously computed TS

if (( checkit ))
then
    diagdir=$(eval echo ${ECE3_POSTPROC_DIAGDIR})
    set +e

    printf "\n\tchecking TimeSeries results for Atmosphere:\n"
    ls -lt ${diagdir}/timeseries/${EXPID}/atmosphere/${EXPID}_????_????_time-series_atmo.nc
    (( web )) && ls -lt ${diagdir}/timeseries/${EXPID}/atmosphere/index.html \
            || echo "no plots-and-html-page were generated for atmosphere"

    printf "\n\tchecking TimeSeries results for Ocean:\n"
    ls -lt ${diagdir}/timeseries/${EXPID}/ocean/${EXPID}_????_????_time-series_ocean.nc
    (( web )) && ls -lt ${diagdir}/timeseries/${EXPID}/ocean/index.html \
            || echo "no plots-and-html-page were generated for ocean"

    printf "\n\tLog file: $OUT/log/ts_${EXPID}_.out"
    #printf "\n\tDo you want to check this log w/ less? "
    #read -n 1 answer
    #[[ $answer == "y" ]] || [[ $answer == "Y" ]] && less $OUT/log/ts_${EXPID}_.out

    set -e
    exit
fi


# -- submit script or execute on the login node

if (( nosub ))
then
    ../timeseries/timeseries.sh ${options} $1
else
    tgt_script=$OUT/ts_$1.job

    sed "s/<EXPID>/$1/" < ${CONFDIR}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script

    [[ -n $account ]] && \
        sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
        sed -i "/<ACCOUNT>/ d" $tgt_script

    [[ -n $dependency ]] && \
        sed -i "s/<DEPENDENCY>/$dependency/" $tgt_script || \
        sed -i "/<DEPENDENCY>/ d" $tgt_script

    sed -i "s/<JOBID>/ts/" $tgt_script
    sed -i "s/<Y1>//" $tgt_script
    sed -i "s|<OUT>|$OUT|" $tgt_script

    echo ../timeseries/timeseries.sh ${options} $1 >> $tgt_script
    
    ${submit_cmd} $tgt_script
fi
