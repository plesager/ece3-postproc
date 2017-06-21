#!/bin/csh -f

#SBATCH -N 1
#SBATCH -n 3
#SBATCH -J AMWGDIAG
#SBATCH -t 03:00:00
#SBATCH -p share
#SBATCH -o out_AMWGDIAG_%J.out
#SBATCH -e err_AMWGDIAG_%J.out



unset echo verbose
setenv DIAG_VERSION 120131  # version number YYMMDD

set test_casename  = "${TEST_RUN}"
set test_period    = "${TEST_PERIOD}"
echo
echo "test_casename = ${test_casename} !"
echo "test_period = ${test_period} !"
echo

echo; echo
echo " *** EMOP_CLIM_DIR = ${EMOP_CLIM_DIR} "
#echo " *** NCAR_DATA = ${NCAR_DATA} "
echo " *** DATA_OBS = ${DATA_OBS} "
echo " *** RHOST = ${RHOST} "
echo " *** RUSER = ${RUSER} "
echo " *** WWW_DIR_ROOT = ${WWW_DIR_ROOT} "
echo; echo


sleep 2

#******************************************************************
#  C-shell control script for AMWG Diagnostics Package.           *
#  Written by Dr. Mark J. Stevens, 2001-2003.                     *
#  Last Updated: Jan 31, 2012                                     *
#  e-mail: hannay@ucar.edu   phone: 303-497-1327                  *
#                                                                 *                      
#  - Please see the AMWG diagnostics package webpage at:          * 
#  http://www.cgd.ucar.edu/amp/amwg/diagnostics                   *
#                                                                 *   
#  - Subscribe to the ccsm-amwgdiag mailing list:                 *
#  http://mailman.cgd.ucar.edu/mailman/listinfo/ccsm_amwgdiag     *
#  to receive updates from the AMWG diagnostic package.           *
#                                                                 * 
#  Implementation of parallel version with Swift sponsored by the *
#  Office of Biological and Environmental Research of the         *
#  U.S. Department of Energy's Office of Science.                 *
#                                                                 * 
#******************************************************************
#                                                                
#
#******************************************************************
#                   PLEASE READ THIS                              *
#******************************************************************

# This script can be placed in any directory provided that
# access to the working directory and local directories are 
# available (see below).
#
# Using this script your model output can be compared with
# observations (observed and reanalysis, data) 
# or with another model run. With all the diagnostic sets 
# turned on the package will produce over 600 plots and 
# tables in your working directory. In addition, files are
# produced for the climatological monthly means and the DJF
# and JJA seasonal means, as well as the annual (ANN) means.
# 
# Input file names are of the standard CCSM type and
# they must be in netcdf format. Filenames are of the 
# form YYYY-MM.nc where YYYY are the model years and MM
# are the months, for example 00010-09.nc. The files
# can reside on the Mass Storage System (MSS), if they 
# are on the MSS the script will get them using msrcp.
# If your files are not on the MSS they must be in a local
# directory. 
#
# Normally 5 years of monthly means are used for the
# comparisons, however only 1 year of data will work. 
# The December just prior to the starting year is also
# needed for the DJF seasonal mean, or Jan and Feb of
# the year following the last full year. For example,  
# for 5-year means the following months are needed 
#
# 0000-12.nc      prior december
# 0001-01.nc      first year (must be 0001 or greater)
#  ...
# 0001-12.nc
#  ...
# 0005-01.nc      last year
#  ...
# 0005-12.nc

#--> OR you can do this 
#
# 0001-01.nc      first year (must be 0001 or greater)
#  ...
# 0001-12.nc
#  ...
# 0005-01.nc      last year full year
#  ...
# 0005-12.nc
# 0006-01.nc      following jan
# 0006-02.nc      following feb
#

#******************************************************************
#                       USER MODIFY SECTION                       *
#              Modify the following sections as needed.           *
#******************************************************************

# In the following "test case" refers to the model run to be
# compared with the "control case", which may be model or obs data.

#******************************************************************

#******************************************************************

# *****************
# *** Test case ***
# *****************

# Set the identifying casename and paths for your test case run. 
# The output netcdf files are in: $test_path_history
# The climatology files are in: $test_path_climo
# The diagnostic plots are: ${test_path_diag}
# Don t forget the trailing / when setting the paths

#setenv DATA_HOME ${NCAR_DATA} ; #lolo
setenv DATA_HOME "DUMMY" ; #lolo
set test_path_history  = ${EMOP_CLIM_DIR}/history/${test_casename}/ 
set test_path_climo    = ${EMOP_CLIM_DIR}/clim_${test_casename}_${test_period}/
set test_path_diag    = ${EMOP_CLIM_DIR}/diag_${test_casename}_${test_period}/

mkdir -p ${test_path_history}

#------------------------------------------------------------------
# If getting monthly data from MSS, or computing climatological
# means from the local test case data, specify the first model 
# year of your data, and the number of years of data to be used.
# If test_begin = 1 and test_nyrs = 1 and you want to compute DJF
# then you must have Dec of year 0000 (0000-12.nc), or Jan,Feb of
# year 0002 (0002-01.nc and 0002-02.nc).

set test_begin = 1980        # first year (must be >= 1)
set test_nyrs  = 2        # number of yrs (must be >= 1)

#------------------------------------------------------------------
# Get your TEST case MONTHLY files from the MSS?
# If yes, then set the MSS path and a local path to receive the
# test case monthly files.
# Don t forget the trailing /.

set MSS_test = 1    # (0=get files from MSS, 1=files exist locally)

# if needed set MSS path    
set MSS_testpath = /HANNAY/csm/${test_casename}/atm/hist/
set tarfile_test_flag = 0    # 0=files are stored by month on MSS; 
                             # 1=files are tarred by year on MSS

#******************************************************************

# ********************
# *** Control case ***
# ******************** 

# Select the type of control case to be compared with your model
# test case (select one). 

#set CNTL = OBS            # observed data (reanalysis etc)
set CNTL = USER           # user defined model control (see below)

#------------------------------------------------------------------
# FOR CNTL == USER ONLY (otherwise skip this section)

# Set the identifying casename and path for your control case run. 
# The output netcdf files are in: $cntl_path_history
# The climatology files are in: $cntl_path_climo
# The diagnostic plots are: $cntl_path_diag
# Don t forget the trailing / when setting the paths


set cntl_casename  = "${CNTL_RUN}"
set cntl_period    = "${CNTL_PERIOD}"
echo
echo "cntl_casename = ${cntl_casename} !"
echo "cntl_period = ${cntl_period} !"
echo

set cntl_path_history = ${EMOP_CLIM_DIR}/history/${cntl_casename}/ 
set cntl_path_climo   = ${EMOP_CLIM_DIR}/clim_${cntl_casename}_${cntl_period}/



echo
echo "test_casename = ${test_casename} => ${test_period}!"
echo "cntl_casename = ${cntl_casename} => ${cntl_period}!"
echo
sleep 2

echo; echo $cntl_path_climo ; echo


#------------------------------------------------------------------
# FOR CNTL == USER ONLY (otherwise skip this section)

# If getting monthly data from MSS, or computing climatological
# means from the local control case data, specify the first model 
# year of your data, and the number of years of data to be used.
# If cntl_begin = 1 and cntl_nyrs = 1 and you want to compute DJF
# then you must have Dec of year 0000 (0000-12.nc), or Jan,Feb of
# year 0002 (0002-01.nc and 0002-02.nc).

set cntl_begin = 1         # first year (must be >= 1)
set cntl_nyrs  = 2         # number of yrs (must be >= 1)

#------------------------------------------------------------------
# FOR CNTL == USER ONLY (otherwise skip this section)

# Get your CONTROL (cntl) MONTHLY files from the MSS?
# If yes, then set the MSS path and a local path to receive the
# control case monthly files. If no, then just set the local path 
# which has the monthly or climatological control case files. 
# Don t forget the trailing /.

set MSS_cntl = 1    # (0=get files from MSS, 1=files exist locally)

# if needed set MSS path   
set MSS_cntlpath = /HANNAY/csm/${cntl_casename}/atm/hist/
set tarfile_cntl_flag = 1    # 0=files are stored by month on MSS; 
                             # 1=files are tar ed by year on MSS

#******************************************************************

# *********************
# *** Climatologies ***
# ********************* 

# Use these settings if computing climatological means 
# from the local test case data and/or local control case data

#-----------------------------------------------------------------
# Turn on/off the computation of climatologies 
      
set test_compute_climo = 1   # (0=ON,1=OFF) 
set cntl_compute_climo = 1   # (0=ON,1=OFF) 

#-----------------------------------------------------------------
# Strip off all the variables that are not required by the AMWG package
# in the computation of the climatology

set strip_off_vars = 0     # (0=ON,1=OFF)

#-----------------------------------------------------------------
# Set seasonal output:  
#  four_seasons = 0     # DJF, MAM, JJA, SON, ANN    
#  four_seasons = 1     # DJF, JJA, ANN 
# Note:  four_seasons is not currently supported for model vs OBS diagnostics.
# if ($CNTL == OBS) then four_seasons is turned OFF.

set four_seasons = 1             # (0=ON; 1=OFF)


#-----------------------------------------------------------------
# Weight the months by their number of days when computing
# averages for ANN, DJF, JJA. This takes much longer to compute 
# the climatologies. Many users might not care about the small
# differences and leave this turned off.

set weight_months = 0     # (0=ON,1=OFF)

#----------------------------------------------------------------
# Select CAM grid 
# FV - by default
# SE - CAM-SE (HOMME cubed sphere)

set cam_grid = FV
#set cam_grid = SE


#******************************************************************

# ******************************
# *** Select diagnostic sets ***
# ****************************** 

# Select the diagnostic sets to be done. You can do one at a
# time or as many as you want at one time, or all at once.

set all_sets = 1  # (0=ON,1=OFF)  Do all the sets (1-13) 
set set_1  = 0    # (0=ON,1=OFF)  tables of global,regional means
set set_2  = 0    # (0=ON,1=OFF)  implied transport plots 
set set_3  = 0    # (0=ON,1=OFF)  zonal mean line plots
set set_4  = 0    # (0=ON,1=OFF)  vertical zonal mean contour plots
set set_4a = 0    # (0=ON,1=OFF)  vertical zonal mean contour plots
set set_5  = 0    # (0=ON,1=OFF)  2D-field contour plots
set set_6  = 0    # (0=ON,1=OFF)  2D-field vector plots
set set_7  = 0    # (0=ON,1=OFF)  2D-field polar plots
set set_8  = 0    # (0=ON,1=OFF)  annual cycle (vs lat) contour plots
set set_9  = 0    # (0=ON,1=OFF)  DJF-JJA difference plots
set set_10 = 0    # (0=ON,1=OFF)  annual cycle line plots    
set set_11 = 0    # (0=ON,1=OFF)  miscellaneous plots
set set_12 = 0    # (0=selected stations: 1=NONE, 2=ALL stations
set set_13 = 1    # (0=ON,1=OFF)  ISCCP cloud simulator plots
set set_14 = 0    # (0=ON,1=OFF)  Taylor diagram plots 
set set_15 = 0    # (0=ON,1=OFF)  Annual Cycle Plots for Select stations

# Select the control case to compare against for Taylor Diagrams
# Cam run select cam3_5; coupled run select ccsm3_5  
 
setenv TAYLOR_BASECASE ccsm3_5  # Base case to compare against
				# Options are cam3_5, ccsm3_5
				# They are both fv_1.9x2.5

#******************************************************************

# **************************************
# *** Customize plots (output/style) ***
# ************************************** 

# Select the output file type and style for plots.

set p_type = ps     # postscript
#set p_type = pdf    # portable document format (ncl ver 4.2.0.a028)
#set p_type = eps    # encapsulated postscript
#set p_type = epsi   # encapsulated postscript with bitmap 
#set p_type = ncgm   # ncar computer graphics metadata

#-------------------------------------------------------------------
# Select the output color type for plots.

 set c_type = COLOR      # color
#set c_type = MONO       # black and white

# If needed select one of the following color schemes,
# you can see the colors by clicking on the links from
# http://www.cgd.ucar.edu/cms/diagnostics

 set color_bar = default           # the usual colors
 set color_bar = blue_red          # blue,red 
#set color_bar = blue_yellow_red   # blue,yellow,red (nice!) 

#----------------------------------------------------------------
# Turn ON/OFF date/time stamp at bottom of plots.
# Leaving this OFF makes the plots larger.

set time_stamp = 1       # (0=ON,1=OFF)

#---------------------------------------------------------------
# Turn ON/OFF tick marks and labels for sets 5,6, and 7
# Turning these OFF make the areas plotted larger, which makes
# the images easier to look at. 

set tick_marks = 1       # (0=ON,1=OFF)
 
#----------------------------------------------------------------
# Use custom case names for the PLOTS instead of the 
# case names encoded in the netcdf files (default). 
# Also useful for publications.

set custom_names = 1     # (0=ON,1=OFF)

# if needed set the names
set test_name = LOLO_test               # test case name 
set cntl_name = LOLO_cntl               # control case name

#----------------------------------------------------------------
# Convert output postscript files to GIF, JPG or PNG image files 
# and place them in subdirectories along with html files.
# Then make a tar file of the web pages and GIF,JPG or PNG files.
# On Dataproc and CGD Suns GIF images are smallest since I built
# ImageMagick from source and compiled in the LZW compression.
# On Linux systems JPG will be smallest if you have an rpm or
# binary distribution of ImageMagick (and hence convert) since
# NO LZW compression is the default. Only works if you have
# convert on your system and for postscript files (p_type = ps).
# NOTE: Unless you have rebuilt ImageMagick on your Linux system
# the GIF files can be as large as the postscript plots. I 
# recommend that PNG always be used. The density option can be
# used with convert to make higher resolution images which will
# work better in powerpoint presentations, try density = 150.

set web_pages = 0     # (0=ON,1=OFF)  make images and html files
set delete_ps = 0     # (0=ON,1=OFF)  delete postscript files !lolo
set img_type  = 0     # (0=PNG,1=GIF,2=JPG) select image type
set density   = 100   # pixels/inch, use larger number for higher !lolo
                      # resolution images (default is 85)

#----------------------------------------------------------------
# Save the output netcdf files of the derived variables
# used to make the plots. These are normally deleted 
# after the plots are made. If you want to save the 
# netcdf files for your own uses then switch to ON. 

set save_ncdfs = 1       # (0=ON,1=OFF)
#----------------------------------------------------------------

# Compute whether the means of the test case and control case 
# are significantly different from each other at each grid point.
# Tests are performed only for model-to-model comparisons.  
# REQUIRES at least 10 years of model data for each case.
# Number of years from above (test_nyrs and cntl_nyrs) is used.
# Also set the significance level for the t-test.
 
set significance = 1         # (0=ON,1=OFF)

# if needed set default level
set sig_lvl = 0.05           # level of significance


#******************************************************************

# ***************************
# *** Source code location ***
# *************************** 

# Below is defined the amwg diagnostic package root location 
# on CGD machines (tramhill, hurricane, salina...), 
# CSIL machines (gale, breeze...), NERSC (davinci), and  LBNL (lens).   	 
#
# If you are installing the diagnostic package on your computer system. 
# you need to set DIAG_HOME to the root location of the diagnostic code. 
# The code is in $DIAG_HOME/code 
# The obs data in $DIAG_HOME/obs_data
# The cam3.5 data in $DIAG_HOME/cam35_data 

# CGD machines (tramhill, hurricane, salina...)
setenv DIAG_HOME ${PWD}

# CSIL machines (mirage, gale, breeze...)
#setenv DIAG_HOME /CESM/amwg/amwg_diagnostics 

# NERSC (davinci),
#setenv DIAG_HOME /global/homes/h/hannay/amwg/amwg_diagnostics

# NCSS (lens)
#setenv DIAG_HOME  /ccs/home/hannay/amwg/amwg_diagnostics

#*****************************************************************

# ****************************
# *** Additional settings  ***
# **************************** 

# Send yourself an e-mail message when everything is done. 

set email = 0        # (0=ON,1=OFF) 
set email_address = ${LOGNAME}@ucar.edu

#*****************************************************************
#*****************************************************************

# **************************
# *** Advanced settings  ***
# **************************

#*****************************************************************
  
#-------------------------------------------------
# Set to 0 to use swift
#-------------------------------------------------
setenv use_swift  1           # (0=ON,1=OFF)
setenv swift_scratch_dir /glade/scratch/$USER/swift_scratch/
set test_inst =  -1
set cntl_inst =  -1

#------------------------------------------------- 
# For set 12:
#-------------------------------------------------
# Select vertical profiles to be computed. Select from list below,
# or do all stations, or none. You must have computed the monthly
# climatological means for this to work. Preset to the 17 selected
# stations.


# Specify selected stations for computing vertical profiles.
if ($set_12 == 0 || $all_sets == 0) then
# ARCTIC (60N-90N)
  set western_alaska      = 1  # (0=ON,1=OFF) 
  set whitehorse_canada   = 1  # (0=ON,1=OFF)
  set resolute_canada     = 0  # (0=ON,1=OFF)
  set thule_greenland     = 0  # (0=ON,1=OFF)
# NORTHERN MIDLATITUDES (23N-60N)
  set new_dehli_india     = 1  # (0=ON,1=OFF)
  set kagoshima_japan     = 1  # (0=ON,1=OFF)
  set tokyo_japan         = 1  # (0=ON,1=OFF)
  set midway_island       = 0  # (0=ON,1=OFF)
  set shipP_gulf_alaska   = 0  # (0=ON,1=OFF)
  set san_francisco_ca    = 0  # (0=ON,1=OFF)
  set denver_colorado     = 1  # (0=ON,1=OFF)
  set great_plains_usa    = 0  # (0=ON,1=OFF)
  set oklahoma_city_ok    = 1  # (0=ON,1=OFF)
  set miami_florida       = 0  # (0=ON,1=OFF)
  set new_york_usa        = 1  # (0=ON,1=OFF)
  set w_north_atlantic    = 1  # (0=ON,1=OFF)
  set shipC_n_atlantic    = 1  # (0=ON,1=OFF)
  set azores              = 1  # (0=ON,1=OFF)
  set gibraltor           = 1  # (0=ON,1=OFF)
  set london_england      = 1  # (0=ON,1=OFF)
  set western_europe      = 0  # (0=ON,1=OFF)
  set crete               = 1  # (0=ON,1=OFF)
# TROPICS (23N-23S)
  set central_india       = 1  # (0=ON,1=OFF)
  set madras_india        = 1  # (0=ON,1=OFF)
  set diego_garcia        = 0  # (0=ON,1=OFF)
  set cocos_islands       = 1  # (0=ON,1=OFF)
  set christmas_island    = 1  # (0=ON,1=OFF)
  set singapore           = 1  # (0=ON,1=OFF)
  set danang_vietnam      = 1  # (0=ON,1=OFF)
  set manila              = 1  # (0=ON,1=OFF)
  set darwin_australia    = 1  # (0=ON,1=OFF)
  set yap_island          = 0  # (0=ON,1=OFF)
  set port_moresby        = 1  # (0=ON,1=OFF)
  set truk_island         = 0  # (0=ON,1=OFF)
  set raoui_island        = 1  # (0=ON,1=OFF)
  set gilbert_islands     = 1  # (0=ON,1=OFF)
  set marshall_islands    = 0  # (0=ON,1=OFF)
  set samoa               = 1  # (0=ON,1=OFF)
  set hawaii              = 0  # (0=ON,1=OFF)
  set panama              = 0  # (0=ON,1=OFF)
  set mexico_city         = 1  # (0=ON,1=OFF)
  set lima_peru           = 1  # (0=ON,1=OFF)
  set san_juan_pr         = 1  # (0=ON,1=OFF)
  set recife_brazil       = 1  # (0=ON,1=OFF)
  set ascension_island    = 0  # (0=ON,1=OFF)
  set ethiopia            = 1  # (0=ON,1=OFF)
  set nairobi_kenya       = 1  # (0=ON,1=OFF)
# SOUTHERN MIDLATITUDES (23S-60S)
  set heard_island        = 1  # (0=ON,1=OFF)
  set w_desert_australia  = 1  # (0=ON,1=OFF)
  set sydney_australia    = 1  # (0=ON,1=OFF)
  set christchurch_nz     = 1  # (0=ON,1=OFF)
  set easter_island       = 0  # (0=ON,1=OFF)
  set san_paulo_brazil    = 1  # (0=ON,1=OFF)
  set falkland_islands    = 1  # (0=ON,1=OFF)
# ANTARCTIC (60S-90S)
  set mcmurdo_antarctica  = 0  # (0=ON,1=OFF)
endif


#-----------------------------------------------------------------

# PALEOCLIMATE coastlines
# Allows users to plot paleoclimate coastlines for sets 5,6,7,9.
# Two special files are created which contain the needed data 
# from each different model orography. The names for these files
# are derived from the variables ${test_casename} and ${cntl_casename} 
# defined above by the user.  
# If the user wants to compare results from two different times
# when the coastlines are different then the difference plots 
# can be turned off. No difference plots are made when the
# paleoclimate model is compared to OBS DATA.
 
set paleo = 1             # (0=use or create coastlines,1=OFF)

# if needed set these
set land_mask1 = 1      # define value for land in test case ORO
set land_mask2 = 1      # define value for land in cntl case ORO
set diff_plots = 1      # make difference plots for different
                        # continental outlines  (0=ON,1=OFF)


#*****************************************************************

# **************************
# *** Obsolete settings  ***
# **************************

# These settings were used in older versions of the diagnostic
# package. It is uncommon to use these settings. 
# These settings are not somewhat obsolete  but left here 
# for the user s convenience.

#-----------------------------------------------------------------

# Need to obtain these dataset separately to compare.
#set CNTL = CAM30AMIP      # CAM 3.0 T42 AMIP2 SST run (1979-1998)
#set CNTL = CAM30          # CAM 3.0 T42 20-year climo SST control run 
#set CNTL = CAM20AMIP      # CAM 2.0 T42 AMIP2 SST run (1979-1995)
#set CNTL = CAM20          # CAM 2.0 T42 20-year climo SST control run 
#set CNTL = CCM36AMIP      # CCM 3.6 T42 AMIP2 SST run (1979-1992)
#set CNTL = CCM36          # CCM 3.6 T42 9-year climo SST control run 

#-----------------------------------------------------------------
# New file naming convention. Set the filename convention for your
# cntl files, if they use it.

#set conv_cntl = ""                   # use for older files
 set conv_cntl = "${cntl_casename}.cam2.h0."   # don t forget the trailing "."

#-----------------------------------------------------------------
# New file naming convention. Set the filename convention for your
# test files, if they use it.

