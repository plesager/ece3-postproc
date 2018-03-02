#!/usr/bin/env bash

usage()
{
   echo "Usage:"
   echo "       hc.sh [-a account] [-u USERexp] [-m months_per_leg] EXP"
   echo
   echo "Submit to a job scheduler an HIRESCLIM2 postprocessing of experiment EXP"
   echo " (started in YREF) from YEAR1 to YEAR2. For each year, the script makes a"
   echo " wrapper around master_hiresclim.sh, and submit it through the job scheduler."
   echo
   echo "Submitted scripts and logs are in $SCRATCH/tmp_ecearth3"
   echo
   echo "Options are:"
   echo "   -a ACCOUNT  : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT:-unknown})"
   echo "   -u USERexp  : alternative user owner of the experiment, default $USER"
   echo "   -m months_per_leg : run was performed with months_per_leg legs (yearly legs expected by default)"
   echo "   -n numprocs       : set number of processors to use (default is 12)"
}

set -ue

# -- default options
account="${ECE3_POSTPROC_ACCOUNT-}"
options=""
nprocs=12
yref=""

# -- options
while getopts "hu:a:m:n:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        n)  nprocs=$OPTARG
            ;;
        m)  options=${options}" -m $OPTARG"
            ;;
        u)  USERexp=$OPTARG
            ;;
        a)  account=$OPTARG
            ;;
        *)  usage
            exit 1
    esac
done
shift $((OPTIND-1))

if [ $# -ne 1 ]; then
   usage
   exit 1
fi

EXPID=$1

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# -- get submit command
CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}

. ${CONFDIR}/conf_hiresclim_${ECE3_POSTPROC_MACHINE}.sh

# -- add here options for submit commands
case "${submit_cmd}" in
        sbatch) queue_cmd="squeue -u $USER  -o %.16j" ;;
esac

# -- Find first and last year
year="*"
YEAR_LAST=$( basename $(eval echo $IFSRESULTS0/ICMSH${EXPID}+????12 | rev | cut -f1 -d" " | rev) | cut -c11-14)
YEAR_ZERO=$( basename $(eval echo $IFSRESULTS0/ICMSH${EXPID}+????12 | cut -f1 -d" ") | cut -c11-14)

# -- exit if no years are found
if [[ ${YEAR_ZERO} == "????" ]] || [[ ${YEAR_ZERO} == "????" ]] ; then 
   echo "Experiment $EXPID not found in $IFSRESULTS0! Exiting!"
   exit
fi

# -- on which years are we running
echo "First year is ${YEAR_ZERO}"
echo "Last year is ${YEAR_LAST}"

# -- take yref from YEAR_ZERO (potentially can be used by other file structures)
yref=${YEAR_ZERO}

# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT/log

#YEAR_LAST=1995

# -- Write and submit one script per year
for YEAR in $(seq ${YEAR_ZERO} ${YEAR_LAST})
do 
    echo; echo ---- $YEAR -----
    # -- If postcheck exists plot it, then exit! 
    if [ -f  $(eval echo ${ECE3_POSTPROC_POSTDIR})/postcheck_${EXPID}_$YEAR.txt ] 
    then
	cat $(eval echo ${ECE3_POSTPROC_POSTDIR})/postcheck_${EXPID}_$YEAR.txt
    else
	# -- check if postproc is already, the exit
	ll=$(echo $(${queue_cmd} | grep "hc_${EXPID}_${YEAR}"))
	if [[ ! -z $ll ]] ; then
            echo "Hiresclim postprocessing for year $YEAR already going on..."
            continue
        fi
	
	# -- if files are missing, run master_hiresclim.sh fo each year
	tgt_script=$OUT/hc_${EXPID}_${YEAR}.job
        sed "s/<EXPID>/$1/" < ${CONFDIR}/hc_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script

        [[ -n $account ]] && \
        sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
        sed -i "/<ACCOUNT>/ d" $tgt_script

        # -- number of processors to use, default 12
        sed -i "s/<NPROCS>/$nprocs/" $tgt_script

        sed -i "s/<YEAR>/$YEAR/" $tgt_script
        sed -i "s|<YREF>|$yref|" $tgt_script
        sed -i "s|<OUT>|$OUT|" $tgt_script
        sed -i "s|<OPTIONS>|${options}|" $tgt_script
	echo "Submitting for year $YEAR"
        ${submit_cmd} $tgt_script
    fi
done
