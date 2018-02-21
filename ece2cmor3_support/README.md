By K. Strommen - Feb 18

These files are thought to provide wrapper scripts to run ECE2CMOR3 
They are addede here in order to keep track of them
Clearly, you will need to install all the ece2cmor3 tool separately

There are two main scripts.

cmor_mon.sh

This is the main script, set up to filter and then cmorize 1 month of IFS data and/or 1 leg of NEMO data. You can specify in there easily where your experiment is, where the output should go, metadata, etc...I've put a lot of documentation in the script so you should be able to figure it out pretty easily. In principle all you need to do is make sure that WORKDIR is pointing to your experiment properly. I have used the default location

:   WORKDIR=$SCRATCH/ece3/${EXP}/output/Output_${YEAR}

The script assumes output is located in $WORKDIR/IFS and $WORKDIR/NEMO. The script can be submitted directly to the slurm queue with sbatch, or launched via the other script, submit_leg.sh.

./submit_leg.sh

This script is just basic wrapper for cmor_mon.sh and is set up to easily launch enough jobs to process a full EC-Earth leg. If it's IFS only, it launches 12 jobs, one for each month, and if coupled, it launches 13, with all of NEMO handled in one job.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Please make a copy of these for yourself if you want to edit these in some way.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Testing indicates 1 month of low-res (T255) IFS takes around 35-40 minutes, and 1 year of low-res NEMO takes around 15 minutes. For hi-res (tested on qsh0 spin-up) 1 month IFS takes around 2 hours and NEMO around 30 (but qsh0 only has monthly output, so unsure how long it would take with full CMIP6 output). The two versions of the scripts (with and without "hires" appended) differ only in the requested time in the SBATCH option to account for this.

Note that currently all CMIP6 tables are working, so can produce all the cmorized CMIP6 variables. The extra PRIMAVERA variables still have some issues. You can see in the current state of cmor_mon.sh what can be done: PRIMAVERA tables with 3hrly frequencies. This produces some variables from Primday and PrimdayPt tables, but nothing else.


