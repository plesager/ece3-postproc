#!/bin/bash

#==========================================================
#
#         Configuration file for
#
# OCEAN MONITORING for NEMO v3.6 of EC-Earth 3.2.2 on 75 levels
#
#        Machine: cca/ccb ecmwf.int
#
#        L. Brodeau, 2017
#        P. Le Sager, June 27, 2017
#
#===========================================================

export CONF=ORCA025.L75 ; # horizontal global ORCA configuration
export NBL=75         ; # number of levels

export HOST="cca/ECMWF" ; # this has no importance at all, it will just become an "info" on the web-page!
export MASTERMIND="KNMI / Frank Selten" ; # same here, who's the person who designed/ran this simulation?

export EXTRA_CONF="NEMO 3.6 + LIM 3 (EC-Earth 3.2.2)" ;   #  // same here ...

# Path / directory structure in which to find NEMO output file (you can use
# <ORCA> and <EXP> as substitute to your ORCA grid and experiment (EXP) name):
#AB export NEMO_OUT_STRCT="$SCRATCH/ece3/<EXP>/"
#ABexport NEMO_OUT_STRCT="$SCRATCH/ece3/<EXP>/output/Output_????/NEMO"
export NEMO_OUT_STRCT="/marconi_scratch/userexternal/$USERexp/ece3/<EXP>/output/Output_????/NEMO"

# Path to root directory where to save the diagnostics (diagnostics for this "CONF"):
export DIAG_DIR="$SCRATCH/barakuda/${CONF}_ece32"

# Path to directory containing some 2D and 3D climatologies on the relevant ORCA grid:
export CONF_INI_DIR="/marconi/home/userexternal/abalanzi/scratch/ECE-DATA/input_barakuda/ORCA025.L75_barakuda"

# Temporary file system (scratch) on which to perform the job you can use <JOB_ID> if scracth depends on JOB ID:
#AB export SCRATCH="$SCRATCH/tmp/<JOB_ID>"    ##AB: quando lo lancio attraverso lo script bar.sh (da ecearth/post/script) 
export SCRATCH="$SCRATCH"

export PYTHON_HOME="/cineca/prod/opt/compilers/python/2.7.12/none" ; # HOME to python distribution with matplotlib and basemap !

export DIR_NCVIEW_CMAP="${BARAKUDA_ROOT}/src/ncview_colormaps"

# Is it an ec-earth experiment?
export ece_exp=1 ; # 0 => not an EC-Earth experiment, it's a "pure" ocean-only NEMO experiment done from traditional NEMO setup
#                  # 1 => it's an OCEAN-ONLY EC-Earth experiment done from a EC-Earth setup
#                  # 2 => it's a  COUPLED  EC-Earth experiment
#                  #      Both 1 and 2 imply that NEMO files are stored in something like
#                  #       ${SOMEWHERE}/<EXP>/output/nemo/<YYY>
#                  #       where YYY starts from '001' to
#                  #      If you select '2', make sure 'cdo' is available and working!!!
#                  # 10 => this experiment controled by AutoSubmit (so NEMO files are tared somerwhere?)
#
export Y_INI_EC=1950 ;    # initial year if ece_exp /= 0 !!!
export TRES_IFS=511  ;    # spectral resolution for IFS, ex: T255 => TRES_IFS=255
###--- end EC-Earth IFS relate section ---

export ATMO_INFO="IFS T${TRES_IFS}" ; # Name of atmospheric model or forcing used (ex: COREv2, DFS5.2, IFS T255, ect...)

# List of suffix of files that have been saved by NEMO and contain MONTHLY averages:
export NEMO_SAVED_FILES="grid_T grid_U grid_V icemod SBC"

export TSTAMP="1m"   ; # output time-frequency stamp as in NEMO output files...

# In case 3D fields have been saved on an annual mean basis rather than montly:
export ANNUAL_3D="" ;   # leave blanck "" if 3D fields are in monthly files...
export NEMO_SAVED_FILES_3D="" ; #     ''

# How does the nemo files prefix looks like
# Everything before "<year_related_info>_grid_<X>" or "<year_related_info>_icemod"
# use <ORCA>, <EXP> and <TSTAMP>=>  Ex: export NEMO_FILE_PREFIX="<ORCA>-<EXP>_<TSTAMP>_"
export NEMO_FILE_PREFIX="<EXP>_<TSTAMP>_"
# => should get rid of TSTAMP actually...


