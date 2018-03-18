#/!bin/bash

# This script launches R programs to test the difference between two
# ensembles (defined by STEM) of experiments (defined by STEM + NB).
# It reads the following data produced by the EC-mean:
#
# --------------------------------------------------
# Location of EC-mean climatology sets for all runs
# --------------------------------------------------
#   For one run, ${stem}${nb}, data are expected in:
#   
#   $CLIMDIR/${stem}${nb}/post/clim-${year1}-${year2}/
#
# --------------------------------------------------
# location of R&K performance indices table
# --------------------------------------------------
#   For one ensemble, ${stem}, tables are expected in:
#
#   ${RK}/${stem}/
#
################## FOR NOW #############################
# we use RK=CLIMDIR, with CLIMDIR set thru the -d option
########################################################

set -o errexit

usage() {
    echo
    echo "Usage:   ${0##*/} [-d datadir] [-p plotdir] [-s] STEM1 STEM2 YEAR1 YEAR2 NB_MEMBER"
    echo
    echo "    -d DATADIR  : (MANDATORY!) location of the output to process (see header)" 
    echo "    -p PLOTDIR  : location of the plots to be produced. Default to DATADIR/plots. Created as needed."
    echo "                  This is also the location of the final PDF report."
    echo "    -s          : to skip sea ice plots (case of AMIP runs for eg)" 
}

while getopts :d:p:s OPT; do
    case $OPT in
        d) CLIMDIR=$OPTARG ;;
        p) PLOTDIR=$OPTARG ;;
        s) skipice=1 ;;
        *) usage
            exit 2
    esac
done
shift $(( OPTIND - 1 ))

# ------ CHECK ARGS -------------
if [ $# -ne 5 ] ; then
    usage
    exit 1
fi

stem1=$1
stem2=$2
year1=$3
year2=$4
nmemb=$5

if [[ ! -d $CLIMDIR ]]
then
    echo "*EE* CLIMDIR is not defined!"
    usage
    exit 1    
fi
RK=$CLIMDIR

[[ -z $PLOTDIR ]] && PLOTDIR=$CLIMDIR/plots
mkdir -p $PLOTDIR


# ------ PLOTS and STATISTICS -------------
cd R_scripts

# - Producing basic time series
Rscript basic_plots.R $CLIMDIR $PLOTDIR $stem1 $stem2 $year1 $year2 $nmemb $skipice

# - Comparing Reichler & Kim indices
Rscript KS_index.R $CLIMDIR $RK $PLOTDIR $stem1 $stem2 $year1 $year2

# - Mapping the differences between the two ensembles
Rscript map_diff_experiments.R $CLIMDIR $PLOTDIR $stem1 $stem2 $year1 $year2 $nmemb $skipice


# ------ PDF REPORT -------------
cd $PLOTDIR
for f in *_${stem1}_${stem2}*.eps
do
    epstopdf $f
done

pdfmerge reichler_kim_scores_stat_${stem1}_${stem2}.pdf \
         series_${stem1}_${stem2}_*pdf \
         diff_${stem1}_${stem2}_*pdf \
         p_value_diff_${stem1}_${stem2}_*pdf \
         repro-test_${stem1}-${stem2}_${year1}-${year2}_${nmemb}-members.pdf

\rm -f reichler_kim_scores_stat_${stem1}_${stem2}.pdf \
    series_${stem1}_${stem2}_*pdf \
    diff_${stem1}_${stem2}_*pdf \
    p_value_diff_${stem1}_${stem2}_*pdf
