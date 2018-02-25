#!/bin/bash

# Must be called from timeseries.sh, where DATADIR (ie output from hiresclim2) is defined.

set -ue

export HERE=`pwd`
export PYTHONPATH=${HERE}/scripts/barakuda_modules

usage()
{
    echo
    echo "USAGE: ${0}  -R <run name> (options)"
    echo
    echo "   OPTIONS:"
    echo "      -y <YYYY>    => force initial year to YYYY"
    echo "      -f           => forces a clean start for diags"
    echo "                      (restart everything from scratch...)"
    echo "      -e           => create the HTML diagnostics page on local or remote server"
    echo "      -h           => print this message"
    echo
    exit
}

RUN=""
YEAR0="" ; iforcey0=0

IPREPHTML=0
IFORCENEW=0

while getopts R:y:t:feh option ; do
    case $option in
        R) RUN=${OPTARG};;
        y) YEAR0=${OPTARG} ; iforcey0=1 ;;
        f) IFORCENEW=1;;
        e) IPREPHTML=1;;
        h)  usage;;
        \?) usage ;;
    esac
done

mkdir -p $SCRATCH/tmp_ecearth3/tmp
export TMPDIR_ROOT=$(mktemp -d $SCRATCH/tmp_ecearth3/tmp/ts_${RUN}_XXXXXX)
export POST_DIR=$DATADIR

echo
echo " *** TMPDIR_ROOT = ${TMPDIR_ROOT}"
echo " *** POST_DIR = ${POST_DIR}"
echo " *** DIR_TIME_SERIES = ${DIR_TIME_SERIES}"
echo " *** RHOST = ${RHOST}"
echo " *** RUSER = ${RUSER}"
echo " *** WWW_DIR_ROOT = ${WWW_DIR_ROOT}"
echo
echo; echo

sleep 3

# On what variable should we test files:
cv_test="sosstsst"

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

RWWWD=${WWW_DIR_ROOT}/time_series/${RUN}

echo; echo " Runs to be treated: ${RUN}"; echo

# where to create diagnostics:
export DIAG_D=${DIR_TIME_SERIES}/ocean

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


#PD: check to have more than one year
if [ ${YEAR_INI} -eq ${YEAR_END} ] ; then
    echo "ERROR: only one year"; exit
fi

export SUPA_FILE=${DIAG_D}/${RUN}_${YEAR_INI}_${YEAR_END}_time-series_ocean.nc

# ~~~~~~~~~~~~~~~~~~~~~~~`

jyear=${YEAR_INI}