#set conv_test = ""                    # use for older files
 set conv_test = "${test_casename}.cam2.h0."    # don t forget the trailing "."

#-----------------------------------------------------------------
# Morrison-Gettleman Microphysics plots (beginning in CAM3.5, with MG 
# microphysics on)
# NOTE: for model-to-model only
set microph = 0          # (0=ON,1=OFF) 


#******************************************************************
#                 INSTALLATION SPECIFIC THINGS
#      ONLY MAKE CHANGES IF YOU ARE INSTALLING THE DIAGNOSTIC
#      PACKAGE (NCL CODE ETC) ON YOUR LOCAL SYSTEM (NON NCAR SITES)
#******************************************************************

# set global and environment variables
unset noclobber
if (! $?NCARG_ROOT) then
  echo ERROR: environment variable NCARG_ROOT is not set
  echo "Do this in your .cshrc file (or whatever shell you use)"
  echo setenv NCARG_ROOT /contrib      # most NCAR systems 
  exit
else
  set NCL = $NCARG_ROOT/bin/ncl       # works everywhere
endif 


#******************************************************************
#******************************************************************
#                     S T O P   H E R E 
#                  END OF USER MODIFY SECTION
#******************************************************************
#******************************************************************

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


#******************************************************************
#******************************************************************
#                 DON T CHANGE ANYTHING BELOW HERE
#                 OR ELSE YOUR LIFE WILL BE SHORT
#******************************************************************
#******************************************************************
# set c-shell limits
limit stacksize unlimited
limit datasize  unlimited

setenv WKDIR      ${test_path_diag} 
setenv OBS_DATA   ${DATA_OBS} ; #lolo
setenv CAM35_DATA ${DATA_HOME}/climo/cam35_data 
setenv CAM30_DATA ${DATA_HOME}/climo/cam30_data
setenv CAM20_DATA ${DATA_HOME}/climo/cam20_data
setenv CCM36_DATA ${DATA_HOME}/climo/ccm36_data
setenv DIAG_CODE  ${DIAG_HOME}/code
setenv COMPARE    $CNTL
setenv PLOTTYPE   $p_type
setenv COLORTYPE  $c_type
setenv DELETEPS   $delete_ps
setenv MG_MICRO   $microph

#-----------------------------------------------------------------

# Turn off four_seasons if comparing against OBS b/c
# AMWG does not have SON and MAM for all vars in obs_data. 
# nanr 29apr10

if ($CNTL == OBS) then
   set four_seasons = 1
endif

#-----------------------------------------------------------------
# Select TEST case climatological means to be COMPUTED. Note 
# these have to be done only once and before the sets below.
# Be sure to turn these off if you don t need to compute the means.

set test_ANN_climo = 1       # (0=ON,1=OFF)  annual mean climo 
set test_DJF_climo = 1       # (0=ON,1=OFF)  seasonal mean climo
set test_JJA_climo = 1       # (0=ON,1=OFF)  seasonal mean climo
set test_MAM_climo = 1       # (0=ON,1=OFF)  seasonal mean climo
set test_SON_climo = 1       # (0=ON,1=OFF)  seasonal mean climo
set test_MON_climo = 1       # (0=ON,1=OFF)  monthly means climo

if ($test_compute_climo == 0) then

   set test_ANN_climo = 0       # (0=ON,1=OFF)  annual mean climo 
   set test_DJF_climo = 0       # (0=ON,1=OFF)  seasonal mean climo
   set test_JJA_climo = 0       # (0=ON,1=OFF)  seasonal mean climo
   set test_MON_climo = 0       # (0=ON,1=OFF)  monthly means climo

   if ($four_seasons == 0) then
      set test_MAM_climo = 0       # (0=ON,1=OFF)  seasonal mean climo
      set test_SON_climo = 0       # (0=ON,1=OFF)  seasonal mean climo
   endif

endif

#-----------------------------------------------------------------
# NOTE: For CNTL == USER (otherwise skip) 
# Select CONTROL case climatological means to be COMPUTED. 
# Be sure to turn these off if you don t need to compute the means.


set cntl_ANN_climo = 1       # (0=ON,1=OFF)  annual mean climo 
set cntl_DJF_climo = 1       # (0=ON,1=OFF)  seasonal mean climo
set cntl_JJA_climo = 1       # (0=ON,1=OFF)  seasonal mean climo
set cntl_MAM_climo = 1       # (0=ON,1=OFF)  seasonal mean climo
set cntl_SON_climo = 1       # (0=ON,1=OFF)  seasonal mean climo
set cntl_MON_climo = 1       # (0=ON,1=OFF)  monthly means climo

if ($cntl_compute_climo == 0) then

   set cntl_ANN_climo = 0       # (0=ON,1=OFF)  annual mean climo 
   set cntl_DJF_climo = 0       # (0=ON,1=OFF)  seasonal mean climo
   set cntl_JJA_climo = 0       # (0=ON,1=OFF)  seasonal mean climo
   set cntl_MON_climo = 0       # (0=ON,1=OFF)  monthly means climo

   if ($four_seasons == 0) then
      set cntl_MAM_climo = 0       # (0=ON,1=OFF)  seasonal mean climo
      set cntl_SON_climo = 0       # (0=ON,1=OFF)  seasonal mean climo
   endif

endif

#-----------------------------------------------------------------        
# Select the climatological means to be PLOTTED or in tables.
# You must have the appropriate set(s) turned on to make plots.

set plot_ANN_climo = 0       # (0=ON,1=OFF) used by sets 1-7,11 
set plot_DJF_climo = 0       # (0=ON,1=OFF) used by sets 1,3-7,9,11
set plot_JJA_climo = 0       # (0=ON,1=OFF) used by sets 1,3-7,9,11
set plot_MON_climo = 0       # (0=ON,1=OFF) used by sets 8,10,11,12
set plot_MAM_climo = 0       # (0=ON,1=OFF) used by sets 1,3-7,9,11
set plot_SON_climo = 0       # (0=ON,1=OFF) used by sets 1,3-7,9,11

if ($four_seasons == 1) then
 set plot_MAM_climo = 1       # (0=ON,1=OFF) used by sets 1,3-7,9,11
 set plot_SON_climo = 1       # (0=ON,1=OFF) used by sets 1,3-7,9,11
endif

#-----------------------------------------------------------------
# point to webpages for either 2 or 4 seasons + annual

if ($four_seasons == 1) then
   setenv HTML_HOME ${DIAG_HOME}/html                 # produce 2 seasons + annual
endif
if ($four_seasons == 0) then
    setenv HTML_HOME ${DIAG_HOME}/html_allSeason      # produce 4 seasons + annual
endif

#-----------------------------------------------------------------
# Set the rgb file name
if ($c_type == COLOR) then
  if (! $?color_bar) then
    setenv RGB_FILE ${DIAG_HOME}/rgb/amwg.rgb  # use default
  else
    if ($color_bar == default) then
      setenv RGB_FILE ${DIAG_HOME}/rgb/amwg.rgb
    else
      if ($color_bar == blue_red) then
        setenv RGB_FILE ${DIAG_HOME}/rgb/bluered.rgb
      endif
      if ($color_bar == blue_yellow_red) then
        setenv RGB_FILE ${DIAG_HOME}/rgb/blueyellowred.rgb
      endif
    endif
  endif
endif
#----------------------------------------------------------------------
# the monthly time weights
if ($weight_months == 0) then
  set ann_weights = (0.08493150770664215 0.07671232521533966 0.08493150770664215 \
    0.08219178020954132 0.08493150770664215 0.08219178020954132 0.08493150770664215 \
    0.08493150770664215 0.08219178020954132 0.08493150770664215 0.08219178020954132 \
    0.08493150770664215)

# the djf time weights
  set djf_weights = (0.3444444537162781 0.3444444537162781 0.3111111223697662)
# the mam time weights
  set mam_weights = (0.3369565308094025 0.3260869681835175 0.3369565308094025)
# the jja time weights
  set jja_weights = (0.3260869681835175 0.3369565308094025 0.3369565308094025)
# the son time weights
  set son_weights = (0.32967033 0.34065934 0.32967033)

# exclude these variables from the time weighting
# and later append them into the weighted climo file
# different selections for non regular (fv) grid
    if ($cam_grid == FV) then  
       set non_time_vars = (gw,hyam,hybm,hyai,hybi,P0)
    else
       set non_time_vars = (hyam,hybm,hyai,hybi,P0) 
       set strip_off_vars = 1    # (1=OFF) => right this option doesn t work for SE 
    endif
endif


#----------------------------------------------------------------------
# set of required variables for AMWG package

set required_vars = (AODVIS AODDUST AODDUST1 AODDUST2 AODDUST3 \
                     ANRAIN ANSNOW AQRAIN AQSNOW AREI AREL AWNC AWNI \
                     CCN3 CDNUMC CLDHGH CLDICE CLDLIQ CLDMED CLDLOW CLDTOT   \
                     CLOUD DCQ DTCOND DTV FICE FLDS FLNS FLNSC FLNT FLNTC    \
                     FLUT FLUTC FREQI FREQL FREQR FREQS FSDS FSDSC FSNS FSNSC \
                     FSNTC FSNTOA FSNTOAC FSNT ICEFRAC ICIMR ICWMR IWC LANDFRAC \
                     LHFLX LWCF NUMICE NUMLIQ OCNFRAC OMEGA OMEGAT P0 PBLH PRECC \
                     PRECL PRECSC PRECSL PS PSL Q QFLX QRL QRS RELHUM SHFLX   \
                     SNOWHICE SNOWHLND SOLIN SRFRAD SWCF T TAUX TAUY TGCLDIWP \
                     TGCLDLWP TMQ TREFHT TS U UU V VD01 VQ VT VU VV WSUB Z3 \
                     CLD_MISR FMISR1 \
                     FISCCP1_COSP FISCCP1 CLDTOT_ISCCP \
                     MEANPTOP_ISCCP MEANCLDALB_ISCCP \
                     CLMODIS FMODIS1 \
                     CLTMODIS CLLMODIS CLMMODIS CLHMODIS CLWMODIS CLIMODIS \
                     IWPMODIS LWPMODIS REFFCLIMODIS REFFCLWMODIS \
                     TAUILOGMODIS TAUWLOGMODIS TAUTLOGMODIS \
                     TAUIMODIS TAUWMODIS TAUTMODIS PCTMODIS \
                     CFAD_DBZE94_CS CFAD_SR532_CAL \
                     CLDTOT_CAL CLDLOW_CAL CLDMED_CAL CLDHGH_CAL CLDTOT_CS2)


#------------------------------------------------------------------------
echo " "
echo "***************************************************"
echo "        EC-Earth AMWG DIAGNOSTIC PACKAGE"
echo "          Script Version: "$DIAG_VERSION
echo "          NCARG_ROOT = "$NCARG_ROOT
echo "          "`date`
echo "***************************************************"
echo " "
# check for .hluresfile in $HOME
if (! -e $HOME/.hluresfile) then
  echo NO .hluresfile PRESENT IN YOUR $HOME DIRECTORY
  echo COPYING .hluresfile to $HOME
  cp $DIAG_CODE/.hluresfile $HOME
endif

#------------------------------------------------------------
# check if directories exist

if (! -e ${test_path_diag}) then
  echo The directory \${test_path_diag} ${test_path_diag} does not exist
  echo Trying to create \${test_path_diag} ${test_path_diag} 
  mkdir ${test_path_diag} 
  if (! -e ${test_path_diag}) then
    echo ERROR: Unable to create \${test_path_diag} : ${test_path_diag}    
    echo ERROR: Please create: ${test_path_diag} 
  exit
  endif
endif

if (! -w ${test_path_diag}) then
  echo ERROR: YOU DO NOT HAVE WRITE ACCESS TO \${test_path_diag} ${test_path_diag}
  exit
endif

if (! -e ${test_path_history}) then
  echo The directory \$test_path_history ${test_path_history} does not exist
  echo Trying to create \$test_path_history ${test_path_history} 
  mkdir ${test_path_history} 
  if (! -e ${test_path_history}) then
    echo ERROR: Unable to create \$test_path_history: ${test_path_history} 
    echo ERROR: Please create ${test_path_history} 
   exit
  endif
endif

if (! -e ${test_path_climo}) then
  echo The directory \$test_path_climo ${test_path_climo} does not exist
  echo Trying to create \$test_path_climo ${test_path_climo} 
  mkdir ${test_path_climo} 
  if (! -e ${test_path_climo}) then
    echo ERROR: Unable to create \$test_path_climo: ${test_path_climo} 
    echo ERROR: Please create ${test_path_climo} 
   exit
  endif
endif

if (! -e ${test_path_diag}) then
  echo The directory \${test_path_diag} ${test_path_diag} does not exist
  echo Trying to create \${test_path_diag} ${test_path_diag} 
  mkdir ${test_path_diag} 
  if (! -e ${test_path_diag}) then
    echo ERROR: Unable to create \${test_path_diag}: ${test_path_diag} 
    echo ERROR: Please create ${test_path_diag} 
   exit
  endif
endif


if ($CNTL == USER) then
  if (! -e ${cntl_path_history}) then
    echo The directory \$cntl_path_history ${cntl_path_history} does not exist
    echo Trying to create \$cntl_path_history ${cntl_path_history} 
    mkdir ${cntl_path_history}    
    if (! -e ${cntl_path_history}) then
       echo ERROR: Unable to create \$cntl_path_history: ${cntl_path_history} 
       echo ERROR: Please create ${cntl_path_history} 
       exit
    endif
  endif
endif


if ($CNTL == USER) then
  if (! -e ${cntl_path_climo}) then
    echo The directory \$cntl_path_climo ${cntl_path_climo} does not exist
    echo Trying to create \$cntl_path_climo ${cntl_path_climo} 
    mkdir ${cntl_path_climo}    
    if (! -e ${cntl_path_climo}) then
       echo ERROR: Unable to create \$cntl_path_climo: ${cntl_path_climo} 
       echo ERROR: Please create  ${cntl_path_climo} 
       exit
    endif
  endif
endif




#-----------------------------------------------------------------
if ($paleo == 0) then
  setenv PALEO True
  if ($diff_plots == 0) then    # only allow when paleoclimate true
    setenv DIFF_PLOTS True      
  else
    setenv DIFF_PLOTS False
  endif
else
  setenv PALEO False
  setenv PALEOCOAST1 null
  setenv PALEOCOAST2 null
  setenv DIFF_PLOTS False
endif

#-----------------------------------------------------------------
if ($time_stamp == 0) then
  setenv TIMESTAMP True
else
  setenv TIMESTAMP False
endif
if ($tick_marks == 0) then
  setenv TICKMARKS True
else
  setenv TICKMARKS False
endif
if ($custom_names == 0) then
  setenv CASENAMES True
  setenv CASE1 $test_name
  setenv CASE2 $cntl_name
else
  setenv CASENAMES False
  setenv CASE1 null 
  setenv CASE2 null
  setenv CNTL_PLOTVARS null  
endif

#--------------------------------------------------------------------
if ($significance == 0) then 
  if ($CNTL != USER) then
    echo ERROR: SIGNIFICANCE TEST ONLY AVAILABLE FOR MODEL-TO-MODEL COMPARISONS
    exit
  endif
  if ($test_nyrs < 10) then
    echo ERROR: NUMBER OF TEST CASE YRS $test_nyrs IS TOO SMALL FOR SIGNIFICANCE TEST.
    exit
  endif
  if ($cntl_nyrs < 10) then
    echo ERROR: NUMBER OF CNTL CASE YRS $cntl_nyrs IS TOO SMALL FOR SIGNIFICANCE TEST.
    exit
  endif
  setenv SIG_PLOT True
  setenv SIG_LVL $sig_lvl
else
  setenv SIG_PLOT False
  setenv SIG_LVL "null"
endif 

#-----------------------------------------------------------------
# set test directory names
#-----------------------------------------------------------------
set test_in  = ${test_path_climo}${test_casename}     # input files 
set test_out = ${test_path_climo}${test_casename}       # output files

#--------------------------------------------------------------------
# set control case names
#-----------------------------------------------------------------
echo ' '
if ($CNTL == OBS) then        # observed data
 echo '------------------------------'
 echo  COMPARISONS WITH OBSERVED DATA 
 echo '------------------------------'
 set cntl_in = $OBS_DATA
endif
if ($CNTL == CAM30AMIP) then   # CAM 3.0 AMIP
  echo '----------------------------------'
  echo  COMPARISONS WITH CAM3.0 AMIP2 CNTL
  echo '----------------------------------'
  set cntl_casename = cam30amip
  set cntl_in = ${CAM30_DATA}/${cntl_casename}
  set cntl_out = ${cntl_path_climo}${cntl_casename}
endif
if ($CNTL == CAM30) then       # CAM 3.0
  echo '---------------------------------'
  echo  COMPARISONS WITH CAM3.0 CNTL RUN
  echo '---------------------------------'
  set cntl_casename = cam30
  set cntl_in = ${CAM30_DATA}/${cntl_casename}
  set cntl_out = ${cntl_path_climo}${cntl_casename}
endif
if ($CNTL == CAM20AMIP) then   # CAM 2.0 AMIP
  echo '----------------------------------'
  echo  COMPARISONS WITH CAM2.0 AMIP2 CNTL
  echo '----------------------------------'
  set cntl_casename = cam20amip
  set cntl_in = ${CAM20_DATA}/${cntl_casename}
  set cntl_out = ${cntl_path_climo}${cntl_casename}
endif
if ($CNTL == CAM20) then       # CAM 2.0
  echo '---------------------------------'
  echo  COMPARISONS WITH CAM2.0 CNTL RUN
  echo '---------------------------------'
  set cntl_casename = cam20
  set cntl_in = ${CAM20_DATA}/${cntl_casename}
  set cntl_out = ${cntl_path_climo}${cntl_casename}
endif
if ($CNTL == CCM36AMIP) then   # CCM 3.6 AMIP
  echo '----------------------------------'
  echo  COMPARISONS WITH CCM3.6 AMIP2 CNTL
  echo '----------------------------------'
  set cntl_casename = ccm36amip
  set cntl_in = ${CCM36_DATA}/${cntl_casename}
  set cntl_out = ${cntl_path_climo}${cntl_casename}
endif
if ($CNTL == CCM36) then       # CCM 3.6
  echo '---------------------------------'
  echo  COMPARISONS WITH CCM3.6 CNTL RUN
  echo '---------------------------------'
  set cntl_casename = ccm36
  set cntl_in = ${CCM36_DATA}/${cntl_casename}
  set cntl_out = ${cntl_path_climo}${cntl_casename}
endif
if ($CNTL == USER) then        # user specified
 echo '------------------------------------'
 echo  COMPARISONS WITH USER SPECIFIED CNTL 
 echo '------------------------------------'
 echo ' '
 set cntl_in = ${cntl_path_climo}${cntl_casename}
 set cntl_out = ${cntl_path_climo}${cntl_casename}
endif

#----------------------------------------------------------------
# Do some safety checks
#----------------------------------------------------------------
if ($test_in == $cntl_in) then
  echo ERROR: THE INPUT TEST AND CNTL PATH AND CASENAME NAMES ARE IDENTICAL
  exit
endif   
if ($CNTL == USER) then    
  if (${test_casename} == ${cntl_casename}) then
    echo ERROR: THE TEST AND CNTL AND CASENAME NAMES ARE IDENTICAL
    exit
  endif
endif   
if ($MSS_cntl == 0 && $CNTL != USER) then
  echo "Resetting MSS_cntl = 1"
  set MSS_cntl = 1
endif
if ($MSS_test == 0 && $MSS_cntl == 0) then
  if ($test_path_history == $cntl_path_history) then
    echo ERROR: THE TEST PATH AND CNTL PATH ARE IDENTICAL
    echo THEY MUST BE DIFFERENT TO RECEIVE MSS DOWNLOADS!
    exit
  endif
endif

#*****************************************************************
# Get test case monthly files from Mass Storage System if needed
#*****************************************************************
if ($MSS_test == 0) then
  echo GETTING TEST CASE MONTHLY FILES FROM THE MSS
  echo THIS MIGHT TAKE SOME TIME ... 
  echo ' '
  # December prior to first year
  if ($test_begin >= 1) then    # so we don t get a negative number
    @ cnt = $test_begin
    @ cnt --
    set prevyear = ${conv_test}`printf "%04d" ${cnt}`
    echo $prevyear-12.nc
    if (! -e ${test_path_history}/${prevyear}-12.nc || -z ${test_path_history}/${prevyear}-12.nc) then
	if ($tarfile_test_flag == 0) then
    		echo 'GETTING '${MSS_testpath}${prevyear}-12.nc
    		#msrcp 'mss:'${MSS_testpath}${prevyear}-12.nc $test_path_history
                echo hsi get ${test_path_history}${prevyear}-12.nc :  ${MSS_testpath}${prevyear}-12.nc
                hsi get ${test_path_history}${prevyear}-12.nc :  ${MSS_testpath}${prevyear}-12.nc
	else
	   if ($cnt >= 0) then
    		echo 'GETTING '${MSS_testpath}${prevyear}.tar
   		#msrcp 'mss:'${MSS_testpath}${prevyear}.tar $test_path_history
                hsi get  $test_path_history/${prevyear}.tar : ${MSS_testpath}${prevyear}.tar               
		set mydir = `pwd`
		cd $test_path_history
		tar -xvf ${prevyear}.tar
		rm    -f ${prevyear}.tar
		cd $mydir
	   endif
	endif
    else
    	echo 'FOUND '${MSS_testpath}${prevyear}-12.nc
    endif
  else
    echo ERROR: FIRST YEAR OF TEST DATA $test_begin MUST BE GT ZERO
    exit
  endif
  @ yr_cnt = $test_begin
  @ yr_end = $test_begin + $test_nyrs - 1    # space between "-" and "1"
  while ( $yr_cnt <= $yr_end )           # loop over years
    set filename = ${conv_test}`printf "%04d" ${yr_cnt}`
    @ mon = 1
    set months = (01 02 03 04 05 06 07 08 09 10 11 12)
    while ($mon <= 12)
    	set tname = ${conv_test}`printf "%04d" ${yr_cnt}`-${months[$mon]}.nc
        if (! -e ${test_path_history}/$tname || -z ${test_path_history}/$tname) then
	     if ($tarfile_test_flag == 0) then
    		echo  'GETTING '${MSS_testpath}${filename}'*.nc' 
    		#msrcp 'mss:'${MSS_testpath}${filename}'*.nc' $test_path_history
                set mydir = `pwd`
		cd $test_path_history
                hsi "prompt; mget '${MSS_testpath}${filename}-*.nc'  ; exit"     
                cd $mydir          
	     else
    		echo 'GETTING '${MSS_testpath}${filename}.tar
    		#msrcp 'mss:'${MSS_testpath}${filename}.tar $test_path_history 
                set mydir = `pwd`
		cd $test_path_history
                hsi "get  ${MSS_testpath}${filename}.tar  ; exit"     
		tar -xvf ${filename}.tar
		rm    -f ${filename}.tar
		cd $mydir
	     endif
	     @ mon = 12
    	else
    		echo  'FOUND '${test_path_history}${tname}'*.nc'
	endif
	@ mon++
    end
    @ yr_cnt++                             # advance year
  end 
  # Jan, Feb of year following the last year
  @ cnt = $yr_end + 1 
  set filename = ${conv_test}`printf "%04d" ${cnt}`
  if (! -e ${test_path_history}${filename}-01.nc || \
        -z ${test_path_history}${filename}-01.nc || \
        -z ${test_path_history}${filename}-02.nc) then
    if ($tarfile_test_flag == 0) then
    	echo 'GETTING '${MSS_testpath}${filename}-01.nc
    	#msrcp 'mss:'${MSS_testpath}${filename}-01.nc $test_path_history
    	hsi "get  ${test_path_history}${filename}-01.nc : ${MSS_testpath}${filename}-01.nc"
        echo 'GETTING '${MSS_testpath}${filename}-02.nc
    	#msrcp 'mss:'${MSS_testpath}${filename}-02.nc $test_path_history
    	hsi "get  ${test_path_history}${filename}-02.nc : ${MSS_testpath}${filename}-02.nc"
    	echo TEST CASE MONTHLY FILES COPIED FROM THE MSS TO ${test_path_history} 
    	echo ' '
    else
    	echo 'GETTING '${MSS_testpath}${filename}.tar
    	#msrcp 'mss:'${MSS_testpath}${filename}.tar $test_path_history
    	hsi "get  ${test_path_history}${filename}.tar : ${MSS_testpath}${filename}.tar"
	set mydir = `pwd`
	cd $test_path_history
	tar -xvf ${filename}.tar
	rm    -f ${filename}.tar
	cd $mydir
    endif
  endif
