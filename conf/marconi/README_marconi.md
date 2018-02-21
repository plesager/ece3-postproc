**CINECA Marconi configuration**

This configuration os for the Marconi machine at CINECA (defined by ISAC-CNR)

add these line to your $HOME/.bashrc 
```
export ECE3_POSTPROC_TOPDIR=$HOME/ecearth3/ece3-postproc  #<dir where this file is>
export ECE3_POSTPROC_RUNDIR=$CINECA_SCRATCH/ece3 #<top dir where your ecearth runs are located -see your config-run.xml>
export ECE3_POSTPROC_DATADIR=$WORK/ECE3-DATA_primavera # <dir where your ecearth data are located -see your config-run.xml> #
export ECE3_POSTPROC_MACHINE=marconi #<name of your (HPC) machine>
export ECE3_POSTPROC_ACCOUNT=Pra13_3311 #<HPC account>
export ECE3_POSTPROC_ISAC_STRUCTURE=1 <extra flag to support for ISAC-CNR data structure>
```

~                                                   
