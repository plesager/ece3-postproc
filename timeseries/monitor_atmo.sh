#!/bin/bash

# Must be called from timeseries.sh, where DATADIR (ie output from hiresclim2) is defined.

set -e
export HERE=`pwd`
export PYTHONPATH=${HERE}/scripts/barakuda_modules


usage()
{
    echo
    echo "USAGE: ${0} -R <run name> (options)"
    echo
    echo "   OPTIONS:"
    echo "      -y <YYYY>    => force initial year to YYYY"
    echo "      -f           => forces a clean start for diags"
    echo "                      (restart everything from scratch...)"
    echo "      -e           => create the HTML diagnostics page on local or remote server"
    echo "      -o           => check for previous run files and use them"
    echo "      -h           => print this message"
    echo
    exit
}

RUN=""
YEAR0="" ; iforcey0=0

IPREPHTML=0
IFORCENEW=0

while getopts R:y:t:foeh option ; do
    case $option in
        R) RUN=${OPTARG};;
        y) YEAR0=${OPTARG} ; iforcey0=1 ;;
        f) IFORCENEW=1;;
        o) CONTINUE=1 ;;
        e) IPREPHTML=1;;
        h)  usage;;
        \?) usage ;;
    esac
done

export TMPDIR_ROOT=$(mktemp -d $SCRATCH/tmp_ecearth3/timeseries_${RUN}_XXXXXX)
export POST_DIR=$DATADIR
export DIR_TIME_SERIES=`echo ${DIR_TIME_SERIES} | sed -e "s|<RUN>|${RUN}|g"`

echo
echo " *** TMPDIR_ROOT = ${TMPDIR_ROOT}"
echo " *** POST_DIR = ${POST_DIR}"
echo " *** DIR_TIME_SERIES = ${DIR_TIME_SERIES}"
echo " *** RHOST = ${RHOST}"
echo " *** RUSER = ${RUSER}"
echo " *** WWW_DIR_ROOT = ${WWW_DIR_ROOT}"
echo
echo; echo


# On what variable should we test files:
cv_test="msl"

# *** end of conf ***

is_leap()
{
    if [ "$1" = "" ]; then echo "USAGE: lb_is_leap <YEAR>"; exit; fi
    #
    i_mod_400=`expr ${1} % 400`
    i_mod_100=`expr ${1} % 100`
    i_mod_4=`expr ${1} % 4`
    #
    if [ ${i_mod_400} -eq 0 -o ${i_mod_4} -eq 0 -a ! ${i_mod_100} -eq 0 ]; then
        echo "1"
    else
        echo "0"
    fi
}

export RUN=${RUN}

if [ "${RUN}" = "" ]; then
    echo; echo "Specify which runs to be treated with the \"-R\" switch!"; echo
    usage
    exit
fi

RWWWD=${WWW_DIR_ROOT}/timeseries/${RUN}

echo; echo " Runs to be treated: ${RUN}"; echo


# where to create diagnostics
export DIAG_D=${DIR_TIME_SERIES}/atmosphere


if [ ${IFORCENEW} -eq 1 ]; then
    echo; echo "Forcing clean restart! => removing ${DIAG_D}"
    rm -rf ${DIAG_D}
    echo
fi

# Need to know first and last year
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ca=`\ls $DATADIR/Post_????/*_${cv_test}.nc | head -1` ; ca=`basename ${ca}` ;
export YEAR_INI=`echo ${ca} | sed -e "s/${RUN}_//g" -e "s/_${cv_test}.nc//g"`

ca=`\ls $DATADIR/Post_????/*_${cv_test}.nc | tail -1` ; ca=`basename ${ca}` ;
export YEAR_END=`echo ${ca} | sed -e "s/${RUN}_//g" -e "s/_${cv_test}.nc//g"`

# Checking if they at least are integers:
if [[ ! ${YEAR_INI} =~ ^[0-9]+$ ]]
then
    echo "ERROR: it was imposible to guess initial year from your input files"
    echo "       maybe the directory contains non-related files..."
    echo "      => use the -y <YEAR> switch to force the initial year!"; exit 1
fi