endif
#---------------------------------------------------------------
# Get control case monthly files from Mass Storage System if needed
#---------------------------------------------------------------
if ($MSS_cntl == 0) then
  echo ' '
  echo GETTING CNTL CASE MONTHLY FILES FROM THE MSS
  echo THIS MIGHT TAKE SOME TIME ... 
  echo ' '
  # December prior to first year
  if ($cntl_begin >= 1) then    # so we don t get a negative number
    @ cnt = $cntl_begin
    @ cnt --

    set prevyear = ${conv_cntl}`printf "%04d" ${cnt}`
    if (! -e ${cntl_path_history}/${prevyear}-12.nc || -z ${cntl_path_history}/${prevyear}-12.nc) then
        if ($tarfile_cntl_flag == 0 ) then
    		echo 'GETTING '${MSS_cntlpath}${prevyear}-12.nc
    		#msrcp 'mss:'${MSS_cntlpath}${prevyear}-12.nc $cntl_path_history
                hsi get ${cntl_path_history}${prevyear}-12.nc :  ${MSS_cntlpath}${prevyear}-12.nc
	else
	   if ($cnt >= 0) then
    		echo 'GETTING '${MSS_cntlpath}${prevyear}.tar
    		#msrcp 'mss:'${MSS_cntlpath}${prevyear}.tar $cntl_path_history      
		set mydir = `pwd`
		cd $cntl_path_history
                hsi get ${MSS_cntlpath}${prevyear}.tar     
		tar -xvf ${prevyear}.tar
	        rm    -f ${prevyear}.tar
		echo $mydir
		cd $mydir
	   endif
	endif
    else
    	echo 'FOUND '${MSS_cntlpath}${prevyear}-12.nc
    endif
  else
    echo ERROR: FIRST YEAR OF CNTL DATA $cntl_begin MUST BE GT ZERO
    exit
  endif

  @ yr_cnt = $cntl_begin
  @ yr_end = $cntl_begin + $cntl_nyrs - 1    # space between "-" and "1"
  while ( $yr_cnt <= $yr_end )           # loop over years
    set filename = ${conv_cntl}`printf "%04d" ${yr_cnt}`
    @ mon = 1
    set months = (01 02 03 04 05 06 07 08 09 10 11 12)
    while ($mon <= 12)
    	set tname = ${conv_cntl}`printf "%04d" ${yr_cnt}`-${months[$mon]}.nc
	if (! -e ${cntl_path_history}/$tname || -z ${cntl_path_history}/$tname) then
             if ($tarfile_cntl_flag == 0) then
    		echo  'GETTING '${MSS_cntlpath}${filename}'*.nc'
    		#msrcp 'mss:'${MSS_cntlpath}${filename}'*.nc' $cntl_path_history
                set mydir = `pwd`
		cd $cntl_path_history
                hsi "prompt; mget '${MSS_cntlpath}${filename}-*.nc'  ; exit"     
                cd $mydir 
	     else
    		echo 'GETTING '${MSS_cntlpath}${filename}.tar
    		#msrcp 'mss:'${MSS_cntlpath}${filename}.tar $cntl_path_history
		set mydir = `pwd`
                cd $cntl_path_history
                hsi "get  ${MSS_cntlpath}${filename}.tar  ; exit"   
		tar -xvf ${filename}.tar
	        rm    -f ${filename}.tar
		cd $mydir
	     endif
	     @ mon = 12
    	else
    		echo  'FOUND '${cntl_path_history}${tname}'*.nc'
	endif
	@ mon++
    end
    @ yr_cnt++                             # advance year
  end 

  # Jan, Feb of year following the last year
  @ cnt = $yr_end + 1 
  set filename = ${conv_cntl}`printf "%04d" ${cnt}`
  if (! -e ${cntl_path_history}${filename}-01.nc || \
        -z ${cntl_path_history}${filename}-01.nc || \
        -z ${cntl_path_history}${filename}-02.nc) then
    if ($tarfile_cntl_flag == 0) then
    	echo 'GETTING '${MSS_cntlpath}${filename}-01.nc
    	#msrcp 'mss:'${MSS_cntlpath}${filename}-01.nc $cntl_path_history
    	hsi "get  ${cntl_path_history}${filename}-01.nc : ${MSS_cntlpath}${filename}-01.nc"
    	echo 'GETTING '${MSS_cntlpath}${filename}-02.nc
    	#msrcp 'mss:'${MSS_cntlpath}${filename}-02.nc $cntl_path_history
    	hsi "get  ${cntl_path_history}${filename}-02.nc : ${MSS_cntlpath}${filename}-02.nc"
    	echo CNTL CASE MONTHLY FILES COPIED FROM THE MSS TO ${cntl_path_history} 
    	echo ' '
    else
    	echo 'GETTING '${MSS_cntlpath}${filename}.tar
    	#msrcp 'mss:'${MSS_cntlpath}${filename}.tar $cntl_path_history
    	hsi "get  ${cntl_path_history}${filename}.tar : ${MSS_cntlpath}${filename}.tar"
	set mydir = `pwd`
	cd $cntl_path_history
	tar -xvf ${filename}.tar
	rm    -f ${filename}.tar
	cd $mydir
    endif
  endif
endif


#********************************************************************
# To compute climatological means check if all monthly files 
# are present in test_path_history directory 
#********************************************************************

set months = (01 02 03 04 05 06 07 08 09 10 11 12)

if ($test_ANN_climo == 0 || $test_MON_climo == 0) then
  echo CHECKING $test_path_history 
  echo FOR ALL MONTHLY FILES TEST_ANN
  echo ' '
  # check for the all months
  @ yr_cnt = $test_begin
  @ yr_end = $test_begin + $test_nyrs - 1      # space between "-" and "1"
  while ( $yr_cnt <= $yr_end )               # loop over years
    foreach month ($months)
      set filename = ${conv_test}`printf "%04d" ${yr_cnt}`-${month}
      echo  'CHECKING FOR '${test_path_history}${filename}.nc
      if (! -e ${test_path_history}${filename}.nc || -z ${test_path_history}${filename}.nc) then      #file does not exist
        echo ${test_path_history}${filename}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
        exit
      endif
    end
    @ yr_cnt++
  end
  echo '-->ALL' ${test_casename} MONTHLY FILES FOUND
  echo ' '
endif

if ($test_DJF_climo == 0) then
  echo CHECKING $test_path_history 
  echo FOR DJF MONTHLY FILES
  echo ' '
  if ($test_begin >= 1) then    # so we don t get a negative number
    @ cnt = $test_begin
    @ cnt--
    set yearnum = ${conv_test}`printf "%04d" ${cnt}`
  else
    echo ERROR: FIRST YEAR OF TEST DATA $test_begin MUST BE GT ZERO
    exit
  endif    
  if (! -e ${test_path_history}${yearnum}-12.nc || -z ${test_path_history}${yearnum}-12.nc) then    # dec of previous year
#   echo ${test_path_history}${yearnum}-12.nc NOT FOUND
#   check for Jan, Feb of the year following the last year
    @ next_year = $test_begin + $test_nyrs
    set yearnum = ${conv_test}`printf "%04d" ${next_year}`
#   echo 'CHECKING FOR '${test_path_history}${yearnum}-01.nc
    if (! -e ${test_path_history}${yearnum}-01.nc || -z ${test_path_history}${yearnum}-01.nc) then
      echo ERROR: ${test_path_history}${yearnum}-01.nc NOT FOUND
      echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
      exit
    endif
#   echo 'CHECKING FOR '${test_path_history}${yearnum}-02.nc
    if (! -e ${test_path_history}${yearnum}-02.nc || -z ${test_path_history}${yearnum}-02.nc) then
      echo ERROR: ${test_path_history}${yearnum}-02.nc NOT FOUND
      echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
      exit
    endif
    @ yr_cnt = $test_begin + 1
    @ yr_end = $test_begin + $test_nyrs     
    while ( $yr_cnt <= $yr_end )               # loop over years
      @ prev_yr = $yr_cnt - 1
      set dec = ${conv_test}`printf "%04d" ${prev_yr}`-12
      if (! -e ${test_path_history}${dec}.nc || -z ${test_path_history}${dec}.nc) then
        echo ERROR: ${test_path_history}${dec}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
        exit
      endif                 
      foreach month (01 02)
        set filename = ${conv_test}`printf "%04d" ${yr_cnt}`-${month}     
#       echo  'CHECKING FOR '${test_path_history}${filename}.nc
	if (! -e ${test_path_history}${filename}.nc || -z ${test_path_history}${filename}.nc) then      #file does not exist
          echo ERROR: ${test_path_history}${filename}.nc NOT FOUND
          echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
          exit
        endif
      end
      @ yr_cnt++
    end    
    set test_djf = NEXT      # use Jan, Feb of year after last year 
  else
#   echo ${test_path_history}${yearnum}-12.nc FOUND
    @ yr_cnt = $test_begin
    @ yr_end = $test_begin + $test_nyrs - 1
    while ( $yr_cnt <= $yr_end )               # loop over years
      @ prev_yr = $yr_cnt - 1
      set dec = ${conv_test}`printf "%04d" ${prev_yr}`-12
      if (! -e ${test_path_history}${dec}.nc || -z ${test_path_history}${dec}.nc) then
        echo ERROR: ${test_path_history}${dec}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
        exit
      endif                 
      foreach month (01 02)
        set filename = ${conv_test}`printf "%04d" ${yr_cnt}`-${month}     
#       echo  'CHECKING FOR '${test_path_history}${filename}.nc
	if (! -e ${test_path_history}${filename}.nc || -z ${test_path_history}${filename}.nc) then      #file does not exist
          echo ERROR: ${test_path_history}${filename}.nc NOT FOUND
          echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
          exit
        endif
      end
      @ yr_cnt++
    end
    set test_djf = PREV      # use Dec of year before first year
  endif
  echo '-->ALL' ${test_casename} DJF FILES FOUND
  echo ' '
endif


#-----------------------------------------------------------
# 2apr10 nanr - added MAM
#-----------------------------------------------------------
if ($test_MAM_climo == 0) then
  echo CHECKING $test_path_history 
  echo FOR MAM MONTHLY FILES
  echo ' '
  @ yr_cnt = $test_begin 
  @ yr_end = $test_begin + $test_nyrs - 1   
  while ( $yr_cnt <= $yr_end )               # loop over years             
    foreach month (03 04 05)
      set filename = ${conv_test}`printf "%04d" ${yr_cnt}`-${month}     
#     echo  'CHECKING FOR '${test_path_history}${filename}.nc
      if (! -e ${test_path_history}${filename}.nc || -z ${test_path_history}${filename}.nc) then      #file does not exist
        echo ERROR: ${test_path_history}${filename}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
        exit
      endif
    end
    @ yr_cnt++
  end
  echo '-->ALL' ${test_casename} MAM FILES FOUND
  echo ' '      
endif 

# End MAM--------------------------------------------------------

if ($test_JJA_climo == 0) then
  echo CHECKING $test_path_history 
  echo FOR JJA MONTHLY FILES
  echo ' '
  @ yr_cnt = $test_begin 
  @ yr_end = $test_begin + $test_nyrs - 1   
  while ( $yr_cnt <= $yr_end )               # loop over years             
    foreach month (06 07 08)
      set filename = ${conv_test}`printf "%04d" ${yr_cnt}`-${month}     
#     echo  'CHECKING FOR '${test_path_history}${filename}.nc
      if (! -e ${test_path_history}${filename}.nc || -z ${test_path_history}${filename}.nc) then      #file does not exist
        echo ERROR: ${test_path_history}${filename}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
        exit
      endif
    end
    @ yr_cnt++
  end
  echo '-->ALL' ${test_casename} JJA FILES FOUND
  echo ' '      
endif 

#-----------------------------------------------------------
# 16jan09 nanr  - added SON
#-----------------------------------------------------------
if ($test_SON_climo == 0) then
  echo CHECKING $test_path_history
  echo FOR SON MONTHLY FILES
  echo ' '
  @ yr_cnt = $test_begin
  @ yr_end = $test_begin + $test_nyrs - 1
  while ( $yr_cnt <= $yr_end )               # loop over years             
    foreach month (09 10 11)
      set filename = ${conv_test}`printf "%04d" ${yr_cnt}`-${month}
#     echo  'CHECKING FOR '${test_path_history}${filename}.nc
      if (! -e ${test_path_history}${filename}.nc || -z ${test_path_history}${filename}.nc) then      #file does not exist
        echo ERROR: ${test_path_history}${filename}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $test_path_history
        exit
      endif
    end
    @ yr_cnt++
  end
  echo '-->ALL' ${test_casename} SON FILES FOUND
  echo ' '
endif

#End SON   --------------------------------------------------------------
#*************************************************************************
# check if monthly files are present in the control case path
#*************************************************************************
#if ($CNTL != USER) goto TEST_ANN_AVE
if ($CNTL != USER) goto CALC_STATS

if ($cntl_ANN_climo == 0 || $cntl_MON_climo == 0) then
  echo CHECKING $cntl_path_history
 
  echo FOR ALL MONTHLY FILES CNTL_ANN
  echo ' '
  # check for the all months
  @ yr_cnt = $cntl_begin
  @ yr_end = $cntl_begin + $cntl_nyrs - 1     
  while ( $yr_cnt <= $yr_end )                 # loop over years
    foreach month ($months)
      set filename = ${conv_cntl}`printf "%04d" ${yr_cnt}`-${month}
#     echo  'CHECKING FOR '${cntl_path_history}${filename}.nc
      if (! -e ${cntl_path_history}${filename}.nc) then      #file does not exist
        echo ERROR: ${cntl_path_history}${filename}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
        exit
      endif
    end
    @ yr_cnt++
  end
  echo '-->ALL' ${cntl_casename} MONTHLY FILES FOUND
  echo ' '
endif

if ($cntl_DJF_climo == 0) then
  echo CHECKING $cntl_path_history 
  echo FOR DJF MONTHLY FILES
  echo ' '
  if ($cntl_begin >= 1) then    # so we don t get a negative number
    @ cnt = $cntl_begin
    @ cnt--
    set yearnum = ${conv_cntl}`printf "%04d" ${cnt}`
  else
    echo ERROR: FIRST YEAR OF CNTL DATA $cntl_begin MUST BE GT ZERO
    exit
  endif    
  if (! -e ${cntl_path_history}${yearnum}-12.nc ) then    # dec of previous year
#   echo ${cntl_path_history}${yearnum}-12.nc NOT FOUND
#   check for Jan, Feb of the year following the last year
    @ next_year = $cntl_begin + $cntl_nyrs
    set yearnum = ${conv_cntl}`printf "%04d" ${next_year}`
#   echo 'CHECKING FOR '${cntl_path_history}${yearnum}-01.nc
    if (! -e ${cntl_path_history}${yearnum}-01.nc || -z ${cntl_path_history}${yearnum}-01.nc) then
      echo ERROR: ${cntl_path_history}${yearnum}-01.nc NOT FOUND
      echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
      exit
    endif
#   echo 'CHECKING FOR '${cntl_path_history}${yearnum}-02.nc
    if (! -e ${cntl_path_history}${yearnum}-02.nc || -z ${cntl_path_history}${yearnum}-02.nc) then
      echo ERROR: ${cntl_path_history}${yearnum}-02.nc NOT FOUND
      echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
      exit
    endif
    @ yr_cnt = $cntl_begin + 1
    @ yr_end = $cntl_begin + $cntl_nyrs     
    while ( $yr_cnt <= $yr_end )               # loop over years
      @ prev_yr = $yr_cnt - 1
      set dec = ${conv_cntl}`printf "%04d" ${prev_yr}`-12
      if (! -e ${cntl_path_history}${dec}.nc || -z ${cntl_path_history}${dec}.nc) then
        echo ERROR: ${cntl_path_history}${dec}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
        exit
      endif                 
      foreach month (01 02)
        set filename = ${conv_cntl}`printf "%04d" ${yr_cnt}`-${month}     
#       echo  'CHECKING FOR '${cntl_path_history}${filename}.nc
	if (! -e ${cntl_path_history}${filename}.nc || -z ${cntl_path_history}${filename}.nc) then      #file does not exist
          echo ERROR: ${cntl_path_history}${filename}.nc NOT FOUND
          echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
          exit
        endif
      end
      @ yr_cnt++
    end    
    set cntl_djf = NEXT      # use Jan, Feb of year after last year 
  else
#   echo ${cntl_path_history}${yearnum}-12.nc FOUND
    @ yr_cnt = $cntl_begin
    @ yr_end = $cntl_begin + $cntl_nyrs - 1
    while ( $yr_cnt <= $yr_end )               # loop over years
      @ prev_yr = $yr_cnt - 1
      set dec = ${conv_cntl}`printf "%04d" ${prev_yr}`-12
      if (! -e ${cntl_path_history}${dec}.nc || -z ${cntl_path_history}${dec}.nc) then
        echo ERROR: ${cntl_path_history}${dec}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
        exit
      endif                 
      foreach month (01 02)
        set filename = ${conv_cntl}`printf "%04d" ${yr_cnt}`-${month}     
#       echo  'CHECKING FOR '${cntl_path_history}${filename}.nc
	if (! -e ${cntl_path_history}${filename}.nc || -z ${cntl_path_history}${filename}.nc) then      #file does not exist
          echo ERROR: ${cntl_path_history}${filename}.nc NOT FOUND
          echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
          exit
        endif
      end
      @ yr_cnt++
    end
    set cntl_djf = PREV      # use Dec of year before first year
  endif
  echo '-->ALL' ${cntl_casename} DJF FILES FOUND
  echo ' '
endif

# -----------------------------------------------------------------
# nanr 2apr10 beg MAM ---------------------------------------------
# -----------------------------------------------------------------

if ($cntl_MAM_climo == 0) then
  echo CHECKING $cntl_path_history
  echo FOR MAM MONTHLY FILES
  echo ' '
  @ yr_cnt = $cntl_begin
  @ yr_end = $cntl_begin + $cntl_nyrs - 1
  while ( $yr_cnt <= $yr_end )               # loop over years             
    foreach month (03 04 05)
      set filename = ${conv_cntl}`printf "%04d" ${yr_cnt}`-${month}
#     echo  'CHECKING FOR '${cntl_path_history}${filename}.nc
      if (! -e ${cntl_path_history}${filename}.nc || -z ${cntl_path_history}${filename}.nc) then      #file does not exist
        echo ERROR: ${cntl_path_history}${filename}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
        exit
      endif
    end
    @ yr_cnt++
  end
  echo '-->ALL' ${cntl_casename} MAM FILES FOUND
  echo ' '
endif

# -----------------------------------------------------------------
# nanr 2apr10 end MAM ---------------------------------------------
# -----------------------------------------------------------------

if ($cntl_JJA_climo == 0) then
  echo CHECKING $cntl_path_history 
  echo FOR JJA MONTHLY FILES
  echo ' '
  @ yr_cnt = $cntl_begin 
  @ yr_end = $cntl_begin + $cntl_nyrs - 1   
  while ( $yr_cnt <= $yr_end )               # loop over years             
    foreach month (06 07 08)
      set filename = ${conv_cntl}`printf "%04d" ${yr_cnt}`-${month}     
#     echo  'CHECKING FOR '${cntl_path_history}${filename}.nc
      if (! -e ${cntl_path_history}${filename}.nc || -z ${cntl_path_history}${filename}.nc) then      #file does not exist
        echo ERROR: ${cntl_path_history}${filename}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
        exit
      endif
    end
    @ yr_cnt++
  end 
  echo '-->ALL' ${cntl_casename} JJA FILES FOUND
  echo ' '     
endif 
# -----------------------------------------------------------------
# nanr 2apr10 beg SON ---------------------------------------------
# -----------------------------------------------------------------
if ($cntl_SON_climo == 0) then
  echo CHECKING $cntl_path_history
  echo FOR SON MONTHLY FILES
  echo ' '
  @ yr_cnt = $cntl_begin
  @ yr_end = $cntl_begin + $cntl_nyrs - 1
  while ( $yr_cnt <= $yr_end )               # loop over years             
    foreach month (09 10 11)
      set filename = ${conv_cntl}`printf "%04d" ${yr_cnt}`-${month}
#     echo  'CHECKING FOR '${cntl_path_history}${filename}.nc
      if (! -e ${cntl_path_history}${filename}.nc || -z ${cntl_path_history}${filename}.nc) then      #file does not exist
        echo ERROR: ${cntl_path_history}${filename}.nc NOT FOUND
        echo ERROR: NEEDED MONTHLY FILES NOT IN $cntl_path_history
        exit
      endif
    end
    @ yr_cnt++
  end
  echo '-->ALL' ${cntl_casename} SON FILES FOUND
  echo ' '
