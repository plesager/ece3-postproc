#!/bin/bash
#
# -- Author : François Massonnet, francois.massonnet@ic3.cat
# -- Date   : 30 Jan 2015
# -- At     : IC3, Barcelona
# -- Modified : 19 Jan 2016, omar.bellprat@bsc.es 
#               November 2017, francois.massonnet@uclouvain.be
# -- Purpose: Generation of an arbitrary number of NEMO oceanic
#             restarts that are copies of a reference, plus a
#             perturbation 
#
# -- Method : The reference file is duplicated in this script, then
#             read by a R script. The perturbation is introduced and
#             finally written to this latter file. 

module load R

set -o errexit
set -o nounset
#set -x


if [ $# == 0 ] ; then
  echo ""
  echo "  Usage: gener_perturb_restart.bash NETCDF-file NUMBER-members"
  echo "      PURPOSE : "
  echo "        Creates NUMBER-members copies of the input NETCDF-file file"
  echo "        and adds for each copy a white noise to sea surface"
  echo "        temperature (standard deviation: 10^(-4) K)"
  echo "        This script can be used to generate ensemble members"
  echo "        for coupled simulations"
  echo "      ARGUMENTS : "
  echo "        NETCDF-file : Restart file of NEMO (NetCDF format). The file"
  echo "                      must contain a variable named tn"
  echo "        NUMBER-members : number of perturbed restarts to generate"
  echo "      OUTPUT : "
  echo "        NUMBER-members copies of the original files with perturbed"
  echo "        variable tn. The file names are the same as the input files"
  echo "        but with suffix pertXX where XX = 01, 02, 03, ..."
  echo "      EXAMPLE : "
  echo "        ./gener_perturb_restart.bash EC04_00046752_restart_oce_0005.nc 5"
  echo "        --> will create:"
  echo "              EC04_00046752_restart_oce_0005_pert01.nc"
  echo "              EC04_00046752_restart_oce_0005_pert02.nc"
  echo "              EC04_00046752_restart_oce_0005_pert03.nc"
  echo "              EC04_00046752_restart_oce_0005_pert04.nc"
  echo "              EC04_00046752_restart_oce_0005_pert05.nc"
  echo "      HELPDESK : "
  echo "        francois.massonnet@uclouvain.be"
  echo ""
  exit
fi

filein=$1
nmemb=$2

# ---------------------------------------------------------

var=tn          # Variable to be perturbed
per=0.0001      # Standard deviation of gaussian perturbation to be applied,
                # in units of the variable (for tn: in K for example)

cp $filein ${filein}.backup # Do a backup

for jmemb in `seq 1 $nmemb`
do
  echo "Doing copy $jmemb out of $nmemb"
  jmemb=$(printf "%02d" $jmemb)
  # 1. Make a copy of the original file, with the new name
  filenew="${filein%.nc}_pert${jmemb}.nc"
  cp $filein $filenew

  # 2. Prepare the R script

  echo "#!/usr/bin/env Rscript
  library(ncdf4)

  # François Massonnet, 30 Jan 2015
  # Adds a gaussian perturbation at the first level of a 3D field
  # Tested only for NEMO restarts
  #
  # This script should be called by a bash script so that the variable and file names are specified, as well as the perturbation

  varname='$var'
  filein <- '$filenew'
  ex.nc           <- nc_open(filein,write=TRUE)
  spert <- $per

  myvar     <- ncvar_get(ex.nc, varname)
  myvarpert <- myvar
  for (i in seq(1,dim(myvar)[1])){
    for (j in seq(1,dim(myvar)[2])){
      if (myvar[i,j,1] != 0){
        myvarpert[i,j,1] = myvarpert[i,j,1] + rnorm(1,sd=spert)
      }
    }
  }

  ncvar_put(ex.nc,varname,myvarpert)
  nc_close(ex.nc)" > Rtmpfile.R

  chmod 744 Rtmpfile.R

  # 3. Run the R script, that produces the new NetCDF
  ./Rtmpfile.R 

  rm -f Rtmpfile.R
done

