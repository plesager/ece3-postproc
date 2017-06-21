#!/bin/bash

usage()
{
   echo "Usage: ts.sh [-a account] [-u user] exp [user]"
   echo "Compute timeseries for experiment exp of user (optional)"
   echo "Options are:"
   echo "-a account    : specify a different special project for accounting (default: spnltune)"
   echo "-u user       : analyse experiment of a different user (default: yourself)"
}

. $ECE3_POSTPROC_TOPDIR/post/conf/conf_users.sh


while getopts "h?u:a:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    u)  USERexp=$OPTARG
        ;;
    a)  account=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))

OUT=$SCRATCH/tmp
mkdir -p $OUT

if [ "$#" -lt 1 ]; then
   usage 
   exit 0
fi
if [ "$#" -eq 2 ]; then
   USERexp=$2
fi

echo "Launched timeseries analysis for experiment $1 of user $USERexp"

#sed -i "s/<USERexp>/$USERexp/" $OUT/header.job
sed "s/<EXPID>/$1/" < $SCRIPTDIR/header_$MACHINE.tmpl > $OUT/ts.job
sed -i "s/<ACCOUNT>/$ACCOUNT/" $OUT/ts.job
sed -i "s/<USERme>/$USERme/" $OUT/ts.job
sed -i "s/<JOBID>/ts/" $OUT/ts.job
echo ./timeseries.sh $1 $USERexp >> $OUT/ts.job

qsub $OUT/ts.job
qstat -u $USERme