endif

CALC_STATS:
echo "SWIFT:" $use_swift
#***************************************************************

#***************************************************************

if ($use_swift == 0) then  # beginning of use_swift branch

#***************************************************************

#***************************************************************


  set mydir = `pwd`

  #---------------------------------------------------------------
  # Determine how to deal with the DJF season for the test dataset
  #---------------------------------------------------------------
  @ cnt = $test_begin
  @ cnt --
  set yearnum = ${conv_test}`printf "%04d" ${cnt}`
  if (! -e ${test_path_history}${yearnum}-12.nc ) then    # dec of previous year
     set test_djf = "NEXT"
  else
     set test_djf = "PREV"
  endif
  echo 'test_djf: ' $test_djf

 #--------------------------------------------------------------
 # Determine which plots need to be drawn
 #--------------------------------------------------------------
  echo 'four_seasons: ' $four_seasons
  echo 'plot_ANN_climo: ' $plot_ANN_climo
  echo 'plot_DJF_climo: ' $plot_DJF_climo
  echo 'plot_JJA_climo: ' $plot_JJA_climo
  echo 'plot_MAM_climo: ' $plot_MAM_climo
  echo 'plot_SON_climo: ' $plot_SON_climo
  if ($four_seasons == 0) then
        set plots = "ANN,DJF,MAM,JJA,SON"
  else
     if ($plot_ANN_climo == 0 && \
         $plot_DJF_climo == 0 && \
         $plot_JJA_climo == 1 && \
         $plot_MAM_climo == 1 && \
         $plot_SON_climo == 1) then
         set plots = "ANN,DJF"
     endif
     if ($plot_ANN_climo == 0 && \
         $plot_DJF_climo == 1 && \
         $plot_JJA_climo == 1 && \
         $plot_MAM_climo == 0 && \
         $plot_SON_climo == 1) then
         set plots = "ANN,MAM"
     endif
     if ($plot_ANN_climo == 0 && \
         $plot_DJF_climo == 1 && \
         $plot_JJA_climo == 0 && \
         $plot_MAM_climo == 1 && \
         $plot_SON_climo == 1) then
         set plots = "ANN,JJA"
     endif
     if ($plot_ANN_climo == 0 && \
         $plot_DJF_climo == 1 && \
         $plot_JJA_climo == 1 && \
         $plot_MAM_climo == 1 && \
         $plot_SON_climo == 0) then
         set plots = "ANN,SON"
     endif
     if ($plot_ANN_climo == 0 && \
         $plot_DJF_climo == 0 && \
         $plot_JJA_climo == 0 && \
         $plot_MAM_climo == 1 && \
         $plot_SON_climo == 1) then
         set plots = "ANN,DJF,JJA"
     endif
     if ($plot_ANN_climo == 1 && \
         $plot_DJF_climo == 0 && \
         $plot_JJA_climo == 0 && \
         $plot_MAM_climo == 1 && \
         $plot_SON_climo == 1) then
         set plots = "DJF,JJA"
     endif
     if ($plot_ANN_climo == 0 && \
         $plot_DJF_climo == 1 && \
         $plot_JJA_climo == 1 && \
         $plot_MAM_climo == 0 && \
         $plot_SON_climo == 0) then
         set plots = "ANN,MAM,SON"
     endif
     if ($plot_ANN_climo == 1 && \
         $plot_DJF_climo == 1 && \
         $plot_JJA_climo == 1 && \
         $plot_MAM_climo == 0 && \
         $plot_SON_climo == 0) then
         set plots = "MAM,SON"
     endif
     if ($plot_ANN_climo == 1 && \
         $plot_DJF_climo == 0 && \
         $plot_JJA_climo == 0 && \
         $plot_MAM_climo == 0 && \
         $plot_SON_climo == 0) then
         set plots = "DJF,MAM,JJA,SON"
     endif
     if ($plot_ANN_climo == 0 && \
         $plot_DJF_climo == 1 && \
         $plot_JJA_climo == 1 && \
         $plot_MAM_climo == 1 && \
         $plot_SON_climo == 1) then
         set plots = "ANN"
     endif
  endif
#****************************************************************
# For SET 12 - Create the station_ids file
#***************************************************************
if ($all_sets == 0 || $set_12 == 0 || $set_12 == 2) then
if (-e ${test_path_diag}station_ids) then
 \rm ${test_path_diag}station_ids
endif
if ($set_12 == 2) then    # all stations
  echo 56 >> ${WKDIR}station_ids
else
  if ($ascension_island == 0) then
    echo 0 >> ${WKDIR}station_ids
  endif
  if ($diego_garcia == 0) then
    echo 1 >> ${WKDIR}station_ids
  endif
  if ($truk_island == 0) then
    echo 2 >> ${WKDIR}station_ids
  endif
  if ($western_europe == 0) then
    echo 3 >> ${WKDIR}station_ids
  endif
  if ($ethiopia == 0) then
    echo 4 >> ${WKDIR}station_ids
  endif
  if ($resolute_canada == 0) then
    echo 5 >> ${WKDIR}station_ids
  endif
  if ($w_desert_australia == 0) then
    echo 6 >> ${WKDIR}station_ids
  endif
  if ($great_plains_usa == 0) then
    echo 7 >> ${WKDIR}station_ids
  endif
  if ($central_india == 0) then
    echo 8 >> ${WKDIR}station_ids
  endif
  if ($marshall_islands == 0) then
    echo 9 >> ${WKDIR}station_ids
  endif
  if ($easter_island == 0) then
    echo 10 >> ${WKDIR}station_ids
  endif
  if ($mcmurdo_antarctica == 0) then
    echo 11 >> ${WKDIR}station_ids
  endif
# skipped south pole antarctica - 12
  if ($panama == 0) then
    echo 13 >> ${WKDIR}station_ids
  endif
  if ($w_north_atlantic == 0) then
    echo 14 >> ${WKDIR}station_ids
  endif
  if ($singapore == 0) then
    echo 15 >> ${WKDIR}station_ids
  endif
  if ($manila == 0) then
    echo 16 >> ${WKDIR}station_ids
  endif
  if ($gilbert_islands == 0) then
    echo 17 >> ${WKDIR}station_ids
  endif
  if ($hawaii == 0) then
    echo 18 >> ${WKDIR}station_ids
  endif
  if ($san_paulo_brazil == 0) then
    echo 19 >> ${WKDIR}station_ids
  endif
  if ($heard_island == 0) then
    echo 20 >> ${WKDIR}station_ids
  endif
  if ($kagoshima_japan == 0) then
    echo 21 >> ${WKDIR}station_ids
  endif
  if ($port_moresby == 0) then
    echo 22 >> ${WKDIR}station_ids
  endif
  if ($san_juan_pr == 0) then
    echo 23 >> ${WKDIR}station_ids
  endif
  if ($western_alaska == 0) then
    echo 24 >> ${WKDIR}station_ids
  endif
  if ($thule_greenland == 0) then
    echo 25 >> ${WKDIR}station_ids
  endif
  if ($san_francisco_ca == 0) then
    echo 26 >> ${WKDIR}station_ids
  endif
  if ($denver_colorado == 0) then
    echo 27 >> ${WKDIR}station_ids
  endif
  if ($london_england == 0) then
    echo 28 >> ${WKDIR}station_ids
  endif
  if ($crete == 0) then
    echo 29 >> ${WKDIR}station_ids
  endif
  if ($tokyo_japan == 0) then
    echo 30 >> ${WKDIR}station_ids
  endif
  if ($sydney_australia == 0) then
    echo 31 >> ${WKDIR}station_ids
  endif
  if ($christchurch_nz == 0) then
    echo 32 >> ${WKDIR}station_ids
  endif
  if ($lima_peru == 0) then
    echo 33 >> ${WKDIR}station_ids
  endif
  if ($miami_florida == 0) then
    echo 34 >> ${WKDIR}station_ids
  endif
  if ($samoa == 0) then
    echo 35 >> ${WKDIR}station_ids
  endif
  if ($shipP_gulf_alaska == 0) then
    echo 36 >> ${WKDIR}station_ids
  endif
  if ($shipC_n_atlantic == 0) then
    echo 37 >> ${WKDIR}station_ids
  endif
  if ($azores == 0) then
    echo 38 >> ${WKDIR}station_ids
  endif
  if ($new_york_usa == 0) then
    echo 39 >> ${WKDIR}station_ids
  endif
  if ($darwin_australia == 0) then
    echo 40 >> ${WKDIR}station_ids
  endif
  if ($christmas_island == 0) then
    echo 41 >> ${WKDIR}station_ids
  endif
  if ($cocos_islands == 0) then
    echo 42 >> ${WKDIR}station_ids
  endif
  if ($midway_island == 0) then
    echo 43 >> ${WKDIR}station_ids
  endif
  if ($raoui_island == 0) then
    echo 44 >> ${WKDIR}station_ids
  endif
  if ($whitehorse_canada == 0) then
    echo 45 >> ${WKDIR}station_ids
  endif
  if ($oklahoma_city_ok == 0) then
    echo 46 >> ${WKDIR}station_ids
  endif
  if ($gibraltor == 0) then
    echo 47 >> ${WKDIR}station_ids
  endif
  if ($mexico_city == 0) then
    echo 48 >> ${WKDIR}station_ids
  endif
  if ($recife_brazil == 0) then
    echo 49 >> ${WKDIR}station_ids
  endif
  if ($nairobi_kenya == 0) then
    echo 50 >> ${WKDIR}station_ids
  endif
  if ($new_dehli_india == 0) then
    echo 51 >> ${WKDIR}station_ids
  endif
  if ($madras_india == 0) then
    echo 52 >> ${WKDIR}station_ids
  endif
  if ($danang_vietnam == 0) then
    echo 53 >> ${WKDIR}station_ids
  endif
  if ($yap_island == 0) then
    echo 54 >> ${WKDIR}station_ids
  endif
  if ($falkland_islands == 0) then
    echo 55 >> ${WKDIR}station_ids
  endif
endif
endif

#***************************************************************
# Setup webpages and make tar file
if ($web_pages == 0) then
  setenv DENSITY $density
  if ($img_type == 0) then
    set image = png
  else
    if ($img_type == 1) then
      set image = gif
    else
      set image = jpg
    endif
  endif
  if ($p_type != ps) then
    echo ERROR: WEBPAGES ARE ONLY MADE FOR POSTSCRIPT PLOT TYPE
    exit
  endif
  if ($CNTL == OBS) then
    setenv WEBDIR ${WKDIR}${test_casename}-obs_${test_period}
    if (! -e $WEBDIR) mkdir $WEBDIR
    cd $WEBDIR
    $HTML_HOME/setup_obs ${test_casename} $image
    cd $WKDIR
    set tarfile = ${test_casename}-obs_${test_period}.tar
  else          # model-to-model 
    setenv WEBDIR ${WKDIR}${test_casename}_${test_period}_-_${cntl_casename}_${cntl_period}
    if (! -e $WEBDIR) mkdir $WEBDIR
    cd $WEBDIR
    $HTML_HOME/setup_2models ${test_casename} ${cntl_casename} $image
    cd $WKDIR
    set tarfile = ${test_casename}_${test_period}_-_${cntl_casename}_${cntl_period}.tar
  endif
endif

#---------------------------------------------------------
# If weight_months == 1, set variables to null
#---------------------------------------------------------
if ($weight_months == 1) then
  set non_time_vars = " "
  set strip_off_vars = 1
endif

#---------------------------------------------------------
# Set RGB_FILE to null if c_type == MONO 
#---------------------------------------------------------
if ($c_type != COLOR) then
   setenv RGB_FILE " "
endif
#----------------------------------------------------------
# Set the test_var_list to use if strip__off_vars is
# set to 0
#----------------------------------------------------------
set test_var_list = " "
if ($test_ANN_climo == 0 || $test_DJF_climo == 0 || $test_JJA_climo == 0 || $test_MON_climo == 0) then
  set filename = ${test_path_history}${conv_test}`printf "%04d" ${test_begin}`"-01.nc"
  set first_find = 1
  foreach var ($required_vars)
    ncks  -d lat,0 -d lon,0 -d lev,0 -v $var $filename > /dev/null
    if (! $status) then
      if ($first_find) then
        set test_var_list = $var
        set first_find=0
      else
        set test_var_list = ${test_var_list},$var
      endif
    endif
  end
endif
set cntl_var_list = " "
if ($cntl_ANN_climo == 0 || $cntl_DJF_climo == 0 || $cntl_JJA_climo == 0 || $cntl_MON_climo == 0) then
  set filename = ${cntl_path_history}${conv_cntl}`printf "%04d" ${cntl_begin}`"-01.nc"
  set first_find = 1
  foreach var ($required_vars)
    ncks  -d lat,0 -d lon,0 -d lev,0 -v $var $filename >& /dev/null
    if (! $status) then
      if ($first_find) then
        set cntl_var_list = $var
        set first_find=0
      else
        set cntl_var_list = ${cntl_var_list},$var
      endif
    endif
  end
