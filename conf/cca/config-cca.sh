


submit_cmd="qsub"

# required programs, including compression options
for soft in nco netcdf python cdo cdftools ncl
do
    if ! module -t list 2>&1 | grep -q $soft
    then
        module load $soft
    fi
done

export cdo=cdo
export cdozip="$cdo -f nc4c -z zip"
export cdonc="$cdo -f nc"

# preferred type of CDO interpolation (curvilinear grids are obliged to use bilinear)
export remap="remapcon2"

rbld="/perm/ms/nl/nm6/r1902-merge-new-components/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

cdftoolsbin="${CDFTOOLS_DIR}/bin"
export CDFTOOLS_BIN="${CDFTOOLS_DIR}/bin"

python=python
export PYTHON=python

# support for GRIB_API?
# Set the directory where the GRIB_API tools are installed
# Note: cdo had to be compiled with GRIB_API support for this to work
# This is only required if your highest level is above 1 hPa,
# otherwise leave GRIB_API_BIN empty (or just comment the line)!
#export GRIB_API_BIN="/home/john/bin"


# The rebuild_nemo (provided with NEMO), that somebody has built (relies on flio_rbld.exe):
export RBLD_NEMO="/perm/ms/nl/nm6/r1902-merge-new-components/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"


# number of parallel procs for IFS (max 12) and NEMO rebuild. Default to 12.
if [ -z $IFS_NPROCS ] ; then
    IFS_NPROCS=12; NEMO_NPROCS=12
fi

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="/perm/ms/nl/nm6/ECE3-DATA/post-proc"
