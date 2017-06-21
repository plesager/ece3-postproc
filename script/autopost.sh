#!/bin/bash

###########################
# AUTOPOSTPROC 
###########################
# Based on original script by P. Davini ISAC-CNR

#set -ex

usage()
{
    echo "Usage: autopost.sh [-a account] [-u user] exp [user]"
    echo "Run hiresclim autopostprocessing of experiment exp for a specific user (optional)"
    echo "Determines automatically which years need to be postprocessed"
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

if [ "$#" -lt 1 ]; then
    usage
    exit 0
fi

if [ "$#" -ge 2 ]; then
    USERexp=$4
fi

OUT=$SCRATCH/tmp
mkdir -p $OUT

expname=$1

. $CONFDIR/conf_hiresclim_${ECE3_POSTPROC_MACHINE}.sh

escape=0

# directories where the postprocessed outputs will be stored
STOREDIR=$OUTDIR0
# directories where raw outputs are stored
OUTPUTDIR=$BASERESULTS


# check if postproc is already going on
qstat -u $USERme > $OUT/joblist.txt
ll=$( grep -r "ap_$expname" $OUT/joblist.txt  | cut -f 1 -d " " )
ll=${#ll}
if [ $ll != 0 ] ; then
    out_escape="Hiresclim postprocessing already going on, exiting..."
    escape=1
fi

outputfile=$(ls -r $OUTPUTDIR/Output_????/IFS/ICMSH????+????12)
if [ $? != 0 ] ; then echo "No complete year run for the moment, exiting..."; exit ; fi

# last year run
#YEAR_LAST=$( ls $OUTPUTDIR -r | head -1 | cut -c8-11 )
YEAR_LAST=$( basename $( ls -r $OUTPUTDIR/Output_????/IFS/ICMSH????+????12 | head  -1 ) | cut -c11-14 )
# first year run
#YEAR_ZERO=$( ls $OUTPUTDIR | head -1 | cut -c8-11 )
YEAR_ZERO=$( basename $( ls $OUTPUTDIR/Output_????/IFS/ICMSH????+????12 | head -1 ) | cut -c11-14 )

echo $YEAR_LAST
echo $YEAR_ZERO

echo
#years to postproc: check from postcheck.txt
mkdir -p $STOREDIR
filelist=$(ls -A $STOREDIR/postcheck_*)

# if no stored checkfiles are found, start from the beginnning 
if [ $? != 0 ] || [ -z "$filelist" ] ; then
    YEAR_POST="NA"
    YEAR1=${YEAR_ZERO}
else
    YEAR_POST=$( ls $STOREDIR/postcheck_* -r | head -1 | cut -f3 -d "_" | cut -c1-4 ) #last year of successful postproc
    YEAR1=$(( $YEAR_POST + 1 )) #first year to postproc
fi

#last year to postpoc
YEAR2=${YEAR_LAST}

hres=$(grep " NSMAX " $OUTPUTDIR/../log/Log_$YEAR1/ifs.log|cut -c11-15| xargs)
vres=$(grep "NFLEVG =" $OUTPUTDIR/../log/Log_$YEAR1/ifs.log|cut -c13-15| xargs)
IFS_GRID="T${hres}L${vres}"

# print some information
echo "----- INFOS -----"
echo "Experiment: $expname; Last year postprocessed: ${YEAR_POST}; Last year run ${YEAR_LAST}"
echo "First year to postproc: $YEAR1"
echo "Resolution is: ${IFS_GRID}"

#if postproc is updated
if [ $YEAR1 -gt $YEAR2 ]  ; then
    out_escape="$YEAR1 >= $YEAR2, Hiresclim has no years to postprocess, exiting..."
    escape=1
fi

#skipping or doing postproc
if [ $escape == 1 ] ; then
    echo "--- NOTHING TO DO ----"
    echo $out_escape
else

        #evaluate the time needed according to the resolution (hours)
    case ${IFS_GRID} in
        T159L91)    hh=2   ; IFS_PROCS=12 ;  JOBCLASS=nf ; THREADS=12 ;;
        T255L91)    hh=2   ; IFS_PROCS=12 ; JOBCLASS=nf ; THREADS=12 ;;
        T511L91)    hh=6   ; IFS_PROCS=12  ; JOBCLASS=nf ; THREADS=12 ;;
        T799L91)    hh=20  ; IFS_PROCS=6  ; JOBCLASS=nf ; THREADS=6 ;;
        T1279L91)   hh=30  ; IFS_PROCS=3 ; JOBCLASS=nf   ; THREADS=3 ;;
    esac
    NEMO_PROCS=12;
    
        #option for degrading resolution

        #compute the postproc according to the max amount of time needed        
    maxyears=$(( 48 / $hh ))
    nyears=$(( $YEAR2 - $YEAR1 + 1 ))
    if [ $nyears -gt $maxyears ] ; then
        nyears=$maxyears
    fi

        # preparing the script and the needed time
    tottime=$(( $nyears * $hh )) #number of years * time for one year
    TOTTIME=$( echo $( printf "%02d" $tottime):00 )
    YEAR2=$(( $YEAR1 + $nyears - 1 ))

    sed "s/<EXPID>/$expname/" < autopost.tmpl > $OUT/autopost.job
    sed -i "s/<ACCOUNT>/$account/" $OUT/autopost.job
    sed -i "s/<Y1>/$YEAR1/" $OUT/autopost.job
    sed -i "s/<Y2>/$YEAR2/" $OUT/autopost.job
    sed -i "s/<TOTTIME>/$TOTTIME/"  $OUT/autopost.job
    sed -i "s/<THREADS>/$THREADS/" $OUT/autopost.job
    sed -i "s/<JOBCLASS>/$JOBCLASS/" $OUT/autopost.job
    sed -i "s/<IFS_PROCS>/$IFS_PROCS/"  $OUT/autopost.job
    sed -i "s/<NEMO_PROCS>/$NEMO_PROCS/"  $OUT/autopost.job
    sed -i "s/<USERme>/$USERme/" $OUT/autopost.job
    sed -i "s/<USERexp>/$USERexp/" $OUT/autopost.job

    echo "--- WRITING THE JOB ---"
    echo "Experiment" $expname
    echo "Resolution" ${IFS_GRID}
    echo "HiResclim postprocessing starting at year" $YEAR1
    echo "HiResclim postprocessing ending at year" $YEAR2
    echo "Running for" $TOTTIME "hours"
    echo "Jobclass is " $JOBCLASS
    
    qsub $OUT/autopost.job
    qstat -u $USERme

fi

#clean 
rm $OUT/joblist.txt
echo
exit

