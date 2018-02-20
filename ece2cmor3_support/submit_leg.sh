#!/bin/bash
#
#
#
###############################################################################
#
# Filter and CMORize one leg of EC-Earth output: uses CMIP6 tables only.
# Legs are assumed to be 1 year in length.
# This script submits 12 jobs, each filtering/cmorizing one month of data.
#
#
# If MON>0, then it will only process the specified month of the given year
# (and consequently will only submit a single job).
#
# Note that for NEMO processing, all files in the output folder will be
# processed irrespective of the MON variable, so this is only useful for IFS.
#
# ATM=1 means process IFS data.
# OCE=1 means process NEMO data (default is 0).
#
# Other choices of output (output/tmp dirs etc.) are set in cmor_mon.sh.
#
#
# KJS (Jan 2018) - based on a script by Gijs van Oord
#
################################################################################


set -u
set -e


# Required arguments

EXP=${EXP:-qsh0}
LEG=${LEG:-000}
STARTYEAR=${STARTYEAR:-1950}
MON=${MON:-0}
ATM=${ATM:-0}
OCE=${OCE:-1}
USERNAME=${USERNAME:-pdavini0}
USEREXP=imavilia  #extra by P. davini: allows analysis of experiment owned by different user
VERBOSE=${VERBOSE:-0}


OPTIND=1
while getopts ":h:e:l:s:m:v:" OPT; do
    case "$OPT" in
    h|\?) echo "Usage: submit_leg.sh -e <experiment name> -l <leg nr> -s <start year> -m <month (optional: 1-12) \
                -a <atmosphere only (0,1): default is 1> -o <ocean only (0,1): default is 0> -u <Marconi username> (-v verbose)"
          exit 0 ;;
    e)    EXP=$OPTARG ;;
    l)    LEG=$OPTARG ;;
    s)    STARTYEAR=$OPTARG ;;
    m)    MON=$OPTARG ;;
    a)    ATM=$OPTARG ;;
    o)    OCE=$OPTARG ;;
    u)    USERNAME=$OPTARG ;;
    v)    VERBOSE=1 ;;
    esac
done
shift $((OPTIND-1))




# Determining year and months
YEAR=$(( STARTYEAR + $((10#$LEG + 1)) - 1))
MONMIN=1
MONMAX=12
if (( MON > 0 )); then
    MONMIN=$MON
    MONMAX=$MON
fi

# define folder for logfile
LOGFILE=/marconi_scratch/userexternal/$USERNAME/log/cmorize
mkdir -p $LOGFILE || exit 1

# The actual submission (via slurm)
echo "========================================================="
echo "Processing and CMORizing leg ${LEG} of experiment ${EXP}"
echo "Startyear for this experiment = ${STARTYEAR}"
echo "Year corresponding to this leg = ${YEAR}"
echo "Log file will be in = $LOGFILE" 



if (( MON > 0 )); then
    echo "Only processing month ${MON}"
fi

if [ "$ATM" -eq 1 ]; then
    echo "IFS processing: yes"
else
    echo "IFS processing: no"
fi

if [ "$OCE" -eq 1 ]; then
    echo "NEMO processing: yes"
else
    echo "NEMO processing: no"
fi

if [ "$ATM" -eq 0 ] && [ "$OCE" -eq 0 ]; then
    echo "Error: ATM and OCE arguments cannot both be 0!" >&2; exit 1
fi



SUBMIT="sbatch"
SLURMOPT_ATM="EXP=$EXP,LEG=$LEG,STARTYEAR=$STARTYEAR,ATM=$ATM,OCE=0,VERBOSE=$VERBOSE,USERNAME=$USERNAME,USEREXP=$USEREXP"
echo SLURMOPT_ATM=${SLURMOPT_ATM}

echo "Submitting jobs via Slurm..."

if [ "$ATM" -eq 1 ] ; then

# For IFS we submit one job for each month
#for MON in $(seq $MONMIN $MONMAX); do
for MON in 1 ; do
    SUBOPT="$SLURMOPT_ATM,MON=$MON"
    JOBID=$($SUBMIT --job-name=proc_ifs-${YEAR}-${MON} --output=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.err --export=$SUBOPT ./cmor_mon.sh)
done

fi


# Because NEMO output files corresponding to same leg are all in one big file, we don't
# need to submit a job for each month, only one for each leg
if [ "$OCE" -eq 1 ]; then
    SLURMOPT_OCE="EXP=$EXP,LEG=$LEG,STARTYEAR=$STARTYEAR,ATM=0,OCE=$OCE,VERBOSE=$VERBOSE,USERNAME=$USERNAME,USEREXP=$USEREXP"
    echo SLURMOPT_OCE=${SLURMOPT_OCE}
    JOBID=$($SUBMIT --job-name=proc_nemo-${YEAR}-${MON} --output=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_nemo_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_nemo_%j.err --export=$SLURMOPT_OCE ./cmor_mon.sh)
fi



echo "Jobs submitted!"
echo "========================================================="


# End of script
exit 0



