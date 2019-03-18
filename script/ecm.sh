#!/bin/bash

usage()
{
   echo "Usage: ecm.sh [-a account] [-d dependency] [-r rundir] [-u USERexp] [-c] [-p] [-y] EXP YEAR1 YEAR2"
   echo
   echo "Submit to a job scheduler an EC-MEAN analysis of experiment EXP in years"
   echo " YEAR1 to YEAR2."
   echo
   echo "This is basically a wrapper around the EC-mean.sh script, which "
   echo "computes global flux averages."
   echo 
   echo "Options are:"
   echo "   -c          : check if processing was successful"
   echo "   -a account  : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT-unknown})"
   echo "   -d depend   : add dependency between this job and other jobs"
   echo "   -r RUNDIR   : fully qualified path to HIRESCLIM2 ouput (default: \${ECE3_POSTPROC_POSTDIR}/mon)"
   echo "   -u USERexp  : alternative 'user' owner of the experiment"
   echo "   -y          : (Y)early global mean are added to \$OUTDIR/yearly_fldmean_\${EXP}.txt"
   echo "   -p          : (P)rimavera specific treatment to select pressure levels"
   echo
   echo "   ECE3_POSTPROC_POSTDIR and USERexp default values should be set in"
   echo "   your conf_timeseries_$ECE3_POSTPROC_MACHINE.sh file"
}

set -ue

# -- default option
account=${ECE3_POSTPROC_ACCOUNT-}
dependency=
ALT_RUNDIR=""
checkit=0
options=""

while getopts "hcr:u:a:py" opt; do
    case "$opt" in
        h)  usage
            exit 0
            ;;
        d)  dependency=$OPTARG
            ;;
        r)  options="${options} -r $OPTARG"
            ALT_RUNDIR=$OPTARG
            ;;
        u)  options="${options} -u $OPTARG"
            USERexp=$OPTARG
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
if [[ ! $1 =~ ^[a-zA-Z0-9_]{4}$ ]]
then
    echo; echo "*EE* argument EXP (=$1) should be a 4-letter string"; echo
    usage
    exit 1
fi

# set variables which can be eval'd
EXPID=$1

# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT/log

CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}

# -- get OUTDIR, submit command
. ${CONFDIR}/conf_ecmean_${ECE3_POSTPROC_MACHINE}.sh

OUTDIR=$(eval echo ${ECE3_POSTPROC_DIAGDIR}/table)

# -- check input dir exist (from EC-mean.sh, repeated here for a "before submission" error catch)
if [[ -n $ALT_RUNDIR ]]
then
    outdir=$ALT_RUNDIR/mon
else
    outdir=$(eval echo ${ECE3_POSTPROC_POSTDIR})/mon
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

[[ -n $dependency ]] && \
    sed -i "s/<DEPENDENCY>/$dependency/" $tgt_script || \
    sed -i "/<DEPENDENCY>/ d" $tgt_script

sed -i "s/<JOBID>/ecm/" $tgt_script
sed -i "s/<Y1>/$2/" $tgt_script
sed -i "s|<OUT>|$OUT|" $tgt_script

echo ../ECmean/EC-mean.sh ${options} $1 $2 $3 >> $tgt_script

${submit_cmd} $tgt_script


