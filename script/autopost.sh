#!/bin/bash

###########################
# AUTOPOSTPROC 
###########################
# JvH 2017, based on original script by P. Davini ISAC-CNR 2015

#set -ex

usage()
{
   echo "Usage: autopost.sh [-a account] [-u user]  exp "
   echo "Run hiresclim autopostprocessing of experiment exp for a specific user (optional)"
   echo "Determines automatically which years need to be postprocessed"
   echo "Options are:"
   echo "-a account    : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT-})"
   echo "   -r RUNDIR   : fully qualified path to another user EC-Earth top RUNDIR"
   echo "                   that is RUNDIR/EXP/output must exists and be readable"
   echo "-p            : filter PRIMAVERA output"
   echo "-n nemoconf            : postprocess NEMO too, e.g. nemoconf=ORCA1L75"
}

. $HOME/ecearth3/post/conf/conf_users.sh

lprimavera=0

## Specifically for switching on or off the analysis of NEMO results: commented following line = switch OFF nemo; otherwise switch ON nemo
#nemores=""  #PAOLO: ARE WE SURE WE NEED THIS?

while getopts "h?r:a:p:" opt; do
    case "$opt" in
    h)
        usage
        exit 0
        ;;
    a)  account=$OPTARG
        ;;
    r)  options=${options}" -r $OPTARG"
        ALT_RUNDIR="$OPTARG"
        ;;
    p)  lprimavera=1
        ;;
    *)  usage
        exit 1
    esac
done
shift $((OPTIND-1))

if [ "$#" -lt 1 ]; then
   usage
   exit 0
fi


# -- Sanity checks (from master_hiresclim.sh, repeated here for a "before submission" error catch)
[[ -z "${ECE3_POSTPROC_TOPDIR:-}"  ]] && echo "User environment not set. See ../README." && exit 1
[[ -z "${ECE3_POSTPROC_RUNDIR:-}"  ]] && echo "User environment not set. See ../README." && exit 1
[[ -z "${ECE3_POSTPROC_MACHINE:-}" ]] && echo "User environment not set. See ../README." && exit 1

# -- get submit command
CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}

. ${CONFDIR}/conf_hiresclim_${ECE3_POSTPROC_MACHINE}.sh

# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT/log


escape=0

# directories where raw outputs are stored
OUTPUTDIR=$BASERESULTS

echo outputdir is $OUTPUTDIR

# check if postproc is already going on
squeue -u $USERme > $OUT/joblist.txt
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

echo $YEAR_ZERO
echo $YEAR_LAST

echo
#years to postproc: check from postcheck.txt
mkdir -p $STOREDIR
filelist=$(ls -A $STOREDIR/postcheck_*)

# if no stored checkfiles are found, start from the beginnning 
if [ $? != 0 ] || [ -z "$filelist" ] ; then
	YEAR_POST="NA"
        YEAR1=${YEAR_ZERO}
else
	YEAR_POST=$( ls $STOREDIR/postcheck_* -r | head -1 | cut -f4 -d "_" | cut -c1-4 ) #last year of successful postproc
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

	#evaluate the time needed for 10y according to the resolution (min)
	case ${IFS_GRID} in
        T159L91)    mm=20   ; IFS_PROCS=12 ;  THREADS=1 ; MEM=12GB ;;
    	T255L91)    mm=25   ; IFS_PROCS=12 ;  THREADS=12 ; MEM=12GB ;;
    	T511L91)    mm=60   ; IFS_PROCS=12  ; THREADS=12 ; MEM=24GB ;;
    	T799L91)    mm=90   ; IFS_PROCS=12  ; THREADS=12 ; MEM=48GB ;;
    	T1279L91)   mm=120  ; IFS_PROCS=12 ;  THREADS=12 ; MEM=105GB ;;
	esac

	#nemo postproc can be time consuming: add minutes 
        NEMO_PROCS=12;
	if [ ! -z "$nemores" ] ; then
		case $nemores in 
		ORCA1L75) 	mm=$((mm+20)) ;;
		ORCA025L75)	mm=$((mm+60)) ;;
		esac
	fi
		
	echo $nemores $mm
	
	#compute the postproc according to the max amount of time needed	
	maxyears=$( echo "scale=0; $JOBMAXHOURS*60./$mm" | bc      )
	nyears=$(( $YEAR2 - $YEAR1 + 1 ))
	if [ $nyears -gt $maxyears ] ; then
		nyears=$maxyears
	fi

        # preparing the script and the needed time
	tottime=$(  echo "scale=0; $nyears*$mm/60." | bc ) #number of years * time for one year
	tottimem=$(  echo "scale=0; $nyears*$mm-$tottime*60." | bc ) #number of years * time for one year
        TOTTIME=$( echo $( printf "%02d:%02d:00" $tottime $tottimem ) )
	YEAR2=$(( $YEAR1 + $nyears - 1 ))
        sed "s/<EXPID>/$expname/" < $CONFDIR/$MACHINE/header.tmpl > $OUT/autopost.job
        sed -i "s/<ACCOUNT>/$account/" $OUT/autopost.job
        sed -i "s/<TOTTIME>/$TOTTIME/"  $OUT/autopost.job
        sed -i "s/<MEM>/$MEM/"  $OUT/autopost.job
	sed -i "s/<THREADS>/$THREADS/" $OUT/autopost.job
        sed -i "s/<JOBID>/ap/" $OUT/autopost.job
	sed -i "s/<IFS_PROCS>/$IFS_PROCS/"  $OUT/autopost.job
	sed -i "s/<NEMO_PROCS>/$NEMO_PROCS/"  $OUT/autopost.job
        sed -i "s/<USERme>/$USERme/" $OUT/autopost.job
        sed -i "s/<USERexp>/$USERexp/" $OUT/autopost.job

	if [[ $lprimavera == 0 ]]; then
cat << EOF >>  $OUT/autopost.job
    	 unset FILTERGG2D
     	 unset FILTERGG3D
   	 unset FILTERSH
EOF
	fi
	echo ./master_hiresclim.sh $expname $YEAR1 $YEAR2 $USERexp $nemores >>  $OUT/autopost.job

        echo "lprimavera is $lprimavera"

	echo "--- WRITING THE JOB ---"
        echo "Experiment" $expname
	echo "Resolution" ${IFS_GRID}
        echo "HiResclim postprocessing starting at year" $YEAR1
	echo "HiResclim postprocessing ending at year" $YEAR2
        echo "Running for" $TOTTIME "hours"
	
        sbatch $OUT/autopost.job
        squeue -u $USERme

fi

#clean 
rm $OUT/joblist.txt
echo
exit

