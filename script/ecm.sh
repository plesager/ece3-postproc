#!/bin/bash

usage()
{
   echo "Usage: ecm.sh [-a account] [-r rundir] [-c] [-p] [-y] EXP YEAR1 YEAR2"
   echo
   echo "Submit to a job scheduler an EC-MEAN analysis of experiment EXP in years"
   echo " YEAR1 to YEAR2."
   echo
   echo "This is basically a wrapper around the EC-mean.sh script, which "
   echo "computes global flux averages."
   echo 
   echo "Options are:"
   echo "   -c          : check if processing was successful"
   echo "   -a account  : specify a different special project for accounting (default $ECE3_POSTPROC_ACCOUNT)"
   echo "   -r RUNDIR   : fully qualified path to another user EC-Earth top RUNDIR"
   echo "                   that is RUNDIR/EXP/post must exists and be readable"
   echo "   -y          : (Y)early global mean are added to "
   echo "   -p          : account for (P)rimavera complicated output"
}

set -ue

# -- default option
account=$ECE3_POSTPROC_ACCOUNT
ALT_RUNDIR=""
checkit=0
options=""

while getopts "hcr:a:py" opt; do
    case "$opt" in
        h)  usage
            exit 0
            ;;
        r)  options="${options} -r $OPTARG"
            ALT_RUNDIR=$OPTARG
            ;;
        p)  options="${options} -p"
            ;;
        y)  options="${options} -y"
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

if [ "$#" -lt 3 ]; then
    echo; echo "*EE* missing arguments"; echo
    usage 
    exit 1
fi

# check that we have a 4-digit number for the year input
if [[ ! $2 =~ ^[0-9]{4}$ ]]
then
    echo ;echo "*EE* argument YEAR1 (=$2) should be a 4-digit integer"; echo
    usage
    exit 1
fi
if [[ ! $3 =~ ^[0-9]{4}$ ]]
then
    echo; echo "*EE* argument YEAR2 (=$3) should be a 4-digit integer"; echo
    usage
    exit 1
fi

# check we have a 4-letter experiment
if [[ ! $1 =~ ^[a-Z0-9_]{4}$ ]]
then
    echo; echo "*EE* argument EXP (=$1) should be a 4-letter string"; echo
    usage
    exit 1
fi

# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT/log

CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}

# -- get OUTDIR, submit command
. ${CONFDIR}/conf_ecmean_${ECE3_POSTPROC_MACHINE}.sh


# -- check input dir exist (from EC-mean.sh, repeated here for a "before submission" error catch)
if [[ -n $ALT_RUNDIR ]]
then
    outdir=$ALT_RUNDIR/$1/post/mon/
else
    outdir="${ECE3_POSTPROC_RUNDIR}/$1/post/mon/"
fi
[[ ! -d $outdir ]] && echo "*EE* Experiment HiresClim2 output dir $outdir does not exist!" && exit 1


# -- check previous processing
if (( checkit ))
then
    echo; echo "Checking ${OUTDIR}/globtable.txt ..."
    grep $1.$2-$3. ${OUTDIR}/globtable.txt || \
        echo "*EE* check log at $SCRATCH/tmp_ecearth3"
    grep $1.$2-$3. ${OUTDIR}/gregory.txt || true
    exit
fi


# -- submit script
tgt_script=$OUT/ecm_$1_$2_$3.job

sed "s/<EXPID>/$1/" < ${CONFDIR}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script

[[ -n $account ]] && \
    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
    sed -i "/<ACCOUNT>/ d" $tgt_script

sed -i "s/<JOBID>/ecm/" $tgt_script
sed -i "s/<Y1>/$2/" $tgt_script
sed -i "s|<OUT>|$OUT|" $tgt_script

echo ../ECmean/EC-mean.sh ${options} $1 $2 $3 >> $tgt_script

${submit_cmd} $tgt_script


