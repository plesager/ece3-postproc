#--------------------------------------------------------------#
# EC-Mean v0.1                                                 #
# Paolo Davini (ISAC-CNR) - <p.davini@isac.cnr.it>             #
# December 2014                                                #
#--------------------------------------------------------------#

# EC-Mean is a simple and fast tool to evaluate different global means
# and the Performance Indices (PI) from Reichler and Kim (2008)
# for EC-Earth any simulations.
# It is based on the output obtained by the classical EC-Earth
# hiresclim postprocessing tool. 

# NEEDED SOFTWARE
# EC-Mean is thought to work only with CDO. Climatologies data are in netcdf
# and Hiresclim or EmOP postprocessed output is needed.
# Tested with CDO 1.5.5 and CDO 1.6.2, netCDF version 4.1.3.

# HOW TO SET
# Just set the different folders in the config.sh file and check CDO is working
# EC-mean is thought to work with standard EC-Earth v3.1 resolution 
# T255L91 ORCA1L46, but theoretically should be fine also at different resolution.

# HOW TO RUN
# EC-Mean is based on 4 different bash scripts, than can be run from together
# using the wrapper EC-mean.sh
# However, they are thought to work independently:
# 1. post2x2.sh creates climatologies from postprocessed output on a 2x2 grid.
# 2. oldPI2.sh computes the PI with the same method of the previously avaiable
#    GRADS-based routine. 
# 3. PI3.sh computes the PI applying some minor corrections (see the script)
# 4. global_mean.sh computes the averages of different radiative (TOA and surface)
#    and non-radiative fields (e.g. temperature, precipitation, etc.)

# OUTPUT
# 2 different .txt tables, one with the global mean and the other one with the PIs.

# Please contact me at <p.davini@isac.cnr.it> if you find any problem or bug
# or if you have any question.