if [[ ! ${YEAR_END} =~ ^[0-9]+$ ]]
then
    echo "ERROR: it was imposible to guess the year coresponding to the last saved year!"
    echo "       => check your IFS output directory and file naming..."; exit 1
fi

# Checking if analysis has been run previously
FILELIST=(${DIAG_D}/${RUN}*.nc)
if [ -e ${FILELIST[0]}  ] ; then
    echo " Timeseries analysis has been performed and files has been saved..." ; echo
    OLD_SUPA_FILE=$( ls -tr ${DIAG_D}/${RUN}_${YEAR_INI}*.nc | tail -1 )
    OLD_YEAR_END=$( echo $( basename ${OLD_SUPA_FILE} ) | cut -f3 -d "_" )

    if [[ ${OLD_YEAR_END} -ne ${YEAR_END} ]] ; then
        BASE_YEAR_INI=${YEAR_INI}
        YEAR_INI=$(( ${OLD_YEAR_END} + 1 ))
        echo " Initial year forced to ${YEAR_INI}"; echo
    else
        echo " Values up to date!" ; echo
        if [[ $IPREPHTML -eq 0 ]] ; then
            exit
        fi
    fi
fi


echo " Initial year guessed from stored files => ${YEAR_INI}"; echo
echo " Last year guessed from stored files => ${YEAR_END}"; echo
if [ ${iforcey0} -eq 1 ]; then
    export YEAR_INI=${YEAR0}
    echo " Initial year forced to ${YEAR_INI}"; echo
fi

export SUPA_FILE=${DIAG_D}/${RUN}_${YEAR_INI}_${YEAR_END}_time-series_atmo.nc


# ~~~~~~~~~~~~~~~~~~~~~~~`

jyear=${YEAR_INI}

