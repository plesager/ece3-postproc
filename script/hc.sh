#!/usr/bin/env bash

usage()
{
   echo "Usage:"
   echo "       hc.sh [-c] [-a account] [-u userexp] [-m months_per_leg] EXP YEAR1 YEAR2 YREF"
   echo
   echo "Submit to a job scheduler an HIRESCLIM2 postprocessing of experiment EXP"
   echo " (started in YREF) from YEAR1 to YEAR2. For each year, the script makes a"
   echo " wrapper around master_hiresclim.sh, and submit it through the job scheduler."
   echo
   echo "Submitted scripts and logs are in $SCRATCH/tmp_ecearth3"
   echo
   echo "Options are:"
   echo "   -a ACCOUNT  : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT:-unknown})"
   echo "   -c          : check for success"
   echo "   -6          : use if EC-Earth run with CMIP6 ctrl output (requires implementation in your config file - see cca example)" 
   echo "   -u USERexp  : alternative user owner of the experiment, default $USER"
   echo "   -m months_per_leg : run was performed with months_per_leg legs (yearly legs expected by default)"
   echo "   -n numprocs       : set number of processors to use (default is 12)"
}

set -ue

# -- default options
account="${ECE3_POSTPROC_ACCOUNT-}"
checkit=0
options=""
nprocs=12

# -- options
while getopts "hc6u:a:m:n:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        n)  nprocs=$OPTARG
            ;;
        m)  options=${options}" -m $OPTARG"
            ;;
        u)  options=${options}" -u $OPTARG"
            ;;
        6)  options=${options}" -6"
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

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# -- get submit command
CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}

. ${CONFDIR}/conf_hiresclim_${ECE3_POSTPROC_MACHINE}.sh


# -- check previous processing
if (( checkit ))
then
    EXPID=$1                    # set variables which can be eval'd    
    for YEAR in $(eval echo {$2..$3})
    do 
        echo; echo "-- check $YEAR--"; echo
        cat $(eval echo ${ECE3_POSTPROC_POSTDIR})/postcheck_$1_$YEAR.txt || \
            echo "*EE* check log at $SCRATCH/tmp_ecearth3"
    done
    exit
fi


# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT/log

# -- Write and submit one script per year
for YEAR in $(eval echo {$2..$3})
do 
    tgt_script=$OUT/hc_$1_$YEAR.job
    sed "s/<EXPID>/$1/" < ${CONFDIR}/hc_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script

    [[ -n $account ]] && \
        sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
        sed -i "/<ACCOUNT>/ d" $tgt_script

    # -- number of processors to use, default 12
    sed -i "s/<NPROCS>/$nprocs/" $tgt_script

    sed -i "s/<YEAR>/$YEAR/" $tgt_script
    sed -i "s|<YREF>|$4|" $tgt_script
    sed -i "s|<OUT>|$OUT|" $tgt_script
    sed -i "s|<OPTIONS>|${options}|" $tgt_script
    ${submit_cmd} $tgt_script
    
    # -- book keeping (experimental: eventually should not be on $SCRATCH)
    echo $YEAR >> $OUT/log/submitted_hc_$1
done