####### NEMO => what fields in what files ??? ############
#       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   => depends on the XIOS *.xml setup you used...
#   => always specify a string for the NN_* variables
#      USE "X" if the field is not present in your NEMO output
#
# State variables and others in grid_T files:
export NN_SST="tos"
export NN_SSS="sos"
export NN_SSH="zos"
export NN_T="thetao"
export NN_S="so"
#AB export NN_MLD="mldr10_1"
export NN_MLD="mlotst" # name for Primavera
#
# State variables and others in grid_U files:
export NN_U="uo"
export NN_TAUX="tauuo"
export NN_U_EIV="0" ; # 0 => ignore
# State variables and others in grid_V files:
export NN_V="vo"
export NN_TAUY="tauvo"
export NN_V_EIV="0" ; # 0 => ignore
#
# Sea-ice fields:
export FILE_ICE_SUFFIX="icemod" ; # in what file type extension to find ice fields
export NN_ICEF="siconc" ; # name of ice fraction in "FILE_ICE_SUFFIX" file...
export NN_ICET="sivolu" ; # ice thickness or rather volume...
export NN_ICEU="siu" ; # ice U-velocity > change for Primavera
#AB export NN_ICEU="sivelu" ; # ice U-velocity
export NN_ICEV="siv" ; # ice V-velocity > change for Primavera
#AB export NN_ICEV="sivelv" ; # ice V-velocity
#
# Surface fluxes:
export FILE_FLX_SUFFIX="SBC" ; # in what file type extension to find surface fluxes (normally: "SBC")
####                           # => mind that $FILE_FLX_SUFFIX must be also in NEMO_SAVED_FILES (above)
#### Note: in fields marked with *+/-* you can use a sum or substraction of variables (no space allowed!)
####       ex: NN_EMP="evap_ao_cea+subl_ai_cea-precip"
####           NN_QNET="qsr+qnsol"
# ++ Surface freswater fluxes:
export NN_FWF="wfo"       ; # *+/-* name of net freshwater flux (E-P-R) in "FILE_FLX_SUFFIX" file...
#AB export NN_EMP="evap_ao_cea+subl_ai_cea-precip" ; # *+/-* name of E-P in "FILE_FLX_SUFFIX" file...
export NN_EMP="X" ; # *+/-* name of E-P in "FILE_FLX_SUFFIX" file...
export NN_P="precip"      ; # name of total precipitation (solid+liquid) in "FILE_FLX_SUFFIX" file...
#AB export NN_RNF="runoffs"   ; # name of continental runoffs in "FILE_FLX_SUFFIX" file...
export NN_RNF="hflx_rnf_cea"   ; # name of continental runoffs in "FILE_FLX_SUFFIX" file...
#AB export NN_CLV="calving"   ; # calving from icebergs in "FILE_FLX_SUFFIX" file...
export NN_CLV="hflx_cal_cea"   ; # calving from icebergs in "FILE_FLX_SUFFIX" file...
#AB export NN_E="evap_ao_cea+subl_ai_cea" ; # *+/-* name of total evaporation in "FILE_FLX_SUFFIX" file...
export NN_E="X" ; # *+/-* name of total evaporation in "FILE_FLX_SUFFIX" file...
# ++ Surface heat fluxes:
export NN_QNET="qt_oce"   ; # *+/-* name of total net surface heat flux in "FILE_FLX_SUFFIX" file...
export NN_QSOL="rsntds"   ; # name of net surface solar flux in "FILE_FLX_SUFFIX" file...
# ++ Wind-stress module:
export NN_TAUM="taum"        ; # name of surface wind stress module in "FILE_FLX_SUFFIX" file...
export NN_WNDM="windsp"      ; # name of surface wind  speed module in "FILE_FLX_SUFFIX" file...
#
################################################################################################

# Land-sea mask and basins files:
#AB export MM_FILE=${CONF_INI_DIR}/mesh_mask.nc4
#AB export BM_FILE=${BARAKUDA_ROOT}/data/basin_mask_ORCA1_ece3.2_2017.nc4
export MM_FILE=$WORK/ecearth3/nemo/ORCA025L75/mesh_mask.nc
export BM_FILE=$WORK/ecearth3/nemo/ORCA025L75/basin_mask.nc

# OBSERVATIONS / REFERENCES
# 3D monthly climatologies of potential temperature and salinity (can be those you used for the NEMO experiment):
export NM_TS_OBS="EN4.2.0 [1990-2010]"
export F_T_OBS_3D_12=${CONF_INI_DIR}/thetao_EN.4.2.0_ORCA025L75_mclim_1990-2010.nc4
export F_S_OBS_3D_12=${CONF_INI_DIR}/so_EN.4.2.0_ORCA025L75_mclim_1990-2010.nc4
export F_SST_OBS_12=${CONF_INI_DIR}/thetao_EN.4.2.0_ORCA025L75_mclim_1990-2010.nc4
export NN_T_OBS="thetao"
export NN_S_OBS="so"
export NN_SST_OBS="thetao"
#
# Sea-ice:
export NM_IC_OBS="Hurrell et al 2008 [1980-1999]"
export F_ICE_OBS_12=${CONF_INI_DIR}/ice_cover_180x360-ORCA025_Hurrell_monthly_mean1980-1999.nc4
export NN_ICEF_OBS="ice_cover"
#
# Surface Heat fluxes:
export NM_QSOL_OBS="NOCS 2.0 [1980-2005]"
export F_QSOL_OBS_12=${BARAKUDA_ROOT}/data/obs/radsw_monthly_clim_1980-2005_NOCS2.nc4
export NN_QSOL_OBS="radsw"


