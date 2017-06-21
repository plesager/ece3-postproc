#!/bin/ksh


# Getting list of available confs:
list_confs=`\ls ../conf_*.bash | sed -e "s|../conf_||g" -e "s|.bash||g"`

usage()
{
    echo
    echo "USAGE: ${0} -C <MY_SETUP> -R <run name> -P <year1-year2>"
    echo
    echo "              * <MY_SETUP>         => configuration settings"
    echo "                                    file ../../conf_<MY_SETUP>.bash must be here"
    echo "                          List of available MY_SETUP is:"
    echo "${list_confs}"
    echo
    #echo "   OPTIONS:"
    #echo "      -y <YYYY>    => force initial year to YYYY"
    #echo "      -f           => forces a clean start for diags"
    #echo "                      (restart everything from scratch...)"
    #echo "      -e           => create the HTML diagnostics page on local or remote server"
    #echo "      -h           => print this message"
    #echo
    exit
}


MY_SETUP=""
RUN=""
PERIOD=""

while getopts C:R:P: option ; do
    case $option in
        C) export MY_SETUP=${OPTARG};;
        R) export RUN=${OPTARG};;
        P) export PERIOD=${OPTARG};;
        h)  usage;;
        \?) usage ;;
    esac
done

if [ "${MY_SETUP}" = "" -o "${RUN}" = "" -o "${PERIOD}" = "" ]
then 
    usage
    exit 1
fi

fconfig="../conf_${MY_SETUP}.bash"
if [ ! -f ${fconfig} ]; then echo " ERROR: no configuration file found: ${fconfig}"; exit; fi
. ${fconfig}

export EMOP_CLIM_DIR=`echo ${EMOP_CLIM_DIR} | sed -e "s|<RUN>|${RUN}|g"`

# This was a wrapper to call the actual csh file:
csh ./csh/diag_mod_vs_obs.csh