d_n=${0%/*}

avars="sf tas msl tcc totp e sshf slhf ssr str tsr ttr"

var_diags="msl NetSFC NetTOA PminE tas tcc sshf slhf ssr str tsr ttr e"

fcompletion=${DIAG_D}/last_year_done.info

if [ ${IPREPHTML} -eq 0 ]; then

    echo " Will store all extracted time series into:"
    echo " ${SUPA_FILE}"

    # create output directory if necessary
    mkdir -p ${DIAG_D} || exit

    # Temporary directory:
    rand_strg=`dd if=/dev/urandom count=128 bs=1 2>&1 | md5sum | cut -b-8`
    TMPD=${TMPDIR}/atmo_time_series.${RUN}.${rand_strg}
    mkdir -p ${TMPD} || exit

    jyear=${YEAR_INI}

    #if [ -f ${fcompletion} ]; then jyear=`cat ${fcompletion}`; jyear=`expr ${jyear} + 1`; fi

    icontinue=1

    rm -f ${SUPA_FILE}

    # Loop along years:
    while [ ${icontinue} -eq 1 ]; do

        echo; echo " **** year = ${jyear}"

        # Testing if the current year has been done
        ftst=$DATADIR/Post_????/${RUN}_${jyear}_${cv_test}.nc

        if [ ! -f ${ftst} ]; then
            echo "Year ${jyear} is not completed yet:"; echo " => ${ftst} is missing"; echo
            icontinue=0
            #echo "`expr ${jyear} - 1`" > ${fcompletion}
        fi


        if [ ${icontinue} -eq 1 ]; then

            echo; echo; echo;
            echo " Starting diagnostic for ${RUN} for year ${jyear} !"
            echo; echo

            nbday=365
            if [ `is_leap ${jyear}` -eq 1 ]; then
                echo; echo " ${jyear} is leap!!!!"; echo
                nbday=366
            fi

            SUPA_Y=${RUN}_${jyear}_time-series_atmo.tmp

            cd ${TMPD}/

            jv=0
            for cvar in ${avars[*]}; do

                rm -f tmp.nc tmp2.nc

                echo "cdo -R -t -fldmean $DATADIR/Post_????/${RUN}_${jyear}_${cvar}.nc ${cf_out}"
                cdo -R -fldmean $DATADIR/Post_????/${RUN}_${jyear}_${cvar}.nc tmp0.nc
                echo
                
                ncwa -3 -O -a lat,lon tmp0.nc -o tmp.nc ; rm tmp0.nc ; # removing degenerate lat and lon dimensions

                # Creating time vector if first year:
                if [ ${jv} -eq 0 ]; then
                    rm -f time_${jyear}.nc
                    ncap2 -3 -h -O -s "time=(time/24.+15.5)/${nbday}" tmp.nc -o tmp0.nc
                    ncap2 -3 -h -O -s "time=time-time(0)+${jyear}+15.5/${nbday}" \
                        -s "time@units=\"years\"" tmp0.nc -o tmp2.nc
                    ncks -3 -h -O -v time tmp2.nc -o time_${jyear}.nc
                    rm -f tmp0.nc tmp2.nc
                fi

                # Creating correct time array:
                ncks -3 -A -h -v time time_${jyear}.nc -o tmp.nc
                ncap2 -3 -h -O -s "time=time+${jyear}" -s "time@units=\"years\"" tmp.nc -o tmp2.nc
                rm -f tmp.nc

                #if [ ! "${cvar}" = "${cvar_nc}" ]; then
                #    echo "ncrename -v ${cvar_nc},${cvar} tmp2.nc"
                #    ncrename -h -v ${cvar_nc},${cvar} tmp2.nc
                #    echo
                #fi

                echo "ncks -3 -A -v ${cvar} tmp2.nc -o ${SUPA_Y}"
                ncks -3 -h -A -v ${cvar} tmp2.nc -o ${SUPA_Y}
                echo

                rm -f tmp2.nc

                jv=`expr ${jv} + 1`

            done

            # Correcting water flux units, from kg/m^2/s to mm/day => *24*3600 = *86400
            for cv in "totp" "e"; do
                ncap2 -3 -h -O -s "${cv}=86400.*${cv}" -s "${cv}@units=\"mm/day\"" ${SUPA_Y} -o ${SUPA_Y}
            done

            # Correcting heat fluxes:
            #for cv in "tsr" "ttr" "ssr" "str" "slhf" "sshf" ; do
            #    ncap2 -3 -h -O -s "${cv}=${cv}/${D10800}" -s "${cv}@units=\"W/m^2\"" ${SUPA_Y} -o ${SUPA_Y}
            #done

            # Pressure to hPa:
            cv='msl'
            ncap2 -3 -h -O -s "${cv}=0.01*${cv}" -s "${cv}@units=\"hPa\"" ${SUPA_Y} -o ${SUPA_Y}

            # T2m to C:
            cv='tas'
            ncap2 -3 -h -O -s "${cv}=${cv}-273.15" -s "${cv}@units=\"deg.C\"" ${SUPA_Y} -o ${SUPA_Y}



            # Creating composite variable:
            ##############################
            
            # Snowfall latent heat flux
            cv='sfhf'
            ncap2 -3 -h -O -s "${cv}=-334000*sf" -s "${cv}@units=\"W/m^2\"" \
                  -s "${cv}@long_name=\"Snowfall latent heat flux\""  ${SUPA_Y} -o ${SUPA_Y}

            # P-E
            cv="PminE"
            ncap2 -3 -h -O -s "${cv}=totp+e" -s "${cv}@units=\"mm/day\""  -s "${cv}@long_name=\"P-E at the surface\"" \
                ${SUPA_Y} -o tmp.nc
            ncks -3 -h -A -v ${cv}  tmp.nc -o ${SUPA_Y}
            rm -f tmp.nc
            
            cv="NetTOA"
            ncap2 -3 -h -O -s "${cv}=tsr+ttr" -s "${cv}@units=\"W/m^2\"" -s "${cv}@long_name=\"TOA net heat flux\"" \
                ${SUPA_Y} -o tmp.nc
            ncks -3 -h -A -v ${cv}  tmp.nc -o ${SUPA_Y}
            rm -f tmp.nc

            cv="NetSFCs"
            ncap2 -3 -h -O -s "${cv}=sshf+slhf+ssr+str+sfhf" -s "${cv}@units=\"W/m^2\""  -s "${cv}@long_name=\"Surface net heat flux with snowfall\"" \
                ${SUPA_Y} -o tmp.nc
            ncks -3 -h -A -v ${cv}  tmp.nc -o ${SUPA_Y}
            rm -f tmp.nc

            cv="NetSFC"
            ncap2 -3 -h -O -s "${cv}=sshf+slhf+ssr+str" -s "${cv}@units=\"W/m^2\""  -s "${cv}@long_name=\"Surface net heat flux\"" \
                ${SUPA_Y} -o tmp.nc
            ncks -3 -h -A -v ${cv}  tmp.nc -o ${SUPA_Y}
            rm -f tmp.nc

            
            echo " ${SUPA_Y} done..."; echo; echo
            
        fi

        jyear=`expr ${jyear} + 1`

    done  # ${icontinue} -eq 1

    ncrcat -h -O ${RUN}_*_time-series_atmo.tmp -o ${SUPA_FILE}
    
    ncrcat -O time_*.nc -o supa_time.nc

    #echo "ncks -3 -A -h -v time supa_time.nc -o ${SUPA_FILE}"
    ncks -3 -A -h -v time supa_time.nc -o ${SUPA_FILE}
    #fix the time axis since cdo does not support it
#    cdo settaxis,${YEAR_INI}-01-01,00:00:00,1mon ${SUPA_FILE} tmp1.nc 
#    mv tmp1.nc ${SUPA_FILE}

    rm -f ${RUN}_*_time-series_atmo.tmp time_*.nc supa_time*.nc

    rm -rf ${TMPD}

    echo
    echo " Time series saved into:"
    echo " ${SUPA_FILE}"
    echo

    #Concatenate new and old files... 
    if [[ ! -z ${BASE_YEAR_INI} ]] ; then
         echo " Concatenate old and new netcdf files... " 
         ncrcat -h ${OLD_SUPA_FILE} ${SUPA_FILE} ${DIAG_D}/${RUN}_${BASE_YEAR_INI}_${YEAR_END}_time-series_atmo.nc
         rm ${OLD_SUPA_FILE} ${SUPA_FILE}
         export SUPA_FILE=${RUN}_${BASE_YEAR_INI}_${YEAR_END}_time-series_atmo.nc
         echo " Variables saved in ${RUN}_${BASE_YEAR_INI}_${YEAR_END}_time-series_atmo.nc " ; echo
    fi


fi # [ ${IPREPHTML} -eq 0 ]


if [ ${IPREPHTML} -eq 1 ]; then


    if [ ! -f ${SUPA_FILE} ]; then
        echo
        echo " PROBLEM: we cannot find ${SUPA_FILE} !!!"
        exit
    fi

    cd ${DIAG_D}/

    ${PYTHON} ${HERE}/scripts/plot_atmo_time_series.py

    # Configuring HTML display file:
    sed -e "s/{TITLE}/Atmosphere diagnostics for EC-Earth coupled experiment/g" \
        -e "s/{RUN}/${RUN}/g" -e "s/{DATE}/`date`/g" -e "s/{HOST}/`hostname`/g" \
        ${HERE}/scripts/index_atmo_skel.html > index.html
    
    
    if [ ! "${RHOST}" = "" ]; then
        echo "Preparing to export to remote host!"; echo
        cd ../
        tar cvf atmosphere.tar atmosphere
        ssh ${RUSER}@${RHOST} "mkdir -p ${RWWWD}"
        echo "scp atmosphere.tar ${RUSER}@${RHOST}:${RWWWD}/"
        scp atmosphere.tar ${RUSER}@${RHOST}:${RWWWD}/
        ssh ${RUSER}@${RHOST} "cd ${RWWWD}/; rm -rf atmosphere; tar xf atmosphere.tar 2>/dev/null; chmod go+rx atmosphere ; chmod go+r atmosphere/* ; rm atmosphere.tar"
        echo; echo
        echo "Diagnostic page installed on remote host ${RHOST} in ${RWWWD}/atmosphere!"
        echo "( Also browsable on local host in ${DIAG_D}/ )"
        rm -rf atmosphere.tar
    else
        echo "Diagnostic page installed in ${DIAG_D}/"
        echo " => view this directory with a web browser (index.html)..."
    fi

    echo; echo

fi # [ ${IPREPHTML} -eq 1 ]


rm -rf ${TMPD}
