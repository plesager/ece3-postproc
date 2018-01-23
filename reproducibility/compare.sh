#/!bin/bash

# This script launches R programs to test the difference between two ensembles
# of experiments.

set -o nounset
set -o errexit

if [ $# -ne 5 ] ; then
   echo "Usage:   ./compare.sh STEM1 STEM2 YEAR1 YEAR2 NB_MEMBER"
   echo "Example: ./compare.sh e00 f00 1990 2000 5"
   exit 1
fi

exp1=$1
exp2=$2
year1=$3
year2=$4
nmemb=$5

# --------------------------------------------------
# Location of EC-mean climatology sets for all runs
# --------------------------------------------------
#   For one run, ${stem}${nb}, data are expected in:
#   
#   $CLIM/${stem}${nb}/post/clim-${year1}-${year2}/
#
CLIMDIR=DOES-NOT-EXIST

# --------------------------------------------------
# location of R&K performance indices table
# --------------------------------------------------
#   For one ensemble, ${stem}, tables are expected in:
#
#   ${RK}/${stem}/
#
RK=DOES-NOT-EXIST


cd R_scripts

# -- step 1 - Producing basic time series

Rscript basic_plots.R $CLIMDIR $exp1 $exp2 $year1 $year2 $nmemb

# -- Step 2 - Comparing Reichler & Kim indices

Rscript KS_index.R $CLIMDIR $RK $exp1 $exp2 $year1 $year2

# -- Step 3 - Mapping the differences between the two experiments

Rscript map_diff_experiments.R $CLIMDIR $exp1 $exp2 $year1 $year2 $nmemb