d_n=${0%/*}

#PD add sowaflup
avars_2d="sosstsst sosaline sossheig sowaflup"
avars_3d="votemper vosaline"

if [ ${IPREPHTML} -eq 0 ]; then

    echo " Will store all extracted time series into:"
    echo " ${SUPA_FILE}"

    # create output directory if necessary
    mkdir -p ${DIAG_D} || exit

    # Temporary directory:
    rand_strg=`dd if=/dev/urandom count=128 bs=1 2>&1 | md5sum | cut -b-8`
    TMPD=${TMPDIR_ROOT}/ocean_time_series.${RUN}.${rand_strg}
    mkdir -p ${TMPD} || exit

    jyear=${YEAR_INI}

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

            SUPA_Y=${RUN}_${jyear}_time-series_ocean.tmp

            cd ${TMPD}/

            # Copying mesh-mask to current directory:
            for cf in mask.nc mesh_zgr.nc mesh_hgr.nc new_maskglo.nc; do

                if [ ! -f ./${cf} ]; then
                    if [ -f ${POST_DIR}/${cf} ]; then
                        echo "Copying ${cf} from ${POST_DIR}/"
                        #PD: linking instead of copying
                        ln -s ${POST_DIR}/${cf} .
                        #cp -L ${POST_DIR}/${cf} .
                    elif [ -f ${NEMO_MESH_DIR}/${cf} ]; then
                        echo "Copying ${cf} from ${NEMO_MESH_DIR}/"
                        #PD: linking instead of copying
                        ln -s ${NEMO_MESH_DIR}/${cf} .
                        #cp -L ${NEMO_MESH_DIR}/${cf} .
                    else
                        echo " ${cf} could not be found anywhere! "
                        exit 1
                    fi
                fi
            done


            # 2D fields
            ###########

            jv=0
            for cvar in ${avars_2d[*]}; do

                f_in=$DATADIR/Post_????/${RUN}_${jyear}_${cvar}_mean.nc

                if [ -f ${f_in} ]; then

                    ncks -O  -v mean_${cvar}         ${f_in} -o tmp.nc
                    ncrename -v mean_${cvar},${cvar} tmp.nc 
                    #LOLO: REMOVE SOON  --------------------
                    # If time-record is called "time_counter", renaming to "time"
                    #ca=`ncdump -h tmp.nc | grep UNLIMITED | grep time_counter`
                    #if [ ! "${ca}" = "" ]; then
                    #    echo "ncrename -h -d time_counter,time  tmp.nc"
                    #    ncrename -h -d time_counter,time  tmpA.nc -o tmpB.nc
                    #fi
                    #ca=`ncdump -h tmp.nc | grep time_counter.units`
                    #if [ ! "${ca}" = "" ]; then
                    #   echo "ncrename -h -v time_counter,time tmp.nc"
                    #   ncrename -h -v time_counter,time  tmpB.nc -o tmpC.nc
                    #fi
                    #LOLO. --------------------
                    
		    # Creating time vector if first year:
                    if [ ${jv} -eq 0 ]; then
                        rm -f time_${jyear}.nc
                        $NCAP -3 -h -O -s "time_counter=(time_counter/(24.*3600.)+15.5)/${nbday}" tmp.nc -o tmp0.nc
                        $NCAP -3 -h -O -s "time_counter=time_counter-time_counter(0)+${jyear}+15.5/${nbday}" \
                            -s "time_counter@units=\"years\"" tmp0.nc -o tmp2.nc
                        ncks -3 -h -O -v time_counter tmp2.nc -o time_${jyear}.nc
                        rm -f tmp0.nc tmp2.nc
                    fi

                    # Appending correct time array into tmp.nc:
                    ncks -3 -A -h -v time_counter time_${jyear}.nc -o tmp.nc

                    echo
                    echo "ncks -3 -A -v ${cvar} tmp.nc -o ${SUPA_Y}"
                    ncks -3 -h -A -v ${cvar} tmp.nc -o ${SUPA_Y}

                    rm -f tmp.nc

                    jv=`expr ${jv} + 1`

                else
                    echo; echo " *** File ${f_in} not here! Skipping variable ${cvar}!"
                fi
                echo
            done
            echo




            # 3D fields
            ###########

            for cvar in ${avars_3d[*]}; do

                f_in=$DATADIR/Post_????/${RUN}_${jyear}_${cvar}_mean.nc

                if [ -f ${f_in} ]; then

                    ncks -O  -v mean_${cvar},mean_3D${cvar} ${f_in} -o tmp.nc
                    ncrename -v mean_${cvar},${cvar} -v  mean_3D${cvar},${cvar}_3d    tmp.nc

                    # Creating time vector if first year:
                    if [ ! -f time_${jyear}.nc ]; then
                        echo "PROBLEM: time_${jyear}.nc not here!!!"; exit
                    fi

                    # Creating correct time array:
                    ncks -3 -A -h -v time_counter time_${jyear}.nc -o tmp.nc

                    echo
                    echo "ncks -3 -A -v ${cvar} tmp.nc -o ${SUPA_Y}"
                    ncks -3 -h -A -v ${cvar}     tmp.nc -o ${SUPA_Y}
                    ncks -3 -h -A -v ${cvar}_3d  tmp.nc -o ${SUPA_Y}

                    rm -f tmp.nc

                else
                    echo; echo " *** File ${f_in} not here! Skipping variable ${cvar}!"
                fi
                echo
            done

            echo




            # AMOC
            #######

            echo
            echo "Doing AMOC"

            f_in=$DATADIR/Post_????/${RUN}_${jyear}_moc.nc

            # TODO does not work with ncap
            if [ -f ${f_in} ] && [ "$NCAP" == "ncap2" ] ; then

                # removing degenerate x dimension:
                ncwa -3 -O -a x ${f_in} -o moc_tmp.nc

                #LOLO: REMOVE SOON  --------------------
                # If time-record is called "time_counter", renaming to "time"
                #ca=`ncdump -h moc_tmp.nc | grep UNLIMITED | grep time_counter`
                #if [ ! "${ca}" = "" ]; then
                #    echo "ncrename -h -d time_counter,time  moc_tmp.nc"
                #    ncrename -h -d time_counter,time  moc_tmp.nc
                #fi
                #ca=`ncdump -h moc_tmp.nc | grep time_counter.units`
                #if [ ! "${ca}" = "" ]; then
                #    echo "ncrename -h -v time_counter,time moc_tmp.nc"
                #    ncrename -h -v time_counter,time  moc_tmp.nc
                #fi
                #LOLO. --------------------


                for ll in 30 40 50; do

                    lm1=`expr ${ll} - 1` ; lp1=`expr ${ll} + 1`

                    # Only range of latitude and depth we want:
                    $NCAP -3 -O -h -s "dlat= ((nav_lat >=  ${lm1})&&(nav_lat <  ${lp1}));" -s 'dz= ((depthw < -500)&&(depthw >= -1500));' moc_tmp.nc -o tmp0.nc
                    $NCAP -3 -O -h -s "x1=dlat*zomsfatl" tmp0.nc -o tmp1.nc
                    $NCAP -3 -O -h -s "max_amoc_${ll}N=dz*x1"   tmp1.nc -o tmp0.nc

                    # Maximum on this remaining y,depthw box:
                    echo "ncwa -O -y max -v max_amoc_${ll}N  -a y,depthw   tmp0.nc -o tmp.nc"
                    ncwa -O -y max -v max_amoc_${ll}N  -a y,depthw   tmp0.nc -o tmp.nc

                    $NCAP -3 -O -h -s "max_amoc_${ll}N@units=\"Sv\"" \
                        -s "max_amoc_${ll}N@long_name=\"Maximum of Atlantic MOC at ${ll}N\""  tmp.nc -o tmp.nc

                    rm -f tmp1.nc tmp0.nc

                    echo "ncks -3 -A -h -v time_counter time_${jyear}.nc -o tmp.nc"
                    ncks -3 -A -h -v time_counter time_${jyear}.nc -o tmp.nc

                    echo "ncks -3 -h -A -v max_amoc_${ll}N tmp.nc -o ${SUPA_Y}"
                    ncks -3 -h -A -v max_amoc_${ll}N tmp.nc -o ${SUPA_Y}

                    rm -f tmp*.nc

                done

                rm -f moc_tmp.nc

            else
                echo; echo " *** File ${f_in} not here! Skipping variable zomsfatl !"
            fi

            echo



            # Sea-Ice extent Arctic and Antarctic:
            ######################################

            echo
            echo "Doing Sea-Ice diag"

            cvar="iiceconc"
            f_in=$DATADIR/Post_????/${RUN}_${jyear}_${cvar}.nc

            # TODO does not work with ncap
            if [ -f ${f_in} ] && [ "$NCAP" == "ncap2" ] ; then

                rm -f tmp*.nc

                # Removing degenerate time dimension in mask.nc
                echo "ncks -3 -O -d z,0 -v tmask    mask.nc  -o tmp.nc"
                ncks -3 -O -d z,0 -v tmask    mask.nc  -o tmp.nc

                echo "ncks -3 -A -v nav_lon,nav_lat mask.nc  -o tmp.nc"
                ncks -3 -A -v nav_lon,nav_lat mask.nc  -o tmp.nc

                echo "ncwa -3 -O -a t,z tmp.nc mask_no_tz.nc ; rm tmp.nc"
                ncwa -3 -O -a t,z tmp.nc mask_no_tz.nc ; rm tmp.nc

                $NCAP -3 -A -h -s 'mN= (nav_lat >=  50);' mask_no_tz.nc -o mask_no_tz.nc
                $NCAP -3 -A -h -s 'mS= (nav_lat <= -45);' mask_no_tz.nc -o mask_no_tz.nc
                $NCAP -3 -A -h -s "tmasknorth=mN*tmask"   mask_no_tz.nc -o mask_no_tz.nc
                $NCAP -3 -A -h -s "tmasksouth=mS*tmask"   mask_no_tz.nc -o mask_no_tz.nc

                echo "ncks -3 -O -v tmasknorth,tmasksouth  mask_no_tz.nc   -o tmp0.nc ; rm -f mask_no_tz.nc"
                ncks -3 -O -v tmasknorth,tmasksouth  mask_no_tz.nc   -o tmp0.nc ; rm -f mask_no_tz.nc

                echo "ncks -A -v ${cvar} ${f_in} -o tmp0.nc"
                ncks -3 -A -v ${cvar} ${f_in} -o tmp0.nc

                #LOLO: REMOVE SOON  --------------------
                # If time-record is called "time_counter", renaming to "time"
                #ca=`ncdump -h tmp0.nc | grep UNLIMITED | grep time_counter`
                #if [ ! "${ca}" = "" ]; then
                #    echo "ncrename -h -d time_counter,time  tmp0.nc"
                #    ncrename -h -d time_counter,time  tmp0.nc
                #fi
                #ca=`ncdump -h tmp0.nc | grep time_counter.units`
                #if [ ! "${ca}" = "" ]; then
                #    echo "ncrename -h -v time_counter,time tmp0.nc"
                #    ncrename -h -v time_counter,time  tmp0.nc
                #fi
                #LOLO. --------------------


                # Must add e1t and e2t for surface!
                echo "ncks -3 -O -d z,0 -v e1t,e2t mesh_hgr.nc  -o tmp_e1t_e2t.nc"
                ncks -3 -O -d z,0 -v e1t,e2t mesh_hgr.nc  -o tmp_e1t_e2t.nc

                echo "ncwa -3 -O -a t tmp_e1t_e2t.nc -o tmp_e1t_e2t.nc"
                ncwa -3 -O -a t tmp_e1t_e2t.nc -o tmp_e1t_e2t.nc


                for hs in north south; do

                    cv=${cvar}_${hs}

                    echo "$NCAP -3 -h -O -s "${cv}=${cvar}*tmask${hs}"  tmp0.nc -o tmp_${hs}.nc"
                    $NCAP -3 -h -O -s "${cv}=${cvar}*tmask${hs}"  tmp0.nc -o tmp_${hs}.nc

                    echo "ncks -3 -A -v e1t,e2t tmp_e1t_e2t.nc tmp_${hs}.nc"
                    ncks -3 -A -v e1t,e2t tmp_e1t_e2t.nc tmp_${hs}.nc

                    echo "$NCAP -3 -h -O -s "area_ice_${hs}=${cv}*e1t*e2t" tmp_${hs}.nc -o tmp_${hs}.nc"
                    $NCAP -3 -h -O -s "area_ice_${hs}=${cv}*e1t*e2t" tmp_${hs}.nc -o tmp_${hs}.nc

                    $NCAP -3 -h -O -s "tot_area_ice_${hs}=area_ice_${hs}.total(\$y,\$x)" \
                        -s "tot_area_ice_${hs}@units=\"m^2\"" tmp_${hs}.nc -o tmp_${hs}.nc

                    echo "ncks -3 -A -h -v time_counter time_${jyear}.nc -o tmp_${hs}.nc"
                    ncks -3 -A -h -v time_counter time_${jyear}.nc -o tmp_${hs}.nc

                    echo "ncks -3 -h -A -v tot_area_ice_${hs} tmp_${hs}.nc -o ${SUPA_Y}"
                    ncks -3 -h -A -v tot_area_ice_${hs} tmp_${hs}.nc -o ${SUPA_Y}
                    
                done
                rm -f tmp0.nc  tmp_e1t_e2t.nc tmp_*.nc
                

            else
                echo; echo " *** File ${f_in} not here! Skipping variable ${cvar}!"
            fi



            echo " ${SUPA_Y} done..."; echo; echo

            #mv -f ${SUPA_Y} ${HERE}/ ; exit

        fi

        jyear=`expr ${jyear} + 1`

    done  # ${icontinue} -eq 1



    echo; echo; echo


    echo "ncrcat -h -O ${RUN}_*_time-series_ocean.tmp -o ${SUPA_FILE}"
    ncrcat -h -O ${RUN}_*_time-series_ocean.tmp -o ${SUPA_FILE}
    ncwa -O -a y,x ${SUPA_FILE} -o ${SUPA_FILE}


    ncrcat -O time_*.nc -o supa_time.nc
    echo "ncks -3 -A -h -v time_counter supa_time.nc -o ${SUPA_FILE}"
    ncks -3 -A -h -v time_counter supa_time.nc -o ${SUPA_FILE}

    rm -f ${RUN}_*_time-series_ocean.tmp time_*.nc supa_time.nc

    rm -rf ${TMPD}

    echo
    echo " Time series saved into:"
    echo " ${SUPA_FILE}"
    echo

    #Concatenate new and old files... 
    if [[ ! -z ${BASE_YEAR_INI:-} ]] ; then
         echo " Concatenate old and new netcdf files... " 
         ncrcat -h ${OLD_SUPA_FILE} ${SUPA_FILE} ${DIAG_D}/${RUN}_${BASE_YEAR_INI}_${YEAR_END}_time-series_ocean.nc
         rm ${OLD_SUPA_FILE} ${SUPA_FILE}
         export SUPA_FILE=${RUN}_${BASE_YEAR_INI}_${YEAR_END}_time-series_ocean.nc
         echo " Variables saved in ${RUN}_${BASE_YEAR_INI}_${YEAR_END}_time-series_ocean.nc " ; echo
    fi



fi # [ ${IPREPHTML} -eq 0 ]



if [ ${IPREPHTML} -eq 1 ]; then


    if [ ! -f ${SUPA_FILE} ]; then
        echo
        echo " PROBLEM: we cannot find ${SUPA_FILE} !!!"
        exit
    fi

    cd ${DIAG_D}/

    ${PYTHON} ${HERE}/scripts/plot_ocean_time_series.py


    # Configuring HTML display file:
    sed -e "s/{TITLE}/Ocean diagnostics for EC-Earth coupled experiment/g" \
        -e "s/{RUN}/${RUN}/g" -e "s/{DATE}/`date`/g" -e "s/{HOST}/`hostname`/g" \
        ${HERE}/scripts/index_ocean_skel.html > index.html


    if [ ! "${RHOST}" = "" ]; then
        echo "Preparing to export to remote host!"; echo
        cd ../
        tar cvf ocean.tar ocean
        ssh ${RUSER}@${RHOST} "mkdir -p ${RWWWD}"
        echo "scp ocean.tar ${RUSER}@${RHOST}:${RWWWD}/"
        scp ocean.tar ${RUSER}@${RHOST}:${RWWWD}/
        ssh ${RUSER}@${RHOST} "cd ${RWWWD}/; rm -rf ocean; tar xf ocean.tar 2>/dev/null; rm ocean.tar"
        echo; echo
        echo "Diagnostic page installed on remote host ${RHOST} in ${RWWWD}/ocean!"
        echo "( Also browsable on local host in ${DIAG_D}/ )"
        rm -rf ocean.tar
    else
        echo "Diagnostic page installed in ${DIAG_D}/"
        echo " => view this directory with a web browser (index.html)..."
    fi

    echo; echo

fi # [ ${IPREPHTML} -eq 1 ]
