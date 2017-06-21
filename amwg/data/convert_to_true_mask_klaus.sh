#!/bin/sh

cdo -R -f nc4c -z zip -t ecmwf  setmisstoc,0 -ifthenc,1 -gec,0.5 -selvar,LSM $1 $2
