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

set -e

# -- default option
account=$ECE3_POSTPROC_ACCOUNT

while getopts "h?cr:a:py" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        r)  ALT_RUNDIR=$OPTARG
            ;;
        p)  theoptions="${theoptions} -p"
            ;;
        y)  theoptions="${theoptions} -y"
            ;;
        c)  checkit=1
            ;;
        a)  account=$OPTARG
            ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -lt 3 ]; then
   usage 
   exit 0
fi

# check that we have number where expected #TODO


# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT/log


# -- get OUTDIR, submit command
. $ECE3_POSTPROC_TOPDIR/conf/conf_ecmean_${ECE3_POSTPROC_MACHINE}.sh


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

sed "s/<EXPID>/$1/" < $ECE3_POSTPROC_TOPDIR/script/platform/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script

[[ -n $account ]] && \
    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
    sed -i "/<ACCOUNT>/ d" $tgt_script

sed -i "s/<JOBID>/ecm/" $tgt_script
sed -i "s/<Y1>/$2/" $tgt_script
sed -i "s|<OUT>|$OUT|" $tgt_script

echo ./EC-mean.sh ${theoptions} $1 $2 $3 $ALT_RUNDIR >> $tgt_script

${submit_cmd} $tgt_script