# A text file where the cross sections (to compute transports) are defined :
export TRANSPORT_SECTION_FILE="${BARAKUDA_ROOT}/data/transportiz_ORCA025_y1050.dat"        ; # set i_do_trsp=1 !
export TRANSPORT_SECTION_FILE_ICE="${BARAKUDA_ROOT}/data/transport_ice_ORCA025_y1050.dat"  ; # set i_do_trsp_ice=1 !

# For transport by sigma-class:
export DENSITY_SECTION_FILE="${BARAKUDA_ROOT}/data/dens_section_ORCA025_y1050.dat"

# Files with the list of rectangular domains to "analyze" more closely:
export FILE_DEF_BOXES="${BARAKUDA_ROOT}/data/def_boxes_convection_ORCA025_y1050.txt"
export FILE_DMV_BOXES="${BARAKUDA_ROOT}/data/def_boxes_convection_ORCA025_y1050.txt"

# In what format should figures be produced ('png' recommanded, but 'svg' supported!):
export FIG_FORM="png"

# About remote HOST to send/install HTML pages to:
export ihttp=0                ; # do we export on a remote http server (1) or keep on the local machine (0)
export RHOST=whitehouse.gov   ; # remote host to send diagnostic page to///
export RUSER=donald           ; # username associated to remote host (for file export)
export RWWWD=/data/www/barakuda/ec-earth_3.2b ; # directory of the local or remote host to send the diagnostic page to


#########################
# Diags to be performed #
#########################

# Movies of SST and SSS compared to OBS:
export i_do_movi=1
export iffmpeg_x264=0 ; # is, by chance, ffmpeg with support for x264 encoding available on your stystem? => 1 !

# Basic 3D and surface averages:
export i_do_mean=1

# IFS surface fluxes of heat and freshwater
export i_do_ifs_flx=0 ; # only relevant when ece_exp=2...

# AMOC:
export i_do_amoc=1
export LMOCLAT="20-23 30-33 40-43 45-48 50-53" ; # List of latitude bands to look in for max of AMOC

# Sea-ice diags
export i_do_ice=1  ; # Sea-ice diags

# Transport of mass, heat and salt through specified sections (into TRANSPORT_SECTION_FILE):
export i_do_trsp=2  ; # transport of mass, heat and salt through specified sections
#              # i_do_trsp=2 => treat also different depths range!
z1_trsp=100  ; # first  depth: i_do_trsp must be set to 2
z2_trsp=1000 ; # second depth: i_do_trsp must be set to 2

# Solid freshwater transport through sections due to sea-ice drift
export i_do_trsp_ice=1 ; # must have i_do_ice=1

# Meridional heat/salt transport (advective)
export i_do_mht=1

# Transport by sigma class
export i_do_sigt=1   #AB original flag is 1

# Budget on pre-defined (FILE_DEF_BOXES) rectangular domains:
export i_do_bb=1   ; # Budget and other stuffs on a given rectangular box!
#             # => needs file FILE_DEF_BOXES !!!
# => produces time-series f(t)  (mean of 2D fields)

# Vertical profiles on of box-averaged as a function of time...
export i_do_box_TS_z=1 ; # do sigma vert. profiles on given boxes... # 1 => no figures, 2 => figures
#                 # => needs file FILE_DEF_BOXES !!!
# => produces time-series f(t,z)

# Deep Mixed volume in prescribed boxes:
export i_do_dmv=1
export MLD_CRIT="1000,725,500"

# User-defined meridional or zonal cross sections (for temperature and salinity)
# => TS_SECTION_FILE must be defined!
export i_do_sect=1
export TS_SECTION_FILE="${BARAKUDA_ROOT}/data/TS_sections.dat"


# BETA / TESTING / NERDY (at your own risks...):
#
export i_do_ssx_box=0 ; # zoom on given boxes (+spatially-averaged values) for surface properties
#                     # boxes defined into barakuda_orca.py ...

# Some nerdy stuffs about the critical depth in prescribed boxes:
export i_do_zcrit=0
