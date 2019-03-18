#!/bin/bash


usage()
{
   echo "Usage: postall.sh [-u user] [-a account] [-r resolution] exp year1 year2 [user]"
   echo "Do AMWG analysis of experiment exp in years year1 to year2 for a specific user (optional) and resolution,"
   echo "where resolution is N128, N256 etc. (N128=default)"
   echo "Options are:"
   echo "-a account    : specify a different special project for accounting (default: spnltune)"
   echo "-u user       : analyse experiment of a different user (default: yourself)"
   echo "-u resolution : resolution (default: N128)"
}

. $ECE3_POSTPROC_TOPDIR/post/conf/conf_users.sh

res=N128

while getopts "h?u:a:r:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    u)  USERexp=$OPTARG
        ;;
    a)  account=$OPTARG
        ;;
    r)  res=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -lt 3 ]; then
    usage
    exit 0
fi

if [ "$#" -ge 4 ]; then
   USERexp=$4
fi

sed "s/<EXPID>/$1/" < $SCRIPTDIR/header_$MACHINE.tmpl > $OUT/postall.job
sed -i "s/<USERme>/$USERme/" $OUT/postall.job

[[ -n $account ]] && \
    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
    sed -i "/<ACCOUNT>/ d" $tgt_script

[[ -n $dependency ]] && \
    sed -i "s/<DEPENDENCY>/$dependency/" $tgt_script || \
    sed -i "/<DEPENDENCY>/ d" $tgt_script

sed -i "s/<JOBID>/postall/" $OUT/postall.job

echo echo Running EC-Mean >>  $OUT/postall.job
echo ./EC-mean.sh $1 $2 $3 $USERexp >>  $OUT/postall.job
echo echo Running timeseries >>  $OUT/postall.job
echo ./timeseries.sh $1 $USERexp >> $OUT/postall.job
echo echo Running AMWG >>  $OUT/postall.job
echo ./amwg_modobs.sh $1 $2 $3 $USERexp $res >> $OUT/postall.job

qsub $OUT/postall.job
qstat -u $USERme
