#!/usr/bin/env bash

usage()
{
   echo "Usage: "
   echo "  amwg.sh [-r RUNDIR] [-a ACCOUNT] EXP YEAR1 YEAR2"
   echo
   echo "Submit to a job scheduler an AMWG analysis of experiment EXP in years"
   echo " YEAR1 to YEAR2. This is basically a wrapper around the amwg_modobs.sh script."
   echo 
   echo "Options are:"
   echo "   -a account    : specify a different special project for HPC accounting (default \$ECE3_POSTPROC_ACCOUNT)"
   echo "   -r RUNDIR     : fully qualified path to another user EC-Earth top RUNDIR [NOT TESTED YET!]"
   echo "                   that is RUNDIR/EXP must exists and be readable"
}

set -e

# -- default option
account=$ECE3_POSTPROC_ACCOUNT

while getopts "h?a:r:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        r)  ALT_RUNDIR=$OPTARG
            ;;
        a)  account=$OPTARG
            ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 3 ]; then
   usage
   exit 1
fi

# -- Sanity check (from amwg_modobs.sh, repeated here for "before submission" error catch) 
[[ -z $ECE3_POSTPROC_TOPDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_RUNDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_DATADIR ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_MACHINE ]] && echo "User environment not set. See ../README." && exit 1 

# -- check options for amwg_modobs.sh
if [[ -n $ALT_RUNDIR ]]
then
    # test alternate dir (from amwg_modobs.sh, repeated here for "before submission" error catch) 
    outdir=$ALT_RUNDIR/$1/post
    [[ ! -d $outdir ]] && echo "User experiment output $outdir does not exist!" && exit1
    amwg_opt="-r $ALT_RUNDIR"
fi


# -- Scratch dir (logs end up there)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT

CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}


# -- submit script
tgt_script=$OUT/amwg_$1.job

sed "s/<EXPID>/$1/" < ${CONFIG}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script
[[ -n $account ]] && \
    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
    sed -i "/<ACCOUNT>/ d" $tgt_script
sed -i "s/<JOBID>/amwg/" $tgt_script
sed -i "s|<OUT>|$OUT|" $tgt_script

echo ./amwg_modobs.sh $amwg_opt $1 $2 $3 $res >>  $tgt_script

qsub $tgt_script
qstat -wu $USER