endif
cd $mydir

  if($CNTL != "OBS" ) then
     #---------------------------------------------------------------
     # Determine how to deal with the DJF season for the cntl dataset
     #---------------------------------------------------------------
     @ cnt = $cntl_begin
     @ cnt --
     set yearnum = ${conv_cntl}`printf "%04d" ${cnt}`
     # echo ${cntl_path}${yearnum}-12.nc
     if (! -e ${cntl_path_history}${yearnum}-12.nc ) then    # dec of previous year
        set cntl_djf = "NEXT"
     else
        set cntl_djf = "PREV"
     endif
     echo 'cntl_djf: ' $cntl_djf


     #------------------------------------------
     # Comparsion between two different datasets
     #------------------------------------------

      echo PLOTS: $plots

       cd $swift_scratch_dir

       swift -config $mydir/cf.properties \
      -sites.file $mydir/sites.xml  -tc.file $mydir/tc.data -cdm.file $mydir/fs.data \
      $mydir/swift/amwg_stats.swift -workdir=${test_path_diag} -sig=$significance -test_inst=$test_inst -cntl_inst=$cntl_inst \
      -test_case=${test_casename} -test_djf=$test_djf -test_path=$test_path_history -test_nyrs=$test_nyrs -test_begin=$test_begin \
      -test_djf_climo=$test_DJF_climo -test_jja_climo=$test_JJA_climo -test_son_climo=$test_SON_climo -test_mam_climo=$test_MAM_climo \
      -test_ann_climo=$test_ANN_climo -test_mon_climo=$test_MON_climo -test_path_climo=$test_path_climo -cntl_path_climo=$cntl_path_climo \
      -cntl_case=${cntl_casename} -cntl_djf=$cntl_djf -cntl_path=$cntl_path_history -cntl_nyrs=$cntl_nyrs -cntl_begin=$cntl_begin \
      -cntl_djf_climo=$cntl_DJF_climo -cntl_jja_climo=$cntl_JJA_climo -cntl_son_climo=$cntl_SON_climo -cntl_mam_climo=$cntl_MAM_climo \
      -cntl_ann_climo=$cntl_ANN_climo -cntl_mon_climo=$cntl_MON_climo -plot_ANN_climo=$plot_ANN_climo -plot_DJF_climo=$plot_DJF_climo \
      -plot_JJA_climo=$plot_JJA_climo -plot_MON_climo=$plot_MON_climo -plot_MAM_climo=$plot_MAM_climo -plot_SON_climo=$plot_SON_climo \
      -all_sets=$all_sets -set_1=$set_1 -set_2=$set_2 -set_3=$set_3 -set_4=$set_4 -set_4a=$set_4a -set_5=$set_5 -set_6=$set_6 \
      -set_7=$set_7 -set_8=$set_8 -set_9=$set_9 -set_10=$set_10 -set_11=$set_11 -set_12=$set_12 -set_13=$set_13 -set_14=$set_14 \
      -set_15=$set_15 -cntl=$CNTL -obs_data=$OBS_DATA -custom_names=$custom_names -casenames=$CASENAMES -case1=$CASE1 -case2=$CASE2 \
      -diag_code=$DIAG_CODE  -plots=$plots -plot_type=$PLOTTYPE -version=$DIAG_VERSION -color_type=$COLORTYPE -time_stamp=$TIMESTAMP \
      -web_pages=$web_pages -imageType=$image -webdir=$WEBDIR -rgb_file=$RGB_FILE -mg_micro=$MG_MICRO -paleo=$PALEO -land_mask1=$land_mask1 \
      -land_mask2=$land_mask2 -tick_marks=$TICKMARKS -sig_plot=$SIG_PLOT -sig_lvl=$SIG_LVL -diffs=$DIFF_PLOTS -significance=$significance \
      -diaghome=${DIAG_HOME} -cam_data=$CAM35_DATA -cam_base=$TAYLOR_BASECASE -ncarg_root=$NCARG_ROOT -strip_off_vars=$strip_off_vars \
      -test_var_list=$test_var_list -cntl_var_list=$cntl_var_list -non_time_vars=$non_time_vars -weight_months=$weight_months \
      -save_ncdfs=$save_ncdfs -delete_ps=$DELETEPS -conv_test=$conv_test -conv_cntl=$conv_cntl

      set cntl_in = $cntl_out

      cd $mydir
   else

     echo 'Comparison against observations'
     #---------------------------------
     # Comparsion against observations
     #---------------------------------

       cd $swift_scratch_dir 

       swift -config $mydir/cf.properties \
      -sites.file $mydir/sites.xml  -tc.file $mydir/tc.data -cdm.file $mydir/fs.data \
      $mydir/swift/amwg_stats.swift -workdir=${test_path_diag} -sig=$significance -test_inst=$test_inst \
      -test_case=${test_casename} -test_djf=$test_djf -test_path=$test_path_history -test_nyrs=$test_nyrs -test_begin=$test_begin \
      -test_djf_climo=$test_DJF_climo -test_jja_climo=$test_JJA_climo -test_son_climo=$test_SON_climo -test_mam_climo=$test_MAM_climo \
      -test_ann_climo=$test_ANN_climo -test_mon_climo=$test_MON_climo -test_path_climo=$test_path_climo -plot_ANN_climo=$plot_ANN_climo \
      -plot_DJF_climo=$plot_DJF_climo \
      -plot_JJA_climo=$plot_JJA_climo -plot_MON_climo=$plot_MON_climo -plot_MAM_climo=$plot_MAM_climo -plot_SON_climo=$plot_SON_climo \
      -all_sets=$all_sets -set_1=$set_1 -set_2=$set_2 -set_3=$set_3 -set_4=$set_4 -set_4a=$set_4a -set_5=$set_5 -set_6=$set_6 \
      -set_7=$set_7 -set_8=$set_8 -set_9=$set_9 -set_10=$set_10 -set_11=$set_11 -set_12=$set_12 -set_13=$set_13 -set_14=$set_14 \
      -set_15=$set_15 -cntl=$CNTL -obs_data=$OBS_DATA -custom_names=$custom_names -casenames=$CASENAMES -case1=$CASE1 -case2=$CASE2 \
      -diag_code=$DIAG_CODE -plots=$plots -plots=$plots -plot_type=$PLOTTYPE -version=$DIAG_VERSION -color_type=$COLORTYPE -time_stamp=$TIMESTAMP \
      -web_pages=$web_pages -imageType=$image -webdir=$WEBDIR -rgb_file=$RGB_FILE -mg_micro=$MG_MICRO -paleo=$PALEO -land_mask1=$land_mask1 \
      -land_mask2=$land_mask2 -tick_marks=$TICKMARKS -sig_plot=$SIG_PLOT -sig_lvl=$SIG_LVL -diffs=$DIFF_PLOTS -significance=$significance \
      -diaghome=${DIAG_HOME} -cam_data=$CAM35_DATA -cam_base=$TAYLOR_BASECASE -ncarg_root=$NCARG_ROOT -strip_off_vars=$strip_off_vars \
      -test_var_list=$test_var_list -cntl_var_list=$cntl_var_list -non_time_vars=$non_time_vars -weight_months=$weight_months \
      -save_ncdfs=$save_ncdfs -delete_ps=$DELETEPS -conv_test=$conv_test -conv_cntl=$conv_cntl

      cd $mydir

   endif

   set test_in = $test_out

   rm -rf _concurrent
   rm -f ${test_path_diag}/*.tar
   rm -f $test_path_climo/dummy*

#***************************************************************
# Remove this next section when bug is fixed
#***************************************************************
if ($set_1 == 0) then
if ($web_pages == 0) then
  mv *.asc $WEBDIR/set1
endif
endif

else  
# -----------------------------------------------------------------
# nanr 2apr10 end SON ---------------------------------------------
# -----------------------------------------------------------------
#------------------------------------------------------------------------
# save unweighted variables
if ($weight_months == 0) then
  if ($test_ANN_climo == 0 || $test_MON_climo == 0 || $test_DJF_climo == 0) then
    set filename = ${conv_test}`printf "%04d" ${test_begin}`-01.nc
    ncks -C -O -v $non_time_vars ${test_path_history}${filename} ${test_path_climo}test_unweighted.nc
  else
    if ($test_JJA_climo == 0) then
      set filename = ${conv_test}`printf "%04d" ${test_begin}`-06.nc
      ncks -C -O -v $non_time_vars ${test_path_history}${filename} ${test_path_climo}test_unweighted.nc
    endif
  endif
endif
if ($CNTL != USER) goto TEST_ANN_AVE

#------------------------------------------------------------------------
# save unweighted variables
if ($weight_months == 0) then
  if ($cntl_ANN_climo == 0 || $cntl_MON_climo == 0 || $cntl_DJF_climo == 0) then
    set filename = ${conv_cntl}`printf "%04d" ${cntl_begin}`-01.nc
    ncks -C -O -v $non_time_vars ${cntl_path_history}${filename} ${cntl_path_climo}cntl_unweighted.nc
  else
    if ($cntl_MAM_climo == 0) then
      set filename = ${conv_cntl}`printf "%04d" ${cntl_begin}`-03.nc
      ncks -C -O -v $non_time_vars ${cntl_path_history}${filename} ${cntl_path_climo}cntl_unweighted.nc
    endif
    if ($cntl_JJA_climo == 0) then
      set filename = ${conv_cntl}`printf "%04d" ${cntl_begin}`-06.nc
      ncks -C -O -v $non_time_vars ${cntl_path_history}${filename} ${cntl_path_climo}cntl_unweighted.nc
    endif
    if ($cntl_SON_climo == 0) then
      set filename = ${conv_cntl}`printf "%04d" ${cntl_begin}`-09.nc
      ncks -C -O -v $non_time_vars ${cntl_path_history}${filename} ${cntl_path_climo}cntl_unweighted.nc
    endif
  endif
endif

#**********************************************************************
# COMPUTE CLIMATOLOGIES
#**********************************************************************
#  CALC TEST CASE WEIGHTED ANNUAL AVERAGES
#---------------------------------------------------------------------
TEST_ANN_AVE:
if ($test_ANN_climo == 1) goto CNTL_ANN_AVE

#+CAF
if ($test_ANN_climo == 0 || $test_DJF_climo == 0 || $test_JJA_climo == 0 || $test_MON_climo == 0) then 
  set filename = ${test_path_history}${conv_test}`printf "%04d" ${test_begin}`"-01.nc"
  set first_find = 1
  foreach var ($required_vars)
    ncks  -d lat,0 -d lon,0 -d lev,0 -v $var $filename > /dev/null 
    if (! $status) then
      if ($first_find) then
        set test_var_list = $var
        set first_find=0
      else
        set test_var_list = ${test_var_list},$var
      endif
    endif
  end
endif
#-CAF
echo COMPUTING TEST CASE ANNUAL AVERAGES
# average testcase files
@ yr_cnt = $test_begin
@ yr_end = $test_begin + $test_nyrs - 1  
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )               # loop over years
  set yr_prnt = ${conv_test}`printf "%04d" ${yr_cnt}`
  if (-e ${test_out}_${yr_prnt}_ANN.nc) then
    \rm -f ${test_out}_${yr_prnt}_ANN.nc
  endif
  ls ${test_path_history}${yr_prnt}*.nc > ${test_path_climo}monthly_files   
  set files = `cat ${test_path_climo}monthly_files`
  if ($weight_months == 0) then
# apply the weights to the monthly files
     foreach m (1 2 3 4 5 6 7 8 9 10 11 12)
     set DATE=`date`;
     set month = `printf "%02d" ${m}` 
        if (-z $files[$m]) then
           echo "ERROR - Empty file:"  $files[$m]
        else
           if ($strip_off_vars == 0) then
             ncflint -O -c -v $test_var_list -w $ann_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
          else    
             ncflint -O -C -x -v $non_time_vars -w $ann_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
           endif  
        endif
     end
# sum the weighted files to make the climo file
    ls ${test_path_climo}wgt_month.*.nc > ${test_path_climo}weighted_files
    set files = `cat ${test_path_climo}weighted_files`
    ncea -O -y ttl $files ${test_out}_${yr_prnt}_ANN.nc 
# append the needed non-time varying variables
    ncks -C -A -v $non_time_vars ${test_path_climo}test_unweighted.nc ${test_out}_${yr_prnt}_ANN.nc
    echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
  else
    ncea -O $files ${test_out}_${yr_prnt}_ANN.nc 
    echo ${yr_prnt}' TIME AVERAGE'
  endif
@ yr_cnt++
end 
# clean up
if ($weight_months == 0) then
  \rm -f ${test_path_climo}weighted_files
  \rm -f ${test_path_climo}wgt_month.*.nc
endif
\rm -f ${test_path_climo}monthly_files
echo ' '

#set DATE=`date`; echo 'ceh----------Date after: '$DATE

#--------------------------------------------------------
#   CALC TEST CASE ANNUAL CLIMATOLOGY 
#--------------------------------------------------------
echo COMPUTING TEST CASE CLIMO ANNUAL MEAN 
if ($test_nyrs == 1) then
  /bin/mv ${test_out}_${yr_prnt}_ANN.nc ${test_out}_ANN_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$test_begin ${test_out}_ANN_climo.nc
else
# use test case output files from previous step
  ls ${test_out}_*_ANN.nc > ${test_path_climo}annual_files
  set files = `cat ${test_path_climo}annual_files`
  ncea -O $files ${test_out}_ANN_climo.nc   
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${test_out}_ANN_climo.nc 
  if ($significance == 0) then
    ncrcat -O $files ${test_out}_ANN_means.nc
  endif 
  \rm -f ${test_out}*ANN.nc
  \rm -f ${test_path_climo}annual_files
endif
set test_in = $test_out
echo ' '
#-------------------------------------------------------
#  CALC CNTL CASE ANNUAL AVERAGES
#-------------------------------------------------------
CNTL_ANN_AVE:
if ($CNTL != USER) goto TEST_DJF_AVE

if ($cntl_ANN_climo == 1) goto TEST_DJF_AVE

#+CAF
if ($cntl_ANN_climo == 0 || $cntl_DJF_climo == 0 || $cntl_JJA_climo == 0 || $cntl_MON_climo == 0) then
  set filename = ${cntl_path_history}${conv_cntl}`printf "%04d" ${cntl_begin}`"-01.nc"
  set first_find = 1
  foreach var ($required_vars)
    ncks  -d lat,0 -d lon,0 -d lev,0 -v $var $filename >& /dev/null
    if (! $status) then
      if ($first_find) then
        set cntl_var_list = $var
        set first_find=0
      else
        set cntl_var_list = ${cntl_var_list},$var
      endif
    endif
  end
endif
#-CAF

echo COMPUTING CNTL CASE ANNUAL AVERAGES
# average cntl case files
@ yr_cnt = $cntl_begin
@ yr_end = $cntl_begin + $cntl_nyrs - 1  
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )               # loop over years
  set yr_prnt = ${conv_cntl}`printf "%04d" ${yr_cnt}`
  if (-e ${cntl_out}_${yr_prnt}_ANN.nc) then
    \rm -f ${cntl_out}_${yr_prnt}_ANN.nc
  endif
  ls ${cntl_path_history}${yr_prnt}*.nc > ${cntl_path_climo}monthly_files   
  set files = `cat ${cntl_path_climo}monthly_files`
# apply the weights to the monthly files
  if ($weight_months == 0) then
    foreach m (1 2 3 4 5 6 7 8 9 10 11 12)
      set month = `printf "%02d" ${m}`
      if (-z $files[$m]) then
        echo "ERROR - Empty file:"  $files[$m]
      else
         if ($strip_off_vars == 0) then
             ncflint -O -c -v $cntl_var_list -w $ann_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
          else    
             ncflint -O -C -x -v $non_time_vars -w $ann_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
           endif  
      endif
    end
# sum the weighted files to make the climo file
    ls ${cntl_path_climo}wgt_month.*.nc > ${cntl_path_climo}weighted_files
    set files = `cat ${cntl_path_climo}weighted_files`
    ncea -O -y ttl $files ${cntl_out}_${yr_prnt}_ANN.nc 
# append the needed non-time varying variables
    ncks -C -A -v $non_time_vars ${cntl_path_climo}cntl_unweighted.nc ${cntl_out}_${yr_prnt}_ANN.nc
    echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
  else
    ncea -O $files ${cntl_out}_${yr_prnt}_ANN.nc 
    echo ${yr_prnt}' TIME AVERAGE'
  endif
@ yr_cnt++
end 
# clean up
if ($weight_months == 0) then
  \rm -f ${cntl_path_climo}weighted_files
  \rm -f ${cntl_path_climo}wgt_month.*.nc
endif
\rm -f ${cntl_path_climo}monthly_files
echo ' '
#--------------------------------------------------------
#   CALC CNTL CASE ANNUAL CLIMATOLOGY 
#--------------------------------------------------------
echo COMPUTING CNTL CASE CLIMO ANNUAL MEAN 
if ($cntl_nyrs == 1) then
  /bin/mv ${cntl_out}_${yr_prnt}_ANN.nc ${cntl_out}_ANN_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$cntl_begin ${cntl_out}_ANN_climo.nc
else
# use cntl case output files from previous step
  ls ${cntl_out}_*_ANN.nc > ${cntl_path_climo}annual_files
  set files = `cat ${cntl_path_climo}annual_files`
  ncea -O $files ${cntl_out}_ANN_climo.nc   
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${cntl_out}_ANN_climo.nc 
  if ($significance == 0) then
    ncrcat -O $files ${cntl_out}_ANN_means.nc
  endif 
  \rm -f ${cntl_out}*ANN.nc
  \rm -f ${cntl_path_climo}annual_files
endif
set cntl_in = $cntl_out

#*********************************************************
# CALCULATE SEASONAL AVERAGES
#*********************************************************
# COMPUTE TEST CASE DJF AVERAGES
#--------------------------------------------------------
TEST_DJF_AVE:

if ($test_DJF_climo == 1) goto TEST_MAM_AVE 
echo COMPUTING TEST CASE DJF AVERAGES
@ yr_cnt = $test_begin
@ yr_end = $test_begin + $test_nyrs - 1 
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )
  set yr_prnt = ${conv_test}`printf "%04d" ${yr_cnt}`
  if ($yr_cnt >= 1) then
    if ($test_djf == PREV) then
      @ yr_cnt--
      set yr_last_prnt = ${conv_test}`printf "%04d" ${yr_cnt}`
      set dec = ${test_path_history}${yr_last_prnt}-12.nc
      set jan = ${test_path_history}${yr_prnt}-01.nc
      set feb = ${test_path_history}${yr_prnt}-02.nc
      @ yr_cnt++
    else
      @ yr_cnt++
      set yr_next_prnt = ${conv_test}`printf "%04d" ${yr_cnt}`
      set dec = ${test_path_history}${yr_prnt}-12.nc
      set jan = ${test_path_history}${yr_next_prnt}-01.nc
      set feb = ${test_path_history}${yr_next_prnt}-02.nc
      @ yr_cnt--
    endif
    if (-e ${test_out}_${yr_prnt}_DJF.nc) then
      \rm -f ${test_out}_${yr_prnt}_DJF.nc
    endif
    set files = ($dec $jan $feb)
    if ($weight_months == 0) then
#   apply the weights to the monthly files
      foreach m (1 2 3)
        set month = `printf "%02d" ${m}`
        if (-z $files[$m]) then 
          echo "ERROR - Empty file:"  $files[$m]
        else
           if ($strip_off_vars == 0) then
             ncflint -O -c -v $test_var_list -w $djf_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
          else    
             ncflint -O -C -x -v $non_time_vars -w $djf_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
           endif  
        endif
      end
#   sum the weighted files to make the climo file
      ls ${test_path_climo}wgt_month.*.nc > ${test_path_climo}weighted_files
      set files = `cat ${test_path_climo}weighted_files`
      ncea -O -y ttl $files ${test_out}_${yr_prnt}_DJF.nc 
#   append the needed non-time varying variables
      ncks -C -A -v $non_time_vars ${test_path_climo}test_unweighted.nc ${test_out}_${yr_prnt}_DJF.nc
      echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
    else
      ncea -O $files ${test_out}_${yr_prnt}_DJF.nc
      echo ${yr_prnt}' TIME AVERAGE'
    endif
  endif
  @ yr_cnt++               
end
# clean up
if ($weight_months == 0) then
  \rm -f ${test_path_climo}weighted_files
  \rm -f ${test_path_climo}wgt_month.*.nc
endif
echo ' '
#---------------------------------------------------------
#  COMPUTE TEST CASE DJF CLIMATOLOGY 
#---------------------------------------------------------
echo COMPUTING TEST CASE DJF CLIMO MEAN 
if ($test_nyrs == 1) then
  /bin/mv ${test_out}_${yr_prnt}_DJF.nc ${test_out}_DJF_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$test_begin ${test_out}_DJF_climo.nc
else
  ls ${test_out}_*_DJF.nc > ${test_path_climo}seasonal_files
  set files = `cat ${test_path_climo}seasonal_files`
  ncea -O $files ${test_out}_DJF_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${test_out}_DJF_climo.nc 
  if ($significance == 0) then
    ncrcat -O $files ${test_out}_DJF_means.nc
  endif 
  \rm -f ${test_out}*DJF.nc
  \rm -f ${test_path_climo}seasonal_files
endif
set test_in = $test_out
echo ' '

#-----------------------------------------------------------
# COMPUTE TEST CASE MAM AVERAGES
#-----------------------------------------------------------
TEST_MAM_AVE:
if ($test_MAM_climo == 1) goto TEST_JJA_AVE
echo COMPUTING TEST CASE MAM AVERAGES
@ yr_cnt = $test_begin
@ yr_end = $test_begin + $test_nyrs - 1
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )
  set yr_prnt = ${conv_test}`printf "%04d" ${yr_cnt}`
  if ($yr_cnt >= 1) then
    set mar = ${test_path_history}${yr_prnt}-03.nc
    set apr = ${test_path_history}${yr_prnt}-04.nc
    set may = ${test_path_history}${yr_prnt}-05.nc
    if (-e ${test_out}_${yr_prnt}_MAM.nc) then
      \rm -f ${test_out}_${yr_prnt}_MAM.nc
    endif
    set files = ($mar $apr $may)
    if ($weight_months == 0) then
#   apply the weights to the monthly files
      foreach m (1 2 3)
      set month = `printf "%02d" ${m}`
      if (-z $files[$m]) then
        echo "ERROR - Empty file:"  $files[$m]
      else
         if ($strip_off_vars == 0) then
             ncflint -O -c -v $test_var_list -w $mam_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
         else    
             ncflint -O -C -x -v $non_time_vars -w $mam_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
         endif
      endif
      end
#   sum the weighted files to make the climo file
      ls ${test_path_climo}wgt_month.*.nc > ${test_path_climo}weighted_files
      set files = `cat ${test_path_climo}weighted_files`
      ncea -O -y ttl $files ${test_out}_${yr_prnt}_MAM.nc
#   append the needed non-time varying variables
      ncks -C -A -v $non_time_vars ${test_path_climo}test_unweighted.nc ${test_out}_${yr_prnt}_MAM.nc
      echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
    else
      ncea -O $files ${test_out}_${yr_prnt}_MAM.nc
      echo ${yr_prnt}' TIME AVERAGE'
    endif
  endif
  @ yr_cnt++
end
# clean up
if ($weight_months == 0) then
  \rm -f ${test_path_climo}weighted_files
  \rm -f ${test_path_climo}wgt_month.*.nc
endif
echo ' '
#---------------------------------------------------------
#  COMPUTE TEST CASE MAM CLIMATOLOGY
#---------------------------------------------------------
echo COMPUTING TEST CASE MAM CLIMO MEAN
if ($test_nyrs == 1) then
  /bin/mv ${test_out}_${yr_prnt}_MAM.nc ${test_out}_MAM_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$test_begin ${test_out}_MAM_climo.nc
else 
  ls ${test_out}_*_MAM.nc > ${test_path_climo}seasonal_files
  set files = `cat ${test_path_climo}seasonal_files`
  ncea -O $files ${test_out}_MAM_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${test_out}_MAM_climo.nc
  if ($significance == 0) then
    ncrcat -O $files ${test_out}_MAM_means.nc
  endif
  \rm -f ${test_out}*MAM.nc
  \rm -f ${test_path_climo}seasonal_files
endif
set test_in = $test_out
echo ' '
#-----------------------------------------------------------
# COMPUTE TEST CASE JJA AVERAGES
#-----------------------------------------------------------
TEST_JJA_AVE:

if ($test_JJA_climo == 1) goto TEST_SON_AVE
echo COMPUTING TEST CASE JJA AVERAGES
@ yr_cnt = $test_begin
@ yr_end = $test_begin + $test_nyrs - 1 
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )
  set yr_prnt = ${conv_test}`printf "%04d" ${yr_cnt}`
  if ($yr_cnt >= 1) then
    set jun = ${test_path_history}${yr_prnt}-06.nc
    set jul = ${test_path_history}${yr_prnt}-07.nc
    set aug = ${test_path_history}${yr_prnt}-08.nc
    if (-e ${test_out}_${yr_prnt}_JJA.nc) then
      \rm -f ${test_out}_${yr_prnt}_JJA.nc
    endif
    set files = ($jun $jul $aug)
    if ($weight_months == 0) then
#   apply the weights to the monthly files
      foreach m (1 2 3)
        set month = `printf "%02d" ${m}`
        if (-z $files[$m]) then
          echo "ERROR - Empty file:"  $files[$m]
        else
           if ($strip_off_vars == 0) then
             ncflint -O -c -v $test_var_list -w $jja_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
           else    
             ncflint -O -C -x -v $non_time_vars -w $jja_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
           endif
        endif
      end
#   sum the weighted files to make the climo file
      ls ${test_path_climo}wgt_month.*.nc > ${test_path_climo}weighted_files
      set files = `cat ${test_path_climo}weighted_files`
      ncea -O -y ttl $files ${test_out}_${yr_prnt}_JJA.nc 
#   append the needed non-time varying variables
      ncks -C -A -v $non_time_vars ${test_path_climo}test_unweighted.nc ${test_out}_${yr_prnt}_JJA.nc
      echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
    else
      ncea -O $files ${test_out}_${yr_prnt}_JJA.nc
      echo ${yr_prnt}' TIME AVERAGE'
    endif
  endif
  @ yr_cnt++               
end
# clean up
if ($weight_months == 0) then
  \rm -f ${test_path_climo}weighted_files
  \rm -f ${test_path_climo}wgt_month.*.nc
endif
echo ' '
#---------------------------------------------------------
#  COMPUTE TEST CASE JJA CLIMATOLOGY 
#---------------------------------------------------------
echo COMPUTING TEST CASE JJA CLIMO MEAN 
if ($test_nyrs == 1) then
  /bin/mv ${test_out}_${yr_prnt}_JJA.nc ${test_out}_JJA_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$test_begin ${test_out}_JJA_climo.nc
else
  ls ${test_out}_*_JJA.nc > ${test_path_climo}seasonal_files 
  set files = `cat ${test_path_climo}seasonal_files`
  ncea -O $files ${test_out}_JJA_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${test_out}_JJA_climo.nc 
  if ($significance == 0) then
    ncrcat -O $files ${test_out}_JJA_means.nc
  endif 
  \rm -f ${test_out}*JJA.nc
  \rm -f ${test_path_climo}seasonal_files
endif
set test_in = $test_out
echo ' '
#-----------------------------------------------------------
#-----------------------------------------------------------
# COMPUTE TEST CASE SON AVERAGES
#-----------------------------------------------------------
TEST_SON_AVE:

if ($test_SON_climo == 1) goto CNTL_DJF_AVE
echo COMPUTING TEST CASE SON AVERAGES
@ yr_cnt = $test_begin
@ yr_end = $test_begin + $test_nyrs - 1
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )
  set yr_prnt = ${conv_test}`printf "%04d" ${yr_cnt}`
  if ($yr_cnt >= 1) then
    set sep = ${test_path_history}${yr_prnt}-09.nc
    set oct = ${test_path_history}${yr_prnt}-10.nc
    set nov = ${test_path_history}${yr_prnt}-11.nc
    if (-e ${test_out}_${yr_prnt}_SON.nc) then
      \rm -f ${test_out}_${yr_prnt}_SON.nc
    endif
    set files = ($sep $oct $nov)
    if ($weight_months == 0) then
#   apply the weights to the monthly files
      foreach m (1 2 3)
        set month = `printf "%02d" ${m}`
        if (-z $files[$m]) then
          echo "ERROR - Empty file:"  $files[$m]
        else
           if ($strip_off_vars == 0) then
             ncflint -O -c -v $test_var_list -w $son_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
           else    
             ncflint -O -C -x -v $non_time_vars -w $son_weights[$m],0.0 \
             $files[$m] $files[$m] ${test_path_climo}wgt_month.$month.nc
           endif
        endif
      end
#   sum the weighted files to make the climo file
      ls ${test_path_climo}wgt_month.*.nc > ${test_path_climo}weighted_files
      set files = `cat ${test_path_climo}weighted_files`
      ncea -O -y ttl $files ${test_out}_${yr_prnt}_SON.nc
#   append the needed non-time varying variables
      ncks -C -A -v $non_time_vars ${test_path_climo}test_unweighted.nc ${test_out}_${yr_prnt}_SON.nc
      echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
    else
      ncea -O $files ${test_out}_${yr_prnt}_SON.nc
      echo ${yr_prnt}' TIME AVERAGE'
    endif
  endif
  @ yr_cnt++
end
# clean up
if ($weight_months == 0) then
  \rm -f ${test_path_climo}weighted_files
  \rm -f ${test_path_climo}wgt_month.*.nc
endif

#---------------------------------------------------------
#  COMPUTE TEST CASE SON CLIMATOLOGY 
#---------------------------------------------------------
echo COMPUTING TEST CASE SON CLIMO MEAN
if ($test_nyrs == 1) then
  /bin/mv ${test_out}_${yr_prnt}_SON.nc ${test_out}_SON_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$test_begin ${test_out}_SON_climo.nc
else 
  ls ${test_out}_*_SON.nc > ${test_path_climo}seasonal_files
  set files = `cat ${test_path_climo}seasonal_files`
  ncea -O $files ${test_out}_SON_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${test_out}_SON_climo.nc
  if ($significance == 0) then
    ncrcat -O $files ${test_out}_SON_means.nc
  endif
  \rm -f ${test_out}*SON.nc
  \rm -f ${test_path_climo}seasonal_files
endif
set test_in = $test_out
echo ' '

#--------------------------------------------------------
# COMPUTE CNTL CASE DJF AVERAGES
#--------------------------------------------------------
CNTL_DJF_AVE:
if ($CNTL != USER) goto TEST_MON_AVE
if ($cntl_DJF_climo == 1) goto CNTL_MAM_AVE 
echo COMPUTING CNTL CASE DJF AVERAGES
@ yr_cnt = $cntl_begin
@ yr_end = $cntl_begin + $cntl_nyrs - 1 
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )
  set yr_prnt = ${conv_cntl}`printf "%04d" ${yr_cnt}`
  if ($yr_cnt >= 1) then
    if ($cntl_djf == PREV) then
      @ yr_cnt--
      set yr_last_prnt = ${conv_cntl}`printf "%04d" ${yr_cnt}`
      set dec = ${cntl_path_history}${yr_last_prnt}-12.nc
      set jan = ${cntl_path_history}${yr_prnt}-01.nc
      set feb = ${cntl_path_history}${yr_prnt}-02.nc
      @ yr_cnt++
    else
      @ yr_cnt++
      set yr_next_prnt = ${conv_cntl}`printf "%04d" ${yr_cnt}`
      set dec = ${cntl_path_history}${yr_prnt}-12.nc
      set jan = ${cntl_path_history}${yr_next_prnt}-01.nc
      set feb = ${cntl_path_history}${yr_next_prnt}-02.nc
      @ yr_cnt--
    endif
    if (-e ${cntl_out}_${yr_prnt}_DJF.nc) then
      \rm -f ${cntl_out}_${yr_prnt}_DJF.nc
    endif
    set files = ($dec $jan $feb)
    if ($weight_months == 0) then
#   apply the weights to the monthly files
      foreach m (1 2 3)
        set month = `printf "%02d" ${m}`
        if (-z $files[$m]) then
          echo "ERROR - Empty file:"  $files[$m]
        else
          if ($strip_off_vars == 0) then
             ncflint -O -c -v $cntl_var_list -w $djf_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
           else    
             ncflint -O -C -x -v $non_time_vars -w $djf_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
           endif
        endif
      end
#   sum the weighted files to make the climo file
      ls ${cntl_path_climo}wgt_month.*.nc > ${cntl_path_climo}weighted_files
      set files = `cat ${cntl_path_climo}weighted_files`
      ncea -O -y ttl $files ${cntl_out}_${yr_prnt}_DJF.nc 
#   append the needed non-time varying variables
      ncks -C -A -v $non_time_vars ${cntl_path_climo}cntl_unweighted.nc ${cntl_out}_${yr_prnt}_DJF.nc
      echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
    else
      ncea -O $files ${cntl_out}_${yr_prnt}_DJF.nc
      echo ${yr_prnt}' TIME AVERAGE'
    endif
  endif
  @ yr_cnt++               
end
# clean up
if ($weight_months == 0) then
  \rm -f ${cntl_path_climo}weighted_files
  \rm -f ${cntl_path_climo}wgt_month.*.nc
endif
echo ' '
#---------------------------------------------------------
#  COMPUTE CNTL CASE DJF CLIMATOLOGY 
#---------------------------------------------------------
echo COMPUTING CNTL CASE DJF CLIMO MEAN 
if ($cntl_nyrs == 1) then
  /bin/mv ${cntl_out}_${yr_prnt}_DJF.nc ${cntl_out}_DJF_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$cntl_begin ${cntl_out}_DJF_climo.nc
else
  ls ${cntl_out}_*_DJF.nc > ${cntl_path_climo}seasonal_files
  set files = `cat ${cntl_path_climo}seasonal_files`
  ncea -O $files ${cntl_out}_DJF_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${cntl_out}_DJF_climo.nc 
  if ($significance == 0) then
    ncrcat -O $files ${cntl_out}_DJF_means.nc
  endif 
  \rm -f ${cntl_out}*DJF.nc
  \rm -f ${cntl_path_climo}seasonal_files
endif
set cntl_in = $cntl_out
echo ' '

#-----------------------------------------------------------
# COMPUTE CNTL CASE MAM AVERAGES
#-----------------------------------------------------------
CNTL_MAM_AVE:
if ($cntl_MAM_climo == 1) goto CNTL_JJA_AVE
echo COMPUTING CNTL CASE MAM AVERAGES
@ yr_cnt = $cntl_begin
@ yr_end = $cntl_begin + $cntl_nyrs - 1
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )
  set yr_prnt = ${conv_cntl}`printf "%04d" ${yr_cnt}`
  if ($yr_cnt >= 1) then
    set mar = ${cntl_path_history}${yr_prnt}-03.nc
    set apr = ${cntl_path_history}${yr_prnt}-04.nc
    set may = ${cntl_path_history}${yr_prnt}-05.nc
    if (-e ${cntl_out}_${yr_prnt}_MAM.nc) then
      \rm -f ${cntl_out}_${yr_prnt}_MAM.nc
    endif
    set files = ($mar $apr $may)
    if ($weight_months == 0) then
#   apply the weights to the monthly files
      foreach m (1 2 3)
        set month = `printf "%02d" ${m}`
        if (-z $files[$m]) then
          echo "ERROR - Empty file:"  $files[$m]
        else
          if ($strip_off_vars == 0) then
             ncflint -O -c -v $cntl_var_list -w $mam_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
           else    
             ncflint -O -C -x -v $non_time_vars -w $mam_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
           endif
        endif
      end
#   sum the weighted files to make the climo file
      ls ${cntl_path_climo}wgt_month.*.nc > ${cntl_path_climo}weighted_files
      set files = `cat ${cntl_path_climo}weighted_files`
      ncea -O -y ttl $files ${cntl_out}_${yr_prnt}_MAM.nc
#   append the needed non-time varying variables
      ncks -C -A -v $non_time_vars ${cntl_path_climo}cntl_unweighted.nc ${cntl_out}_${yr_prnt}_MAM.nc
      echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
    else
      ncea -O $files ${cntl_out}_${yr_prnt}_MAM.nc
      echo ${yr_prnt}' TIME AVERAGE'
    endif
  endif
  @ yr_cnt++
end
# clean up
if ($weight_months == 0) then
  \rm -f ${cntl_path_climo}weighted_files
  \rm -f ${cntl_path_climo}wgt_month.*.nc
endif
echo ' '

#---------------------------------------------------------
#  COMPUTE CNTL CASE MAM CLIMATOLOGY
#---------------------------------------------------------
echo COMPUTING CNTL CASE MAM CLIMO MEAN
if ($cntl_nyrs == 1) then
  /bin/mv ${cntl_out}_${yr_prnt}_MAM.nc ${cntl_out}_MAM_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$cntl_begin ${cntl_out}_MAM_climo.nc
else
  ls ${cntl_out}_*_MAM.nc > ${cntl_path_climo}seasonal_files
  set files = `cat ${cntl_path_climo}seasonal_files`
  ncea -O $files ${cntl_out}_MAM_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${cntl_out}_MAM_climo.nc
  if ($significance == 0) then
    ncrcat -O $files ${cntl_out}_MAM_means.nc
  endif
  \rm -f ${cntl_out}*MAM.nc
  \rm -f ${cntl_path_climo}seasonal_files
endif
set cntl_in = $cntl_out
echo ' '


#-----------------------------------------------------------
# COMPUTE CNTL CASE JJA AVERAGES
#-----------------------------------------------------------
CNTL_JJA_AVE:
if ($cntl_JJA_climo == 1) goto CNTL_SON_AVE
echo COMPUTING CNTL CASE JJA AVERAGES
@ yr_cnt = $cntl_begin
@ yr_end = $cntl_begin + $cntl_nyrs - 1 
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )
  set yr_prnt = ${conv_cntl}`printf "%04d" ${yr_cnt}`
  if ($yr_cnt >= 1) then
    set jun = ${cntl_path_history}${yr_prnt}-06.nc
    set jul = ${cntl_path_history}${yr_prnt}-07.nc
    set aug = ${cntl_path_history}${yr_prnt}-08.nc
    if (-e ${cntl_out}_${yr_prnt}_JJA.nc) then
      \rm -f ${cntl_out}_${yr_prnt}_JJA.nc
    endif
    set files = ($jun $jul $aug)
    if ($weight_months == 0) then
#   apply the weights to the monthly files
      foreach m (1 2 3)
        set month = `printf "%02d" ${m}`
        if (-z $files[$m]) then
          echo "ERROR - Empty file:"  $files[$m]
        else
          if ($strip_off_vars == 0) then
             ncflint -O -c -v $cntl_var_list -w $jja_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
           else    
             ncflint -O -C -x -v $non_time_vars -w $jja_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
           endif
         endif  
      end
#   sum the weighted files to make the climo file
      ls ${cntl_path_climo}wgt_month.*.nc > ${cntl_path_climo}weighted_files
      set files = `cat ${cntl_path_climo}weighted_files`
      ncea -O -y ttl $files ${cntl_out}_${yr_prnt}_JJA.nc 
#   append the needed non-time varying variables
      ncks -C -A -v $non_time_vars ${cntl_path_climo}cntl_unweighted.nc ${cntl_out}_${yr_prnt}_JJA.nc
      echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
    else
      ncea -O $files ${cntl_out}_${yr_prnt}_JJA.nc
      echo ${yr_prnt}' TIME AVERAGE'
    endif
  endif
  @ yr_cnt++               
end
# clean up
if ($weight_months == 0) then
  \rm -f ${cntl_path_climo}weighted_files
  \rm -f ${cntl_path_climo}wgt_month.*.nc
endif
echo ' '
#---------------------------------------------------------
#  COMPUTE CNTL CASE JJA CLIMATOLOGY 
#---------------------------------------------------------
echo COMPUTING CNTL CASE JJA CLIMO MEAN 
if ($cntl_nyrs == 1) then
  /bin/mv ${cntl_out}_${yr_prnt}_JJA.nc ${cntl_out}_JJA_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$cntl_begin ${cntl_out}_JJA_climo.nc
else
  ls ${cntl_out}_*_JJA.nc > ${cntl_path_climo}seasonal_files 
  set files = `cat ${cntl_path_climo}seasonal_files`
  ncea -O $files ${cntl_out}_JJA_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${cntl_out}_JJA_climo.nc 
  if ($significance == 0) then
    ncrcat -O $files ${cntl_out}_JJA_means.nc
  endif 
  \rm -f ${cntl_out}*JJA.nc
  \rm -f ${cntl_path_climo}seasonal_files
endif
set cntl_in = $cntl_out
echo ' '

#-----------------------------------------------------------
# COMPUTE CNTL CASE SON AVERAGES
#-----------------------------------------------------------
CNTL_SON_AVE:
if ($cntl_SON_climo == 1) goto TEST_MON_AVE
echo COMPUTING CNTL CASE SON AVERAGES
@ yr_cnt = $cntl_begin
@ yr_end = $cntl_begin + $cntl_nyrs - 1
set ave_yrs = $yr_cnt-$yr_end
while ( $yr_cnt <= $yr_end )
  set yr_prnt = ${conv_cntl}`printf "%04d" ${yr_cnt}`
  if ($yr_cnt >= 1) then
    set sep = ${cntl_path_history}${yr_prnt}-09.nc
    set oct = ${cntl_path_history}${yr_prnt}-10.nc
    set nov = ${cntl_path_history}${yr_prnt}-11.nc
    if (-e ${cntl_out}_${yr_prnt}_SON.nc) then
      \rm -f ${cntl_out}_${yr_prnt}_SON.nc
    endif
    set files = ($sep $oct $nov)
    if ($weight_months == 0) then
#   apply the weights to the monthly files
      foreach m (1 2 3)
        set month = `printf "%02d" ${m}`
        if (-z $files[$m]) then
          echo "ERROR - Empty file:"  $files[$m]
        else
          if ($strip_off_vars == 0) then
             ncflint -O -c -v $cntl_var_list -w $son_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
           else    
             ncflint -O -C -x -v $non_time_vars -w $son_weights[$m],0.0 \
             $files[$m] $files[$m] ${cntl_path_climo}wgt_month.$month.nc
           endif 
        endif
      end
#   sum the weighted files to make the climo file
      ls ${cntl_path_climo}wgt_month.*.nc > ${cntl_path_climo}weighted_files
      set files = `cat ${cntl_path_climo}weighted_files`
      ncea -O -y ttl $files ${cntl_out}_${yr_prnt}_SON.nc
#   append the needed non-time varying variables
      ncks -C -A -v $non_time_vars ${cntl_path_climo}cntl_unweighted.nc ${cntl_out}_${yr_prnt}_SON.nc
      echo ${yr_prnt}' WEIGHTED TIME AVERAGE'
    else
      ncea -O $files ${cntl_out}_${yr_prnt}_SON.nc
      echo ${yr_prnt}' TIME AVERAGE'
    endif
  endif
  @ yr_cnt++
end
# clean up
if ($weight_months == 0) then
  \rm -f ${cntl_path_climo}weighted_files
  \rm -f ${cntl_path_climo}wgt_month.*.nc
endif
echo ' '
#---------------------------------------------------------
#  COMPUTE CNTL CASE SON CLIMATOLOGY 
#---------------------------------------------------------
echo COMPUTING CNTL CASE SON CLIMO MEAN
if ($cntl_nyrs == 1) then
  /bin/mv ${cntl_out}_${yr_prnt}_SON.nc ${cntl_out}_SON_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$cntl_begin ${cntl_out}_SON_climo.nc
else
  ls ${cntl_out}_*_SON.nc > ${cntl_path_climo}seasonal_files
  set files = `cat ${cntl_path_climo}seasonal_files`
  ncea -O $files ${cntl_out}_SON_climo.nc
  ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${cntl_out}_SON_climo.nc
  if ($significance == 0) then
    ncrcat -O $files ${cntl_out}_SON_means.nc
  endif
  \rm -f ${cntl_out}*SON.nc
  \rm -f ${cntl_path_climo}seasonal_files
endif
set cntl_in = $cntl_out
echo ' '

#*******************************************************************
#  CALC TEST CASE MONTHLY CLIMATOLOGY 
#*******************************************************************
TEST_MON_AVE:
if ($test_MON_climo == 1) goto CNTL_MON_AVE
echo COMPUTING TEST CASE CLIMO MONTHLY MEANS
if ($test_nyrs == 1) then
  set yr_prnt = ${conv_test}`printf "%04d" ${test_begin}`
  foreach x ($months)
    /bin/cp ${test_path_history}${yr_prnt}-${x}.nc ${test_out}_${x}_climo.nc 
    ncatted -O -a yrs_averaged,global,c,c,$test_begin ${test_out}_${x}_climo.nc
  end
else
  @ yr_end = $test_begin + $test_nyrs - 1 
  set ave_yrs = $test_begin-$yr_end
  foreach month ($months)
    @ yr_cnt = $test_begin
    while ( $yr_cnt <= $yr_end )
      set yr_prnt = ${conv_test}`printf "%04d" ${yr_cnt}`
      ls ${test_path_history}${yr_prnt}-${month}.nc >> ${test_path_climo}month_files  
      @ yr_cnt++
    end
    set files = `cat ${test_path_climo}month_files`
    ncea -O $files ${test_out}_${month}_climo.nc
    ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${test_out}_${month}_climo.nc
    \rm -f ${test_path_climo}month_files 
  end 
endif
set test_in = $test_out
echo ' '
#-----------------------------------------------------------------------
#  CALC CNTL CASE MONTHLY CLIMATOLOGY 
#-----------------------------------------------------------------------
CNTL_MON_AVE:
if ($CNTL != USER) goto CHECK_TEST
if ($cntl_MON_climo == 1) goto CHECK_TEST
echo COMPUTING CNTL CASE CLIMO MONTHLY MEANS
if ($cntl_nyrs == 1) then
  set yr_prnt = ${conv_cntl}`printf "%04d" ${cntl_begin}`
  foreach x ($months)
    /bin/cp ${cntl_path_history}${yr_prnt}-${x}.nc ${cntl_out}_${x}_climo.nc 
    ncatted -O -a yrs_averaged,global,c,c,$cntl_begin ${cntl_out}_${x}_climo.nc
  end
else
  @ yr_end = $cntl_begin + $cntl_nyrs - 1 
  set ave_yrs = $cntl_begin-$yr_end
  foreach month ($months)
    @ yr_cnt = $cntl_begin
    while ( $yr_cnt <= $yr_end )
      set yr_prnt = ${conv_cntl}`printf "%04d" ${yr_cnt}`
      ls ${cntl_path_history}${yr_prnt}-${month}.nc >> ${cntl_path_climo}month_files  
      @ yr_cnt++
    end
    set files = `cat ${cntl_path_climo}month_files`
    ncea -O $files ${cntl_out}_${month}_climo.nc
    ncatted -O -a yrs_averaged,global,c,c,$ave_yrs ${cntl_out}_${month}_climo.nc
    \rm -f ${cntl_path_climo}month_files 
  end 
endif
set cntl_in = $cntl_out

#**************************************************************
# test case climo files check always needed
#**************************************************************
CHECK_TEST:
if ($set_1 == 0 || $set_2 == 0 || $set_3 == 0 || $set_4 == 0 || $set_4a == 0 ||  \
    $set_5 == 0 || $set_6 == 0 || $set_7 == 0 || $all_sets == 0) then
  if ($set_2 == 0 || $all_sets == 0) then
    if ($plot_ANN_climo == 1) then 
      echo ' '
      echo ERROR: FOR SETS 2 YOU MUST SET plot_ANN_climo = 0
      exit
    endif
  endif 
  if ($plot_ANN_climo == 0) then
    if ($test_ANN_climo == 0) then           # were just computed
      echo CHECKING $test_path_climo FOR ANN CLIMO FILES
      if (! -e ${test_out}_ANN_climo.nc) then    
        echo ' '
        echo ERROR: ${test_out}_ANN_climo.nc NOT FOUND
        exit
      endif
    else                                     # already exist
      echo CHECKING $test_path_climo FOR ANN CLIMO FILES
      if (! -e ${test_in}_ANN_climo.nc) then    
        echo ' '
        echo ERROR: ${test_in}_ANN_climo.nc NOT FOUND
        exit
      endif
    endif
    if ($significance == 0) then
      echo CHECKING $test_path_climo FOR ANN MEANS FILE
      if (! -e ${test_out}_ANN_means.nc) then
        echo ' '
        echo ERROR: ${test_out}_ANN_means.nc NOT FOUND
        exit
      endif  
    endif
  endif
endif
if ($set_1 == 0 || $set_3 == 0 || $set_4 == 0 || $set_4a == 0 || $set_5 == 0 ||  \
    $set_6 == 0 || $set_7 == 0 || $set_9 == 0 || $all_sets == 0) then 
  if ($set_9 == 0 || $all_sets == 0) then
    if ($plot_DJF_climo == 1) then 
      echo ' '
      echo ERROR: FOR SET 9 YOU MUST SET plot_DJF_climo = 0
      echo "                         AND plot_JJA_climo = 0"
      exit
    endif
    if ($plot_JJA_climo == 1) then
      echo ' '
      echo ERROR: FOR SET 9 YOU MUST SET plot_JJA_climo = 0
      exit
    endif
    if ($plot_MAM_climo == 1 && $four_seasons == 0) then
      echo ' '
      echo ERROR: FOR SET 9 YOU MUST SET plot_MAM_climo = 0
      exit
    endif
    if ($plot_SON_climo == 1 && $four_seasons == 0) then
      echo ' '
      echo ERROR: FOR SET 9 YOU MUST SET plot_SON_climo = 0
      exit
    endif
  endif
  if ($plot_DJF_climo == 0) then
    if ($test_DJF_climo == 0) then       # were just computed
      echo CHECKING $test_path_climo FOR DJF CLIMO FILES
      if (! -e ${test_out}_DJF_climo.nc) then    
        echo ' '
        echo ERROR: ${test_out}_DJF_climo.nc NOT FOUND
        exit
      endif
    else                                # already exist
      echo CHECKING $test_path_climo FOR DJF CLIMO FILES
      if (! -e ${test_in}_DJF_climo.nc) then    
        echo ' '
        echo ERROR: ${test_in}_DJF_climo.nc NOT FOUND
        exit
      endif
    endif
    if ($significance == 0) then
      echo CHECKING $test_path_climo FOR DJF MEANS FILE
      if (! -e ${test_out}_DJF_means.nc) then
        echo ' '
        echo ERROR: ${test_out}_DJF_means.nc NOT FOUND
        exit
      endif  
    endif
  endif
  if ($plot_MAM_climo == 0) then
    if ($test_MAM_climo == 0) then        # were just computed
      echo CHECKING $test_path_climo FOR MAM CLIMO FILES
      if (! -e ${test_out}_MAM_climo.nc) then
        echo ' '
        echo ERROR: ${test_out}_MAM_climo.nc NOT FOUND
        exit
      endif
    else                                  # already exist
      echo CHECKING $test_path_climo FOR MAM CLIMO FILES
      if (! -e ${test_in}_MAM_climo.nc) then
        echo ' '
        echo ERROR: ${test_in}_MAM_climo.nc NOT FOUND
        exit
      endif
    endif
    if ($significance == 0) then
      echo CHECKING $test_path_climo FOR MAM MEANS FILE
      if (! -e ${test_out}_MAM_means.nc) then
        echo ' '
        echo ERROR: ${test_out}_MAM_means.nc NOT FOUND
        exit
      endif
    endif
  endif

  if ($plot_JJA_climo == 0) then
    if ($test_JJA_climo == 0) then        # were just computed
      echo CHECKING $test_path_climo FOR JJA CLIMO FILES
      if (! -e ${test_out}_JJA_climo.nc) then    
        echo ' '
        echo ERROR: ${test_out}_JJA_climo.nc NOT FOUND
        exit
      endif
    else                                  # already exist
      echo CHECKING $test_path_climo FOR JJA CLIMO FILES
      if (! -e ${test_in}_JJA_climo.nc) then    
        echo ' '
        echo ERROR: ${test_in}_JJA_climo.nc NOT FOUND
        exit
      endif
    endif
    if ($significance == 0) then
      echo CHECKING $test_path_climo FOR JJA MEANS FILE
      if (! -e ${test_out}_JJA_means.nc) then
        echo ' '
        echo ERROR: ${test_out}_JJA_means.nc NOT FOUND
        exit
      endif  
    endif
  endif

  if ($plot_SON_climo == 0) then
    if ($test_SON_climo == 0) then        # were just computed
      echo CHECKING $test_path_climo FOR SON CLIMO FILES
      if (! -e ${test_out}_SON_climo.nc) then
        echo ' '
        echo ERROR: ${test_out}_SON_climo.nc NOT FOUND
        exit
      endif
    else                                  # already exist
      echo CHECKING $test_path_climo FOR SON CLIMO FILES
      if (! -e ${test_in}_SON_climo.nc) then
        echo ' '
        echo ERROR: ${test_in}_SON_climo.nc NOT FOUND
        exit
      endif
    endif
    if ($significance == 0) then
      echo CHECKING $test_path_climo FOR SON MEANS FILE
      if (! -e ${test_out}_SON_means.nc) then
        echo ' '
        echo ERROR: ${test_out}_SON_means.nc NOT FOUND
        exit
      endif
    endif
  endif

endif  
if ($set_8 == 0 || $set_10 == 0 || $set_12 == 0 || $all_sets == 0) then
  if ($plot_MON_climo == 1) then
    echo ' '
    echo ERROR: FOR SETS 8,10,12 YOU MUST SET plot_MON_climo = 0
    exit
  endif 
  if ($plot_MON_climo == 0) then
    if ($test_MON_climo == 0) then        # were just computed
      echo CHECKING $test_path_climo FOR MONTHLY CLIMO FILES
      foreach month ($months)
        if (! -e ${test_out}_${month}_climo.nc) then 
          echo ' '
          echo ERROR: ${test_out}_${month}_climo.nc NOT FOUND
          exit
        endif
      end
    else                                  # already exist
      echo CHECKING $test_path_climo FOR MONTHLY CLIMO FILES
      foreach month ($months)
        if (! -e ${test_in}_${month}_climo.nc) then 
          echo ' '
          echo ERROR: ${test_in}_${month}_climo.nc NOT FOUND
          exit
        endif
      end
    endif
  endif
endif
# climatological files are present
echo '-->ALL NEEDED '${test_casename}' CLIMO AND/OR MEANS FILES FOUND'
echo ' '

#--------------------------------------------------------------------
# check for cntl case climo files if needed
#--------------------------------------------------------------------
if ($CNTL != USER) goto CHECK_SETS
# do checks for CNTL == USER

if ($plot_ANN_climo == 0) then
  if ($cntl_ANN_climo == 0) then        # were just computed
    echo CHECKING $cntl_path_climo FOR ANN CLIMO FILES
    if (! -e ${cntl_out}_ANN_climo.nc) then    
      echo ' '
      echo ERROR: ${cntl_out}_ANN_climo.nc NOT FOUND
      exit
    endif
  else                                  # already exist
    echo CHECKING $cntl_path_climo FOR ANN CLIMO FILES
    if (! -e ${cntl_in}_ANN_climo.nc) then    
      echo ' '
      echo ERROR: ${cntl_in}_ANN_climo.nc NOT FOUND
      exit
    endif
  endif
  if ($significance == 0) then
    echo CHECKING $cntl_path_climo FOR ANN MEANS FILE
    if (! -e ${cntl_out}_ANN_means.nc) then
      echo ' '
      echo ERROR: ${cntl_out}_ANN_means.nc NOT FOUND
      exit
    endif  
  endif
endif
if ($plot_DJF_climo == 0) then
  if ($cntl_DJF_climo == 0) then          # were just computed
    echo CHECKING $cntl_path_climo FOR DJF CLIMO FILES
    if (! -e ${cntl_out}_DJF_climo.nc) then    
      echo ' '
      echo ERROR: ${cntl_out}_DJF_climo.nc NOT FOUND
      exit
    endif
  else                                    # already exist
    echo CHECKING $cntl_path_climo FOR DJF CLIMO FILES
    if (! -e ${cntl_in}_DJF_climo.nc) then    
      echo ' '
      echo ERROR: ${cntl_in}_DJF_climo.nc NOT FOUND
      exit
    endif
  endif
  if ($significance == 0) then
    echo CHECKING $cntl_path_climo FOR DJF MEANS FILE
    if (! -e ${cntl_out}_DJF_means.nc) then
      echo ' '
      echo ERROR: ${cntl_out}_DJF_means.nc NOT FOUND
      exit
    endif  
  endif
endif
if ($plot_MAM_climo == 0) then
  if ($cntl_MAM_climo == 0) then         # were just computed
    echo CHECKING $cntl_path_climo FOR MAM CLIMO FILES
    if (! -e ${cntl_out}_MAM_climo.nc) then    
      echo ' '
      echo ERROR: ${cntl_out}_MAM_climo.nc NOT FOUND
      exit
    endif
  else                                  # already exist
    echo CHECKING $cntl_path_climo FOR MAM CLIMO FILES
    if (! -e ${cntl_in}_MAM_climo.nc) then    
      echo ' '
      echo ERROR: ${cntl_in}_MAM_climo.nc NOT FOUND
      exit
    endif
  endif
  if ($significance == 0) then
    echo CHECKING $cntl_path_climo FOR MAM MEANS FILE
    if (! -e ${cntl_out}_MAM_means.nc) then
      echo ' '
      echo ERROR: ${cntl_out}_MAM_means.nc NOT FOUND
      exit
    endif  
  endif
endif
if ($plot_JJA_climo == 0) then
  if ($cntl_JJA_climo == 0) then         # were just computed
    echo CHECKING $cntl_path_climo FOR JJA CLIMO FILES
    if (! -e ${cntl_out}_JJA_climo.nc) then    
      echo ' '
      echo ERROR: ${cntl_out}_JJA_climo.nc NOT FOUND
      exit
    endif
  else                                  # already exist
    echo CHECKING $cntl_path_climo FOR JJA CLIMO FILES
    if (! -e ${cntl_in}_JJA_climo.nc) then    
      echo ' '
      echo ERROR: ${cntl_in}_JJA_climo.nc NOT FOUND
      exit
    endif
  endif
  if ($significance == 0) then
    echo CHECKING $cntl_path_climo FOR JJA MEANS FILE
    if (! -e ${cntl_out}_JJA_means.nc) then
      echo ' '
      echo ERROR: ${cntl_out}_JJA_means.nc NOT FOUND
      exit
    endif  
  endif
endif
if ($plot_SON_climo == 0) then
  if ($cntl_SON_climo == 0) then         # were just computed
    echo CHECKING $cntl_path_climo FOR SON CLIMO FILES
    if (! -e ${cntl_out}_SON_climo.nc) then    
      echo ' '
      echo ERROR: ${cntl_out}_SON_climo.nc NOT FOUND
      exit    
    endif    
  else                                  # already exist
    echo CHECKING $cntl_path_climo FOR SON CLIMO FILES
    if (! -e ${cntl_in}_SON_climo.nc) then
      echo ' '
      echo ERROR: ${cntl_in}_SON_climo.nc NOT FOUND
      exit
    endif
  endif
  if ($significance == 0) then
    echo CHECKING $cntl_path_climo FOR SON MEANS FILE
    if (! -e ${cntl_out}_SON_means.nc) then
      echo ' '
      echo ERROR: ${cntl_out}_SON_means.nc NOT FOUND
      exit
    endif
  endif
endif
if ($plot_MON_climo == 0) then
  if ($cntl_MON_climo == 0) then        # were just computed
    echo CHECKING $cntl_path_climo FOR MONTHLY CLIMO FILES
    foreach month ($months)
      if (! -e ${cntl_out}_${month}_climo.nc) then 
        echo ${cntl_out}_${month}_climo.nc NOT FOUND
        echo ' '
        exit
      endif
    end
  else                                 # already exist
    echo CHECKING $cntl_path_climo FOR MONTHLY CLIMO FILES
    foreach month ($months)
      if (! -e ${cntl_in}_${month}_climo.nc) then 
        echo ${cntl_in}_${month}_climo.nc NOT FOUND
        echo ' '
        exit
      endif
    end
  endif
endif
# climatological files are present
echo '-->ALL NEEDED '${cntl_casename}' CLIMO AND/OR MEANS FILES FOUND'

#**************************************************************************
CHECK_SETS:
if ($set_1 == 1 && $set_2 == 1 && $set_3 == 1 && $set_4 == 1 && $set_4a == 1 && \
    $set_5 == 1 && $set_6 == 1 && $set_7 == 1 && $set_8 == 1 && \
    $set_9 == 1 && $set_10 == 1 && $set_11 == 1 && $set_12 &&  \
    $set_13 == 1 && $set_14 == 1 && $set_15 == 1 && $all_sets == 1) then
  echo ' '
  echo "NO DIAGNOSTIC SETS SELECTED (1-13)" 
  exit
endif
if ($set_1 == 0 || $set_3 == 0 || $set_4 == 0 || $set_4a == 0 || $set_5 == 0 || \
    $set_6 == 0 || $set_7 == 0 || $set_13 == 0) then
  if ($plot_ANN_climo == 1 &&  $plot_DJF_climo == 1 &&  \
      $plot_MAM_climo == 1 &&  $plot_SON_climo == 1 &&  \
      $plot_JJA_climo == 1) then
    echo ' '
    echo "ERROR: FOR SETS 1,3-7,13 SET AT LEAST ONE OF plot_(ANN,DJF,MAM,JJA,SON)_climo = 0" 
    exit
  endif
endif
#**************************************************************************
if ($plot_ANN_climo == 1 && $plot_DJF_climo == 1 && \
    $plot_SON_climo == 1 && $plot_MAM_climo == 1 && \
    $plot_JJA_climo == 1 && $plot_MON_climo == 1) then
  echo ' '
  echo "NO SELECTION MADE (ANN, MAM, JJA, SON, DJF, MON) FOR TABLES AND/OR PLOTS"
  exit
endif
if ($four_seasons == 0) then
    set plots = (ANN DJF MAM JJA SON)
else
   if ($plot_ANN_climo == 0 && \
       $plot_DJF_climo == 0 && \
       $plot_JJA_climo == 1 && \
       $plot_MAM_climo == 1 && \
       $plot_SON_climo == 1) then
       set plots = (ANN DJF)
   endif
   if ($plot_ANN_climo == 0 && \
       $plot_DJF_climo == 1 && \
       $plot_JJA_climo == 1 && \
       $plot_MAM_climo == 0 && \
       $plot_SON_climo == 1) then
       set plots = (ANN MAM)
   endif
   if ($plot_ANN_climo == 0 && \
       $plot_DJF_climo == 1 && \
       $plot_JJA_climo == 0 && \
       $plot_MAM_climo == 1 && \
       $plot_SON_climo == 1) then
       set plots = (ANN JJA)
   endif
   if ($plot_ANN_climo == 0 && \
       $plot_DJF_climo == 1 && \
       $plot_JJA_climo == 1 && \
       $plot_MAM_climo == 1 && \
       $plot_SON_climo == 0) then
       set plots = (ANN SON)
   endif
   if ($plot_ANN_climo == 0 && \
       $plot_DJF_climo == 0 && \
       $plot_JJA_climo == 0 && \
       $plot_MAM_climo == 1 && \
       $plot_SON_climo == 1) then
       set plots = (ANN DJF JJA)
   endif
   if ($plot_ANN_climo == 1 && \
       $plot_DJF_climo == 0 && \
       $plot_JJA_climo == 0 && \
       $plot_MAM_climo == 1 && \
       $plot_SON_climo == 1) then
       set plots = (DJF JJA)
   endif
   if ($plot_ANN_climo == 0 && \
       $plot_DJF_climo == 1 && \
       $plot_JJA_climo == 1 && \
       $plot_MAM_climo == 0 && \
       $plot_SON_climo == 0) then
       set plots = (ANN MAM SON)
   endif
   if ($plot_ANN_climo == 1 && \
       $plot_DJF_climo == 1 && \
       $plot_JJA_climo == 1 && \
       $plot_MAM_climo == 0 && \
       $plot_SON_climo == 0) then
       set plots = (MAM SON)
   endif
   if ($plot_ANN_climo == 1 && \
       $plot_DJF_climo == 0 && \
       $plot_JJA_climo == 0 && \
       $plot_MAM_climo == 0 && \
       $plot_SON_climo == 0) then
       set plots = (DJF MAM JJA SON)
   endif
   if ($plot_ANN_climo == 0 && \
       $plot_DJF_climo == 1 && \
       $plot_JJA_climo == 1 && \
       $plot_MAM_climo == 1 && \
       $plot_SON_climo == 1) then
       set plots = (ANN)
   endif
endif

#**********************************************************************
# check for plot variable files and delete them if present
foreach name (ANN DJF MAM JJA SON MONTHS)
  if (-e ${test_out}_${name}_plotvars.nc) then
    \rm -f ${test_out}_${name}_plotvars.nc
  endif
  if ($CNTL != OBS) then
    if (-e ${cntl_out}_${name}_plotvars.nc) then
      \rm -f ${cntl_out}_${name}_plotvars.nc
    endif
  endif
end
# initial mode is to create new netcdf files
setenv NCDF_MODE create
#***************************************************************
# Setup webpages and make tar file
if ($web_pages == 0) then
  setenv DENSITY $density
  if ($img_type == 0) then
    set image = png
  else
    if ($img_type == 1) then
      set image = gif
    else
      set image = jpg
    endif
  endif
  if ($p_type != ps) then
    echo ERROR: WEBPAGES ARE ONLY MADE FOR POSTSCRIPT PLOT TYPE
    exit
  endif
  if ($CNTL == OBS) then
    setenv WEBDIR ${test_path_diag}${test_casename}-obs_${test_period}
    if (! -e $WEBDIR) mkdir $WEBDIR
    cd $WEBDIR
    $HTML_HOME/setup_obs ${test_casename} $image
    cd ${test_path_diag}
    set tarfile = ${test_casename}-obs_${test_period}.tar
  else          # model-to-model 
    setenv WEBDIR ${test_path_diag}${test_casename}_${test_period}_-_${cntl_casename}_${cntl_period}
    if (! -e $WEBDIR) mkdir $WEBDIR
    cd $WEBDIR
    $HTML_HOME/setup_2models ${test_casename} ${cntl_casename} $image
    cd ${test_path_diag}
    set tarfile = ${test_casename}_${test_period}_-_${cntl_casename}_${cntl_period}.tar
  endif
endif

#****************************************************************
#   SET 1 - TABLES OF MEANS, DIFFS, RMSE
#****************************************************************
if ($all_sets == 1 && $set_1 == 1) goto SET_2
echo " "
echo SET 1 TABLES OF MEANS, DIFFS, RMSES

foreach name ($plots)
  setenv SEASON $name 
  setenv TEST_INPUT ${test_in}_${SEASON}_climo.nc
  setenv TEST_PLOTVARS ${test_out}_${SEASON}_plotvars.nc
  if ($CNTL == OBS) then 
    setenv CNTL_INPUT $OBS_DATA
  else
    setenv CNTL_INPUT ${cntl_in}_${SEASON}_climo.nc
    setenv CNTL_PLOTVARS ${cntl_out}_${SEASON}_plotvars.nc
  endif
  if (-e $TEST_PLOTVARS) then
    setenv NCDF_MODE write
  else
    setenv NCDF_MODE create
  endif
  echo MAKING $SEASON TABLES 
  $NCL <  $DIAG_CODE/tables.ncl
  if ($NCDF_MODE == create) then
    setenv NCDF_MODE write
  endif
end
if ($web_pages == 0) then
  mv *.asc $WEBDIR/set1
endif




#*****************************************************************
#   SET 2 - ANNUAL LINE PLOTS OF IMPLIED FLUXES
#*****************************************************************

SET_2:
if ($all_sets == 1 && $set_2 == 1) goto SET_3   
echo " "
echo SET 2 ANNUAL IMPLIED TRANSPORTS
setenv TEST_INPUT ${test_in}_ANN_climo.nc
setenv TEST_PLOTVARS ${test_out}_ANN_plotvars.nc
if ($CNTL == OBS) then
  setenv CNTL_INPUT $OBS_DATA
else
  setenv CNTL_INPUT ${cntl_in}_ANN_climo.nc
  setenv CNTL_PLOTVARS ${cntl_out}_ANN_plotvars.nc
endif
if (-e $TEST_PLOTVARS) then
  setenv NCDF_MODE write
else
  setenv NCDF_MODE create
endif

echo OCEAN FRESHWATER TRANSPORT 
$NCL < $DIAG_CODE/plot_oft.ncl

if ($NCDF_MODE == create) then
  setenv NCDF_MODE write
endif

echo OCEAN AND ATMOSPHERIC TRANSPORT
$NCL < $DIAG_CODE/plot_oaht.ncl

if ($NCDF_MODE == create) then
  setenv NCDF_MODE write
endif

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set2 $image &
endif





#*****************************************************************
#   SET 3 - ZONAL LINE PLOTS
#*****************************************************************
SET_3:
if ($all_sets == 1 && $set_3 == 1) goto SET_4
echo " "
echo SET 3 ZONAL LINE PLOTS

foreach name ($plots)
  setenv SEASON $name
  setenv TEST_INPUT ${test_in}_${SEASON}_climo.nc  
  setenv TEST_PLOTVARS ${test_out}_${SEASON}_plotvars.nc
  if ($CNTL == OBS) then
    setenv CNTL_INPUT $OBS_DATA 
  else
    setenv CNTL_INPUT ${cntl_in}_${SEASON}_climo.nc    
    setenv CNTL_PLOTVARS ${cntl_out}_${SEASON}_plotvars.nc
  endif
  if (-e $TEST_PLOTVARS) then
    setenv NCDF_MODE write
  else
    setenv NCDF_MODE create
  endif
  echo MAKING $SEASON PLOTS 
  $NCL < $DIAG_CODE/plot_zonal_lines.ncl
  if ($NCDF_MODE == create) then
    setenv NCDF_MODE write
  endif
end

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set3 $image &
endif
#*****************************************************************
#   SET 4 - LAT/PRESS CONTOUR PLOTS
#*****************************************************************
SET_4:
if ($all_sets == 1 && $set_4 == 1) goto SET_4a
echo " "
echo SET 4 VERTICAL CONTOUR PLOTS

foreach name ($plots)
  setenv SEASON $name 
  setenv TEST_INPUT ${test_in}_${SEASON}_climo.nc
  setenv TEST_PLOTVARS ${test_out}_${SEASON}_plotvars.nc
  if ($CNTL == OBS) then
    setenv CNTL_INPUT $OBS_DATA
  else
    setenv CNTL_INPUT ${cntl_in}_${SEASON}_climo.nc
    setenv CNTL_PLOTVARS ${cntl_out}_${SEASON}_plotvars.nc
  endif
  if (-e $TEST_PLOTVARS) then
    setenv NCDF_MODE write
  else
    setenv NCDF_MODE create
  endif
  echo MAKING $SEASON PLOTS 
  $NCL < $DIAG_CODE/plot_vertical_cons.ncl
  if ($NCDF_MODE == create) then
    setenv NCDF_MODE write
  endif
end

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set4 $image &
endif

#*****************************************************************
#   SET 4a - LON/PRESS CONTOUR PLOTS (10N-10S)
#*****************************************************************
SET_4a:
if ($all_sets == 1 && $set_4a == 1) goto SET_5
echo " "
echo SET 4a VERTICAL LON-PRESS CONTOUR PLOTS

foreach name ($plots)
  setenv SEASON $name 
  setenv TEST_INPUT ${test_in}_${SEASON}_climo.nc
  setenv TEST_PLOTVARS ${test_out}_${SEASON}_plotvars.nc
  if ($CNTL == OBS) then
    setenv CNTL_INPUT $OBS_DATA
  else
    setenv CNTL_INPUT ${cntl_in}_${SEASON}_climo.nc
    setenv CNTL_PLOTVARS ${cntl_out}_${SEASON}_plotvars.nc
  endif
  if (-e $TEST_PLOTVARS) then
    setenv NCDF_MODE write
  else
    setenv NCDF_MODE create
  endif
  echo MAKING $SEASON PLOTS 
  $NCL < $DIAG_CODE/plot_vertical_xz_cons.ncl
  if ($NCDF_MODE == create) then
    setenv NCDF_MODE write
  endif
end

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set4a $image &
endif


#****************************************************************
#   SET 5 - LAT/LONG CONTOUR PLOTS
#****************************************************************
SET_5:
if ($all_sets == 1 && $set_5 == 1) goto SET_6
echo " "
echo SET 5 LAT/LONG CONTOUR PLOTS 

if ($paleo == 0) then
  echo ' '
  setenv MODELFILE ${test_in}_ANN_climo.nc
  setenv LANDMASK $land_mask1
  if (-e ${test_in}.lines && -e ${test_in}.names) then
    echo TEST CASE COASTLINE DATA FOUND
    setenv PALEODATA $test_in
  else
    echo CREATING TEST CASE PALEOCLIMATE COASTLINE FILES 
    setenv PALEODATA $test_out
  endif
  $NCL < $DIAG_CODE/plot_paleo.ncl
  setenv PALEOCOAST1 $PALEODATA
  if ($CNTL == OBS) then
   setenv PALEOCOAST2 "null"
  endif
  if ($CNTL == USER) then
    echo ' '
    setenv MODELFILE ${cntl_in}_ANN_climo.nc
    setenv LANDMASK $land_mask2
    if (-e ${cntl_in}.lines && -e ${cntl_in}.names) then
      echo CNTL CASE COASTLINE DATA FOUND
      setenv PALEODATA $cntl_in
    else
      echo CREATING CNTL CASE PALEOCLIMATE COASTLINE FILES 
      setenv PALEODATA $cntl_out
    endif
    $NCL < $DIAG_CODE/plot_paleo.ncl
    setenv PALEOCOAST2 $PALEODATA 
  endif
endif

foreach name ($plots)
  setenv SEASON $name 
  setenv TEST_INPUT ${test_in}_${SEASON}_climo.nc
  setenv TEST_PLOTVARS ${test_out}_${SEASON}_plotvars.nc
  if ($CNTL == OBS) then
    setenv CNTL_INPUT $OBS_DATA
  else
    setenv CNTL_INPUT ${cntl_in}_${SEASON}_climo.nc
    setenv CNTL_PLOTVARS ${cntl_out}_${SEASON}_plotvars.nc
  endif
  if (-e $TEST_PLOTVARS) then
    setenv NCDF_MODE write
  else
    setenv NCDF_MODE create
  endif   
  if ($significance == 0) then
    setenv TEST_MEANS ${test_out}_${SEASON}_means.nc
    setenv TEST_VARIANCE ${test_out}_${SEASON}_variance.nc
    setenv CNTL_MEANS ${cntl_out}_${SEASON}_means.nc
    setenv CNTL_VARIANCE ${cntl_out}_${SEASON}_variance.nc
    if (-e $TEST_VARIANCE) then
      setenv VAR_MODE write
    else
      setenv VAR_MODE create
    endif  
  else
     setenv SIG_LVL null
     setenv TEST_MEANS null
     setenv TEST_VARIANCE null
     setenv CNTL_MEANS null
     setenv CNTL_VARIANCE null
     setenv VAR_MODE null
  endif
  echo MAKING $SEASON PLOTS
  $NCL < $DIAG_CODE/plot_surfaces_cons.ncl 
  if ($NCDF_MODE == create) then
    setenv NCDF_MODE write
  endif
  if ($significance == 0) then 
    if($VAR_MODE == create) then
      setenv VAR_MODE write
    endif
  endif
end

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set5 $image &
endif
#****************************************************************
#   SET 6 - LAT/LONG VECTOR PLOTS
#****************************************************************
SET_6:
if ($all_sets == 1 && $set_6 == 1) goto SET_7
echo " "
echo SET 6 LAT/LONG VECTOR PLOTS 

if ($paleo == 0) then
  echo ' '
  setenv MODELFILE ${test_in}_ANN_climo.nc
  setenv LANDMASK $land_mask1
  if (-e ${test_in}.lines && -e ${test_in}.names) then
    echo TEST CASE COASTLINE DATA FOUND
    setenv PALEODATA $test_in
  else
    echo CREATING TEST CASE PALEOCLIMATE COASTLINE FILES 
    setenv PALEODATA $test_out
  endif
  $NCL < $DIAG_CODE/plot_paleo.ncl
  setenv PALEOCOAST1 $PALEODATA
  if ($CNTL == USER) then
    echo ' '
    setenv MODELFILE ${cntl_in}_ANN_climo.nc
    setenv LANDMASK $land_mask2
    if (-e ${cntl_in}.lines && -e ${cntl_in}.names) then
      echo CNTL CASE COASTLINE DATA FOUND
      setenv PALEODATA $cntl_in
    else
      echo CREATING CNTL CASE PALEOCLIMATE COASTLINE FILES 
      setenv PALEODATA $cntl_out
    endif
    $NCL < $DIAG_CODE/plot_paleo.ncl
    setenv PALEOCOAST2 $PALEODATA 
  endif
endif

foreach name ($plots)
  setenv SEASON $name 
  setenv TEST_INPUT ${test_in}_${SEASON}_climo.nc
  setenv TEST_PLOTVARS ${test_out}_${SEASON}_plotvars.nc
  if ($CNTL == OBS) then
    setenv CNTL_INPUT $OBS_DATA
  else
    setenv CNTL_INPUT ${cntl_in}_${SEASON}_climo.nc
    setenv CNTL_PLOTVARS ${cntl_out}_${SEASON}_plotvars.nc
  endif
  if (-e $TEST_PLOTVARS) then
    setenv NCDF_MODE write
  else
    setenv NCDF_MODE create
  endif   
  echo MAKING $SEASON PLOTS 
  $NCL < $DIAG_CODE/plot_surfaces_vecs.ncl
  if ($NCDF_MODE == create) then
    setenv NCDF_MODE write
  endif
end

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set6 $image &
endif
#****************************************************************
#   SET 7 - POLAR CONTOUR AND VECTOR PLOTS
#****************************************************************
SET_7:
if ($all_sets == 1 && $set_7 == 1) goto SET_8
echo " "
echo SET 7 POLAR CONTOUR AND VECTOR PLOTS 

if ($paleo == 0) then
  echo ' '
  setenv MODELFILE ${test_in}_ANN_climo.nc
  setenv LANDMASK $land_mask1
  if (-e ${test_in}.lines && -e ${test_in}.names) then
    echo TEST CASE COASTLINE DATA FOUND
    setenv PALEODATA $test_in
  else
    echo CREATING TEST CASE PALEOCLIMATE COASTLINE FILES 
    setenv PALEODATA $test_out
  endif
  $NCL < $DIAG_CODE/plot_paleo.ncl
  setenv PALEOCOAST1 $PALEODATA
  if ($CNTL == USER) then
    echo ' '
    setenv MODELFILE ${cntl_in}_ANN_climo.nc
    setenv LANDMASK $land_mask2
    if (-e ${cntl_in}.lines && -e ${cntl_in}.names) then
      echo CNTL CASE COASTLINE DATA FOUND
      setenv PALEODATA $cntl_in
    else
      echo CREATING CNTL CASE PALEOCLIMATE COASTLINE FILES 
      setenv PALEODATA $cntl_out
    endif
    $NCL < $DIAG_CODE/plot_paleo.ncl
    setenv PALEOCOAST2 $PALEODATA 
  endif
endif

foreach name ($plots)
  setenv SEASON $name 
  setenv TEST_INPUT ${test_in}_${SEASON}_climo.nc
  setenv TEST_PLOTVARS ${test_out}_${SEASON}_plotvars.nc
  if ($CNTL == OBS) then
    setenv CNTL_INPUT $OBS_DATA
  else
    setenv CNTL_INPUT ${cntl_in}_${SEASON}_climo.nc
    setenv CNTL_PLOTVARS ${cntl_out}_${SEASON}_plotvars.nc
  endif
  if (-e $TEST_PLOTVARS) then
    setenv NCDF_MODE write
  else
    setenv NCDF_MODE create
  endif   
  if ($significance == 0) then
    setenv TEST_MEANS ${test_out}_${SEASON}_means.nc
    setenv TEST_VARIANCE ${test_out}_${SEASON}_variance.nc
    setenv CNTL_MEANS ${cntl_out}_${SEASON}_means.nc
    setenv CNTL_VARIANCE ${cntl_out}_${SEASON}_variance.nc
    if (-e $TEST_VARIANCE) then
      setenv VAR_MODE write
    else
      setenv VAR_MODE create
    endif   
  endif
  echo MAKING $SEASON PLOTS 
  $NCL < $DIAG_CODE/plot_polar_cons.ncl
  if ($NCDF_MODE == create) then
    setenv NCDF_MODE write
  endif
  if ($significance == 0) then 
    if($VAR_MODE == create) then
      setenv VAR_MODE write
    endif
  endif
  $NCL < $DIAG_CODE/plot_polar_vecs.ncl
  if ($NCDF_MODE == create) then
    setenv NCDF_MODE write
  endif
end

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set7 $image &
endif
#****************************************************************
#   SET 8 - ZONAL ANNUAL CYCLE PLOTS
#****************************************************************
SET_8:
if ($all_sets == 1 && $set_8 == 1) goto SET_9
echo " "
echo SET 8 ANNUAL CYCLE PLOTS 
setenv TEST_INPUT $test_in    # path/casename
setenv TEST_PLOTVARS ${test_out}_MONTHS_plotvars.nc
if ($CNTL == OBS) then
  setenv CNTL_INPUT $OBS_DATA
else
  setenv CNTL_INPUT $cntl_in       # path/casename
  setenv CNTL_PLOTVARS ${cntl_out}_MONTHS_plotvars.nc
endif
if (-e $TEST_PLOTVARS) then
  setenv NCDF_MODE write
else
  setenv NCDF_MODE create
endif
$NCL < $DIAG_CODE/plot_ann_cycle.ncl
if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set8 $image &
endif
#****************************************************************
#  SET 9 - DJF-JJA LAT/LONG PLOTS
#****************************************************************
SET_9:
if ($all_sets == 1 && $set_9 == 1) goto SET_10 
echo ' '
echo SET 9 DJF-JJA CONTOUR PLOTS
if ($paleo == 0) then
  setenv MODELFILE ${test_in}_ANN_climo.nc
  setenv LANDMASK $land_mask1
  if (-e ${test_in}.lines && -e ${test_in}.names) then
    echo TEST CASE COASTLINE DATA FOUND
    setenv PALEODATA $test_in
  if ($CNTL == OBS) then
    setenv PALEOCOAST2 "null"
  endif
  else
    echo CREATING TEST CASE PALEOCLIMATE COASTLINE FILES 
    setenv PALEODATA $test_out
  endif
  $NCL < $DIAG_CODE/plot_paleo.ncl
  setenv PALEOCOAST1 $PALEODATA
  if ($CNTL == USER) then
    echo ' '
    setenv MODELFILE ${cntl_in}_ANN_climo.nc
    setenv LANDMASK $land_mask2
    if (-e ${cntl_in}.lines && -e ${cntl_in}.names) then
      echo CNTL CASE COASTLINE DATA FOUND
      setenv PALEODATA $cntl_in
    else
      echo CREATING CNTL CASE PALEOCLIMATE COASTLINE FILES 
      setenv PALEODATA $cntl_out 
    endif
    $NCL < $DIAG_CODE/plot_paleo.ncl
    setenv PALEOCOAST2 $PALEODATA 
  endif
endif

echo MAKING PLOTS
setenv TEST_INPUT $test_in
setenv TEST_PLOTVARS $test_out
if ($CNTL == OBS) then
  setenv CNTL_INPUT $OBS_DATA
else
  setenv CNTL_INPUT $cntl_in
  setenv CNTL_PLOTVARS $cntl_out
endif
if (-e ${test_out}_DJF_plotvars.nc) then
  setenv NCDF_DJF_MODE write
else
  setenv NCDF_DJF_MODE create
endif   
if (-e ${test_out}_JJA_plotvars.nc) then
  setenv NCDF_JJA_MODE write
else
  setenv NCDF_JJA_MODE create
endif   
$NCL < $DIAG_CODE/plot_seasonal_diff.ncl
if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set9 $image &
endif
#***************************************************************
# SET 10 - Annual cycle line plots 
#***************************************************************
SET_10:
if ($all_sets == 1 && $set_10 == 1) goto SET_11
echo " "
echo SET 10 ANNUAL CYCLE LINE PLOTS 
setenv TEST_INPUT $test_in        # path/casename
setenv TEST_PLOTVARS $test_out
if ($CNTL == OBS) then
  setenv CNTL_INPUT $OBS_DATA        # path
else
  setenv CNTL_INPUT $cntl_in      # path/casename
  setenv CNTL_PLOTVARS $cntl_out
endif
if (-e ${test_out}_01_plotvars.nc) then
  setenv NCDF_MODE write
else
  setenv NCDF_MODE create
endif
$NCL < $DIAG_CODE/plot_seas_cycle.ncl
if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set10 $image &
endif
#***************************************************************
# SET 11 - Miscellaneous plot types
#***************************************************************
SET_11:
if ($all_sets == 1 && $set_11 == 1) goto SET_12
echo " "
if ($plot_ANN_climo == 0 && $plot_DJF_climo == 0 && \
    $plot_JJA_climo == 0) then 
  echo SET 11 SWCF/LWCF SCATTER PLOTS 
  setenv TEST_INPUT $test_in
  setenv TEST_PLOTVARS $test_out
  if ($CNTL == OBS) then
    setenv CNTL_INPUT $OBS_DATA
  else
    setenv CNTL_INPUT $cntl_in      # path/casename
    setenv CNTL_PLOTVARS $cntl_out
  endif
  if (-e ${test_out}_ANN_plotvars.nc) then
    setenv NCDF_ANN_MODE write
  else
    setenv NCDF_ANN_MODE create
  endif
  if (-e ${test_out}_DJF_plotvars.nc) then
    setenv NCDF_DJF_MODE write
  else
    setenv NCDF_DJF_MODE create
  endif
  if (-e ${test_out}_JJA_plotvars.nc) then
    setenv NCDF_JJA_MODE write
  else
    setenv NCDF_JJA_MODE create
  endif
  $NCL < $DIAG_CODE/plot_swcflwcf.ncl
else
  echo "WARNING: plot_ANN_climo, plot_DJF_climo, and plot_JJA_climo"
  echo "must be turned on (=0) for SET 11 LWCF/SWCF scatter plots"
endif

echo " "
if ($plot_MON_climo == 0) then
  echo SET 11 EQUATORIAL ANNUAL CYCLE
  $NCL < $DIAG_CODE/plot_cycle_eq.ncl
else
  echo "WARNING: plot_MON_climo must be turned on (=0)"
  echo "for set 11 ANNUAL CYCLE plots"
endif

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set11 $image &
endif

#****************************************************************
# SET 12 - Vertical profiles
#***************************************************************
SET_12:
if ($all_sets == 1 && $set_12 == 1) goto SET_13
echo ' '
echo SET 12 VERTICAL PROFILES
setenv TEST_CASE $test_in
if ($CNTL == OBS) then     
  setenv STD_CASE NONE 
else
  setenv STD_CASE $cntl_in
endif

if (-e ${test_path_diag}station_ids) then
 \rm ${test_path_diag}station_ids
endif
if ($set_12 == 2) then    # all stations
  echo 56 >> ${test_path_diag}station_ids
else
  if ($ascension_island == 0) then
    echo 0 >> ${test_path_diag}station_ids
  endif
  if ($diego_garcia == 0) then
    echo 1 >> ${test_path_diag}station_ids
  endif
  if ($truk_island == 0) then
    echo 2 >> ${test_path_diag}station_ids
  endif
  if ($western_europe == 0) then
    echo 3 >> ${test_path_diag}station_ids
  endif
  if ($ethiopia == 0) then
    echo 4 >> ${test_path_diag}station_ids
  endif
  if ($resolute_canada == 0) then
    echo 5 >> ${test_path_diag}station_ids
  endif
  if ($w_desert_australia == 0) then
    echo 6 >> ${test_path_diag}station_ids
  endif
  if ($great_plains_usa == 0) then
    echo 7 >> ${test_path_diag}station_ids
  endif
  if ($central_india == 0) then
    echo 8 >> ${test_path_diag}station_ids
  endif
  if ($marshall_islands == 0) then
    echo 9 >> ${test_path_diag}station_ids
  endif
  if ($easter_island == 0) then
    echo 10 >> ${test_path_diag}station_ids
  endif
  if ($mcmurdo_antarctica == 0) then
    echo 11 >> ${test_path_diag}station_ids
  endif
# skipped south pole antarctica - 12
  if ($panama == 0) then
    echo 13 >> ${test_path_diag}station_ids
  endif
  if ($w_north_atlantic == 0) then
    echo 14 >> ${test_path_diag}station_ids
  endif
  if ($singapore == 0) then
    echo 15 >> ${test_path_diag}station_ids
  endif
  if ($manila == 0) then
    echo 16 >> ${test_path_diag}station_ids
  endif
  if ($gilbert_islands == 0) then
    echo 17 >> ${test_path_diag}station_ids
  endif
  if ($hawaii == 0) then
    echo 18 >> ${test_path_diag}station_ids
  endif
  if ($san_paulo_brazil == 0) then
    echo 19 >> ${test_path_diag}station_ids
  endif
  if ($heard_island == 0) then
    echo 20 >> ${test_path_diag}station_ids
  endif
  if ($kagoshima_japan == 0) then
    echo 21 >> ${test_path_diag}station_ids
  endif
  if ($port_moresby == 0) then
    echo 22 >> ${test_path_diag}station_ids
  endif
  if ($san_juan_pr == 0) then
    echo 23 >> ${test_path_diag}station_ids
  endif
  if ($western_alaska == 0) then
    echo 24 >> ${test_path_diag}station_ids
  endif
  if ($thule_greenland == 0) then
    echo 25 >> ${test_path_diag}station_ids
  endif
  if ($san_francisco_ca == 0) then
    echo 26 >> ${test_path_diag}station_ids
  endif
  if ($denver_colorado == 0) then
    echo 27 >> ${test_path_diag}station_ids
  endif
  if ($london_england == 0) then
    echo 28 >> ${test_path_diag}station_ids
  endif
  if ($crete == 0) then
    echo 29 >> ${test_path_diag}station_ids
  endif
  if ($tokyo_japan == 0) then
    echo 30 >> ${test_path_diag}station_ids
  endif
  if ($sydney_australia == 0) then
    echo 31 >> ${test_path_diag}station_ids
  endif
  if ($christchurch_nz == 0) then
    echo 32 >> ${test_path_diag}station_ids
  endif
  if ($lima_peru == 0) then
    echo 33 >> ${test_path_diag}station_ids
  endif
  if ($miami_florida == 0) then
    echo 34 >> ${test_path_diag}station_ids
  endif
  if ($samoa == 0) then
    echo 35 >> ${test_path_diag}station_ids
  endif
  if ($shipP_gulf_alaska == 0) then
    echo 36 >> ${test_path_diag}station_ids
  endif
  if ($shipC_n_atlantic == 0) then
    echo 37 >> ${test_path_diag}station_ids
  endif
  if ($azores == 0) then
    echo 38 >> ${test_path_diag}station_ids
  endif
  if ($new_york_usa == 0) then
    echo 39 >> ${test_path_diag}station_ids
  endif
  if ($darwin_australia == 0) then
    echo 40 >> ${test_path_diag}station_ids
  endif
  if ($christmas_island == 0) then
    echo 41 >> ${test_path_diag}station_ids
  endif
  if ($cocos_islands == 0) then
    echo 42 >> ${test_path_diag}station_ids
  endif
  if ($midway_island == 0) then
    echo 43 >> ${test_path_diag}station_ids
  endif
  if ($raoui_island == 0) then
    echo 44 >> ${test_path_diag}station_ids
  endif
  if ($whitehorse_canada == 0) then
    echo 45 >> ${test_path_diag}station_ids
  endif
  if ($oklahoma_city_ok == 0) then
    echo 46 >> ${test_path_diag}station_ids
  endif
  if ($gibraltor == 0) then
    echo 47 >> ${test_path_diag}station_ids
  endif
  if ($mexico_city == 0) then
    echo 48 >> ${test_path_diag}station_ids
  endif
  if ($recife_brazil == 0) then
    echo 49 >> ${test_path_diag}station_ids
  endif
  if ($nairobi_kenya == 0) then
    echo 50 >> ${test_path_diag}station_ids
  endif
  if ($new_dehli_india == 0) then
    echo 51 >> ${test_path_diag}station_ids
  endif
  if ($madras_india == 0) then
    echo 52 >> ${test_path_diag}station_ids
  endif
  if ($danang_vietnam == 0) then
    echo 53 >> ${test_path_diag}station_ids
  endif
  if ($yap_island == 0) then
    echo 54 >> ${test_path_diag}station_ids
  endif
  if ($falkland_islands == 0) then
    echo 55 >> ${test_path_diag}station_ids
  endif
endif
$NCL < $DIAG_CODE/profiles.ncl
\rm ${test_path_diag}station_ids

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set12 $image &
endif

#*****************************************************************
# SET 13 - ISCCP Cloud Simulator Plots
#*****************************************************************
SET_13:
if ($all_sets == 1 && $set_13 == 1) goto SET_14
echo " "
echo SET 13 ISCCP CLOUD SIMULATOR PLOTS 
foreach name ($plots)   # do any or all of ANN,DJF,JJA
  setenv SEASON $name 
  setenv TEST_INPUT ${test_in}_${SEASON}_climo.nc
  setenv TEST_PLOTVARS ${test_out}_${SEASON}_plotvars.nc
  if ($CNTL == OBS) then
    setenv CNTL_INPUT $OBS_DATA
    setenv CNTL_PLOTVARS $OBS_DATA
  else
    setenv CNTL_INPUT ${cntl_in}_${SEASON}_climo.nc
    setenv CNTL_PLOTVARS ${cntl_out}_${SEASON}_plotvars.nc
  endif
  if (-e $TEST_PLOTVARS) then
    setenv NCDF_MODE write
  else
    setenv NCDF_MODE create
  endif   
  $NCL < $DIAG_CODE/plot_matrix.ncl
  if ($NCDF_MODE == create) then
    setenv NCDF_MODE write
  endif
end

if ($web_pages == 0) then
  $DIAG_CODE/ps2imgwww.csh set13 $image &
endif
#*****************************************************************
# SET 14 - Taylor Diagram Plots
#*****************************************************************
SET_14:
if ($all_sets == 1 && $set_14 == 1) goto SET_15

setenv TEST_INPUT ${test_in}
if ($CNTL != OBS) then 
    setenv CNTL_INPUT ${cntl_in}
else
    setenv CNTL_INPUT $OBS_DATA
endif

if ($plot_MON_climo == 0) then
  echo ' '
  echo SET 14 TAYLOR DIAGRAM PLOTS
  echo ' '
  $NCL < $DIAG_CODE/plot_taylor.ncl
else
  echo "WARNING: plot_MON_climo must be turned on (=0)"
  echo "for set 14 TAYLOR DIAGRAM plots"
endif

if ($web_pages == 0) then
  ${DIAG_HOME}/code/ps2imgwww.csh set14 $image &
endif

#*****************************************************************
# SET 15 - Annual Cycle Select Sites Plots
#*****************************************************************
SET_15:
if ($all_sets == 1 && $set_15 == 1) goto EXIT

setenv TEST_INPUT ${test_in}
setenv TEST_PLOTVARS ${test_out}_plotvars.nc
  if ($CNTL == OBS) then
    setenv CNTL_INPUT $OBS_DATA
  else
    setenv CNTL_INPUT $cntl_in
    setenv CNTL_PLOTVARS ${cntl_out}_plotvars.nc
  endif
  if (-e $TEST_PLOTVARS) then
    setenv NCDF_MODE write
  else
    setenv NCDF_MODE create
  endif   

if ($plot_MON_climo == 0) then
  echo ' '
  echo SET 15 ANNUAL CYCLE SELECT SITES PLOTS
  echo ' '
  $NCL < $DIAG_CODE/plot_ac_select_sites.ncl
else
  echo "WARNING: plot_MON_climo must be turned on (=0)"
  echo "for set 15 SELECT SITES plots"
endif

if ($web_pages == 0) then
  ${DIAG_HOME}/code/ps2imgwww.csh set15 $image &
endif

#***************************************************************

#***************************************************************

endif # end of !use_swift  branch

#***************************************************************

#***************************************************************

EXIT:
wait          # wait for all child precesses to finish
echo ' '


# make tarfile of web pages
#if ($web_pages == 0) then
#  cd $WKDIR
#  set tardir = $tarfile:r
#  echo MAKING TAR FILE OF DIRECTORY $tardir
#  tar -cf ${test_path_diag}$tarfile $tardir
#  \rm -fr $WEBDIR/*
#  rmdir $WEBDIR
#endif


# send email message
#if ($email == 0) then
#  echo `date` > email_msg
#  echo MESSAGE FROM THE AMWG DIAGNOSTIC PACKAGE. >> email_msg
#  echo THE PLOTS FOR $tardir ARE NOW READY! >> email_msg
#  mail -s 'DIAG plots' $email_address < email_msg
#  echo E-MAIL SENT
#  \rm email_msg
#endif  


# cleanup
if ($weight_months == 0) then
  \rm -f ${test_path_diag}*_unweighted.nc
endif
if ($save_ncdfs == 1) then
  echo CLEANING UP
  \rm -f ${test_out}*_plotvars.nc
  if ($CNTL != OBS) then
    \rm -f ${cntl_out}*_plotvars.nc  
  endif
  if ($significance == 0) then
    \rm -f ${test_out}*_variance.nc
    if ($CNTL == USER) then
      \rm -f ${cntl_out}*_variance.nc     
    endif
  endif
endif 



rm -f ${DIAG_HOME}/emop_${1}.csh









# Exporting to remote host:
set DIR2EXP = "${EMOP_CLIM_DIR}/diag_${test_casename}_${test_period}/${test_casename}_${test_period}_-_${cntl_casename}_${cntl_period}"

set RWWWD   = ${WWW_DIR_ROOT}/AMWG

set cc = "aa"
while ( $cc != "" )
    echo "Waiting for ${DIR2EXP} to be empty from ${p_type} files..."
    sleep 5
    set cc = `\ls ${DIR2EXP}/*.${p_type} 2>/dev/null`
end





if ( ${RHOST} != "" ) then

    echo "Preparing to export to remote host!"; echo
    ssh ${RUSER}@${RHOST} "mkdir -p ${RWWWD}"

    echo "rsync -avP -e 'ssh -c arcfour' ${DIR2EXP} ${RUSER}@${RHOST}:${RWWWD}/"
    rsync -avP -e 'ssh -c arcfour' ${DIR2EXP} ${RUSER}@${RHOST}:${RWWWD}/
    
    echo "Diagnostic page installed on remote host ${RHOST} in ${RWWWD}/${test_casename}_${test_period}_-_${cntl_casename}_${cntl_period} !"
    echo "( Also browsable on local host in ${DIR2EXP}/ )"

else
        echo "Diagnostic page installed in ${DIR2EXP}/"
        echo " => view this directory with a web browser (index.html)..."        
endif

echo

echo ' '
echo "NORMAL EXIT FROM SCRIPT"
date

rm -f ${DIAG_HOME}/emop_${1}.csh

echo
