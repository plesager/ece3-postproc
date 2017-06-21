#!/bin/bash

#==========================================================================================
#
# Dependencies:
#  *  NCO (netCDF Operator)
#  * CDO (Climate Data Operators). Only if coupled simulation data (needed for ocean fields)
#  * mask_drown_field.x of SOSIE.  Only if coupled simulation data (needed for ocean fields)
#
# Important, set the following variables to be adapted to your own environment:
# - POST_DIR
# - EMOP_CLIM_DIR
#
# What do you need as input files
# ===============================
#
#    In $POST_DIR:
#
# * files created by the cript XXX developed by Klaus W.
#   => one file per year per variable in the form <expname>_<YEAR>_<variable>.nc
#   => list of these "<variable>s" are given later in $LIST_V_3D_ATM $LIST_V_2D_ATM and $LIST_V_3D_ATM
#   => 3D fields are given on pressure levels!
#
#
#    In $DIR_EXTRA:
#
# * Gaussian weights and IFS land-sea mask for the given IFS gaussian resolution (N80, N128, ...)
#   => gauss_weights_N<GR>.nc, lsm_IFS_N<GR>.nc
#   => these files for resolution (N80 (T159) and N128 (T255) are provided in the sub-directory "extra"
#
# ...
#
# Will generate the following files:
# <expname>_01_climo.nc  <expname>_04_climo.nc  <expname>_07_climo.nc  <expname>_10_climo.nc  <expname>_ANN_climo.nc
# <expname>_02_climo.nc  <expname>_05_climo.nc  <expname>_08_climo.nc  <expname>_11_climo.nc  <expname>_DJF_climo.nc
# <expname>_03_climo.nc  <expname>_06_climo.nc  <expname>_09_climo.nc  <expname>_12_climo.nc  <expname>_JJA_climo.nc
#
# Each file should contain 12 monthly records for 8 3D fields and 46 2D fields !!!
#
#
#
# Author: Laurent Brodeau (laurent@misu.su.se), 2014
#
#==========================================================================================



# Getting list of available confs:
list_confs=`\ls ../conf_*.bash | sed -e "s|../conf_||g" -e "s|.bash||g"`


usage()
{
    echo
    echo "USAGE: `basename $0` -C <MY_SETUP> -R <EXP_NAME> -g <GAUSS_RES> -i <first_year> -e <last_year>"
    echo
    echo "              * <MY_SETUP>         => configuration settings"
    echo "                                    file ../../conf_<MY_SETUP>.bash must be here"
    echo "                          List of available MY_SETUP is:"
    echo "${list_confs}"
    echo
    echo "              * <EXP_NAME>       => name of your experiment (usually 4-character long)"
    echo "              * <GAUSS_RES>      => Gaussian resolution corresponding to IFS resolution (default = N80)"
    echo "                                           * N80   (T159, EC-Earth v2 default)"
    echo "                                           * N128  (T255, EC-Earth v3 default)"
    echo "                                           * N256  (T512, EC-Earth v3)"
    echo
    echo "   OPTIONS:"
    echo "      -h                         =>  print this message"
    echo
    exit
}

# Defaults
MY_SETUP=""
expname=""
YEAR1=""
YEAR2=""
GAUSS_RES="N80"

while getopts C:R:g:i:e:h option ; do
    case $option in
        C) MY_SETUP=${OPTARG}   ;;
        R) expname=${OPTARG}   ;;
        g) GAUSS_RES=${OPTARG} ;;
        i) YEAR1=${OPTARG}    ;;
        e) YEAR2=${OPTARG}    ;;
        h)  usage ;;
        \?) usage ;;
    esac
done

if [ "${MY_SETUP}" = "" -o "${expname}" = "" -o "${YEAR1}" = "" -o "${YEAR2}" = "" ]; then usage ; fi

echo
echo " *** Name of run = ${expname}"
echo " *** First year  = ${YEAR1}"
echo " *** Last year   = ${YEAR2}"
echo " *** Target grid = ${GAUSS_RES}"
echo; echo




fconfig="../conf_${MY_SETUP}.bash"
if [ ! -f ${fconfig} ]; then echo " ERROR: no configuration file found: ${fconfig}"; exit; fi
. ${fconfig}

echo; echo
echo " *** EMOP_DIR = ${EMOP_DIR}"
echo " *** POST_DIR = ${POST_DIR}"
echo " *** EMOP_CLIM_DIR = ${EMOP_CLIM_DIR}"
echo " *** DIR_EXTRA = ${DIR_EXTRA}"
echo " *** SOSIE_DROWN_EXEC = ${SOSIE_DROWN_EXEC}"
echo " *** MESH_MASK_ORCA = ${MESH_MASK_ORCA}"
echo
echo " *** requested fields for ocean:"
echo "   => ${LIST_V_2D_OCE}"
echo
echo " *** reqested 2D fields for atmosphere :"
echo "   => ${LIST_V_2D_ATM}"
echo
echo " *** reqested 3D fields for atmosphere :"
echo "   => ${LIST_V_3D_ATM}"
echo

export POST_DIR=`echo ${POST_DIR} | sed -e "s|<RUN>|${expname}|g"`
echo " *** Will read EC-Earth post-processed netcdf files into"; echo "   ${POST_DIR} "; echo

export EMOP_CLIM_DIR=`echo ${EMOP_CLIM_DIR} | sed -e "s|<RUN>|${expname}|g"`

echo; echo
sleep 5





DIR_CL=${EMOP_CLIM_DIR}/clim_${expname}_${YEAR1}-${YEAR2}
mkdir -p ${DIR_CL} ; rm -f ${DIR_CL}/*.tmp  ; rm -f ${DIR_CL}/*.nc

LM="01 02 03 04 05 06 07 08 09 10 11 12"





# Testing if the latitude dimension of a random input file matches GAUSS_RES...
# makes sense:
ca=`ncdump -h ${POST_DIR}/mon/Post_${YEAR1}/${expname}_${YEAR1}_msl.nc | grep 'lat = '` nlat=`echo ${ca} | sed -e s/'lat = '/''/g -e s/' ;'/''/g`
nlat_gauss=`echo ${GAUSS_RES} | sed -e s/'N'/''/g` ; nlat_gauss=`expr ${nlat_gauss} \* 2`
if [ ! ${nlat_gauss} -eq ${nlat} ]; then
    echo "PROBLEM: IFS files and specified gaussian resolution do not agree in size => ${nlat} vs ${nlat_gauss}  !!!"
    exit
fi

#echo "  ${nlat} vs ${nlat_gauss}"






# 1st, testing if that was a coupled run, ie if we can find ocean fields:
i_ocean=0
cf=${POST_DIR}/mon/Post_${YEAR1}/${expname}_${YEAR1}_sosstsst.nc
if [ -f ${cf} ]; then i_ocean=1 ; fi


# Now time for the atmospheric fields, first 3D and then 2D
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


jv=0
for var in ${LIST_V_3D_ATM}; do

    jv=`expr ${jv} + 1`

    cd ${DIR_CL}/

    case ${var} in
        "q")  varncar="Q"      ;;
        "r") varncar="RELHUM" ;;
        "t")  varncar="T"      ;;
        "u")  varncar="U"      ;;
        "v")  varncar="V"      ;;
        "z")  varncar="Z3"     ;;
        *  )  echo "ERROR: unknown 3D variable => ${var}"; exit ;;
    esac




    # Checking if post file for variable ${var} is there for first year,
    # skipping otherwize:
    cf_in=Post_${YEAR1}/${expname}_${YEAR1}_${var}.nc ; cf=${POST_DIR}/mon/${cf_in}

    if [ -f ${cf} ]; then

        echo; echo " Treating ${var} => ${varncar} !!!"


        jy=${YEAR1}
        while [ ${jy} -le ${YEAR2} ]; do

            cf_in=Post_${jy}/${expname}_${jy}_${var}.nc ; cf=${POST_DIR}/mon/${cf_in}

            if [ -f ${cf} ]; then
                echo "   => using ${cf} "
            else
                echo "ERROR: file ${cf} is missing !!!"; exit
            fi

            for cm in ${LM}; do
                
                echo "ncks -h -a -F -O -d time,${cm} ${cf} -o tmp.nc"
                ncks -h -a -F -O -d time,${cm} ${cf} -o tmp.nc
                # removing global attribute history:
                echo "ncatted -h -O -a history,global,d,, tmp.nc"
                ncatted -h -O -a history,global,d,, tmp.nc
                
                fo=./${varncar}_${expname}_${jy}${cm}.tmp
                if [ ! "${var}" = "${varncar}" ]; then
                    echo "ncrename -h -O -v ${var},${varncar} tmp.nc -o ${fo}"
                    ncrename -h -O -v ${var},${varncar} tmp.nc -o ${fo} ; rm -f tmp.nc
                else
                    mv -f tmp.nc ${fo}
                fi
            done
            jy=`expr ${jy} + 1`
        done


        for cm in ${LM}; do
            fclim=${expname}_${cm}_climo.nc
            if [ ${jv} -eq 1 ]; then
                echo "      => ncra -A -h ${varncar}_${expname}_*${cm}.tmp -o ${fclim}"
                ncra -A -h               ${varncar}_${expname}_*${cm}.tmp -o ${fclim}
            else
                echo "      => ncra -A -h -C -v ${varncar} ${varncar}_${expname}_*${cm}.tmp -o ${fclim}"
                ncra -A -h -C -v ${varncar} ${varncar}_${expname}_*${cm}.tmp -o ${fclim}
            fi
            rm -f ${varncar}_${expname}_*${cm}.tmp
        done


    else
        echo
        echo "WARNING: File ${cf} wasn't found, skipping variable ${var} => ${varncar} !!!"
        echo; echo
    fi

done















# 2D atmospheric fields:
#~~~~~~~~~~~~~~~~~~~~~~~~

for var in ${LIST_V_2D_ATM}; do

    cd ${DIR_CL}/

    case ${var} in
        "ps")   varncar="PS" ;;
        "msl")  varncar="PSL" ;;
        "tas")  varncar="TREFHT" ;;
        "e")    varncar="QFLX" ;;
        "uas")  varncar="U_REF" ;;
        "vas")  varncar="V_REF" ;;
        "stl1") varncar="TS" ;;
        "tcc")  varncar="CLDTOT" ;;
        "totp") varncar="PRECT" ;;
        "cp")   varncar="PRECC" ;;
        "lsp")  varncar="PRECL" ;;
        "ewss") varncar="TAUX" ;;
        "nsss") varncar="TAUY" ;;
        "sshf") varncar="SHFLX" ;;
        "slhf") varncar="LHFLX" ;;
        "ssrd") varncar="FSDS" ;;
        "strd") varncar="FLDS" ;;
        "ssr")  varncar="FSNS" ;;
        "str")  varncar="FLNS" ;;
        "tsr")  varncar="FSNT" ;;
        "ttr")  varncar="FLNT" ;;
        "tsrc") varncar="FSNTC" ;;
        "ttrc") varncar="FLNTC" ;;
        "ssrc") varncar="FSNSC" ;;
        "strc") varncar="FLNSC" ;;
        "lcc")  varncar="CLDLOW" ;;
        "mcc")  varncar="CLDMED" ;;
        "hcc")  varncar="CLDHGH" ;;
        "tcwv") varncar="TMQ" ;;
        "tclw") varncar="TGCLDLWP" ;;
        "tciw") varncar="TGCLDIWP" ;;
        "fal")  varncar="ALBEDO"  ;;

        *  ) echo "ERROR: unknown 3D variable => ${var}"; exit ;;
    esac



    cf_in=Post_${YEAR1}/${expname}_${YEAR1}_${var}.nc ; cf=${POST_DIR}/mon/${cf_in}

    if [ -f ${cf} ]; then

        echo; echo " Treating ${var} => ${varncar} !!!"

        jy=${YEAR1}
        while [ ${jy} -le ${YEAR2} ]; do
            cf_in=Post_${jy}/${expname}_${jy}_${var}.nc ; cf=${POST_DIR}/mon/${cf_in}
            if [ -f ${cf} ]; then
                echo "   => using ${cf} "
            else
                echo "ERROR: file ${cf} is missing !!!"; exit
            fi

            for cm in ${LM}; do

                ncks -h -a -F -O -d time,${cm} ${cf} -o tmp.nc
                ncatted -h -O -a history,global,d,, tmp.nc ; # removing global attribute history

                # Testing if no degenerate level dimension and variable of length 1:
                ca=`ncdump -h tmp.nc | grep "${var}("`
                for ctest in depth lev alt; do
                    cb=`echo $ca | grep "${ctest}, lat"`
                    if [ ! "${cb}" = "" ]; then
                        echo "Need to remove degenerate dimension ${ctest} from ${var}"
                        ncwa -O -h    -a ${ctest} tmp.nc  -o tmp2.nc ; rm -f tmp.nc  ; # removes lev dimension
                        ncks -O -h -x -v ${ctest} tmp2.nc -o tmp.nc  ; rm -f tmp2.nc ; # deletes lev variable
                        echo " => done!"
                    fi
                done

                fo=./${varncar}_${expname}_${jy}${cm}.tmp
                if [ ! "${var}" = "${varncar}" ]; then
                    ncrename -h -O -v ${var},${varncar} tmp.nc -o ${fo} ; rm -f tmp.nc
                else
                    mv -f tmp.nc ${fo}
                fi
                #echo "    ${fo} created"
            done
            jy=`expr ${jy} + 1`
        done

        for cm in ${LM}; do
            fclim=${expname}_${cm}_climo.nc
            echo "      => ncra -A -h -C -v ${varncar} ${varncar}_${expname}_*${cm}.tmp -o ${fclim}"
            ncra -A -h -C -v ${varncar} ${varncar}_${expname}_*${cm}.tmp -o ${fclim}
            rm -f ${varncar}_${expname}_*${cm}.tmp
        done


    else
        echo
        echo "WARNING: File ${cf} wasn't found, skipping variable ${var} => ${varncar} !!!"
        echo; echo
    fi

done





# Ocean fields if relevant
############################

if [ ${i_ocean} -eq 1 ]; then

    # GAUSS_RES in lower-case for CDO...
    GAUSS_RES_lc=`echo ${GAUSS_RES} | tr '[:upper:]' '[:lower:]'`

    for var in ${LIST_V_2D_OCE}; do

        cd ${DIR_CL}/

        case ${var} in
            "sosstsst") varncar="SST" ;;
            "iiceconc") varncar="ICEFRAC" ;;
            *  ) echo "ERROR: unknown 2D ocean variable => ${var}"; exit ;;
        esac



        rm -f tmp*.nc

        cf_in=Post_${YEAR1}/${expname}_${YEAR1}_${var}.nc ; cf=${POST_DIR}/mon/${cf_in}

        if [ -f ${cf} ]; then

            echo; echo " Treating ${var} => ${varncar} !!!"

            jy=${YEAR1}
            while [ ${jy} -le ${YEAR2} ]; do

                cf_in=Post_${jy}/${expname}_${jy}_${var}.nc ; cf=${POST_DIR}/mon/${cf_in}
                if [ -f ${cf} ]; then
                    echo "   => using ${cf} "
                else
                    echo "ERROR: file ${cf} is missing !!!"; exit
                fi
                
                # If time-record is called "time_counter", renaming to "time"
                #ca=`ncdump -h ${cf} | grep UNLIMITED | grep time_counter`
                #if [ ! "${ca}" = "" ]; then
                #    echo "ncrename -d time_counter,time ${cf}"
                #    ncrename -O -d time_counter,time ${cf} -o ./copy.tmp
                    cf="./copy.tmp"
                #fi


                if [ ! ${SOSIE_DROWN_EXEC} == "" ]; then

                    if [ `dirname ${MESH_MASK_ORCA}` = "." ]; then
                        MESH_MASK_ORCA="${NEMO_MESH_DIR}/${MESH_MASK_ORCA}"
                    fi

                    echo
                    # Ocean fields: Extrapolating sea-values over continents for cleaner plots...
                    #  => using DROWN routine of SOSIE interpolation package "mask_drown_field.x"
                    ncks -A -a -v time_counter,nav_lon,nav_lat ${cf} -o tmp.nc
                    ncatted -O -a coordinates,${var},o,c,"nav_lon nav_lat" tmp.nc
                    
                    cf="./tmp.nc"
                    echo
                fi

                # Need to interpolate on gaussian grid ${GAUSS_RES}:
                echo "cdo remapbil,${GAUSS_RES_lc} -selvar,${var} ${cf} tmp1.nc"
                $cdo remapbil,${GAUSS_RES_lc}       -selvar,${var} ${cf} tmp1.nc
                
                rm -f tmp.nc; echo
                
                
                for cm in ${LM}; do
                    ncks -h -a -F -O -d time,${cm} tmp1.nc -o tmp2.nc
                    ncatted -h -O -a history,global,d,, tmp2.nc ; # removing global attribute history
                    
                    fo=./${varncar}_${expname}_${jy}${cm}.tmp
                    if [ ! "${var}" = "${varncar}" ]; then
                        ncrename -h -O -v ${var},${varncar} tmp2.nc -o ${fo} ; rm -f tmp2.nc
                    else
                        mv -f tmp2.nc ${fo}
                    fi
                done
                rm -f tmp1.nc copy.tmp
                jy=`expr ${jy} + 1`
            done

            for cm in ${LM}; do
                fclim=${expname}_${cm}_climo.nc
                echo "      => ncra -A -h -C -v ${varncar} ${varncar}_${expname}_*${cm}.tmp -o ${fclim}"
                ncra -A -h -C -v ${varncar} ${varncar}_${expname}_*${cm}.tmp -o ${fclim}
                rm -f ${varncar}_${expname}_*${cm}.tmp
            done


        else
            echo
            echo "WARNING: File ${cf} wasn't found, skipping variable ${var} => ${varncar} !!!"
            echo; echo
        fi

    done   ; # for var in ${LIST_V_2D_OCE}; do

else
    echo
    echo "WARNING: it must be an atmosphere-only run because sst field is missing!!!"
    echo; echo
fi














function var_is_there()
{
    ca=`ncdump -h ${expname}_01_climo.nc | grep "float ${1}("`
    if [ "${ca}" = "" ]; then
        echo "0"
    else
        echo "1"
    fi
}







cd ${DIR_CL}/

pwd
ls
echo




# Wind module at 10m:
if [ ! `var_is_there WIND_MAG_SURF` -eq 1 ]; then
    if [ `var_is_there U_REF` -eq 1  -a  `var_is_there V_REF` -eq 1 ]; then
        echo; echo "Creating surface wind magnitude at 10m!"
        for cm in ${LM}; do
            ncap2 -s 'WIND_MAG_SURF=sqrt(U_REF*U_REF+V_REF*V_REF)' ${expname}_${cm}_climo.nc -o tmp.nc
            ncatted -O -a units,WIND_MAG_SURF,o,c,'m s**-1' tmp.nc
            ncatted -O -a long_name,WIND_MAG_SURF,o,c,'Surface Wind Magnitude' tmp.nc
            ncks -h -A -a -v WIND_MAG_SURF tmp.nc -o ${expname}_${cm}_climo.nc
            rm -f tmp.nc
        done
    else
        echo "U_REF or/and V_REF is/are missing!"; echo
    fi
else
    echo "WIND_MAG_SURF already there..."; echo
fi



# Adding TCW as the sum of: TCW = TMQ + TGCLDLWP + TGCLDIWP
if [ ! `var_is_there TCW` -eq 1 ]; then
    if [ `var_is_there TMQ` -eq 1 -a `var_is_there TGCLDLWP` -eq 1 -a `var_is_there TGCLDIWP` -eq 1 ]; then
        echo; echo "Creating total_column water (TCW)!"
        for cm in ${LM}; do
            # Unit !!!
            ncap2 -h -O -s 'TCW=TMQ+TGCLDLWP+TGCLDIWP' ${expname}_${cm}_climo.nc -o tmp.nc
            ncatted -O -a units,TCW,o,c,'kg m-2' tmp.nc
            ncatted -O -a long_name,TCW,o,c,'Total column water' tmp.nc
            ncks -h -A -a -v TCW tmp.nc -o ${expname}_${cm}_climo.nc
            rm -f tmp.nc
        done
    else
        echo "TMQ or/and TGCLDLWP or/and TGCLDIWP is missing!"; echo
    fi
else
    echo "TCW already there!"
fi


if [ ! `var_is_there SRFRAD` -eq 1 ]; then
    if [ `var_is_there FSNS` -eq 1 -a `var_is_there FLNS` -eq 1 ]; then
        echo; echo "Creating net radiation at surface (SRFRAD)!"
        for cm in ${LM}; do
            ncap2 -h -O -s 'SRFRAD=FSNS+FLNS' ${expname}_${cm}_climo.nc -o tmp.nc
            ncks -h -A -a -v SRFRAD tmp.nc -o ${expname}_${cm}_climo.nc
            rm -f tmp.nc
        done
    else
        echo "FSNS or/and FLNS is missing!"; echo
    fi
else
    echo "SRFRAD already there!"
fi

if [ ! `var_is_there LWCF` -eq 1 ]; then
    if [ `var_is_there FLNT` -eq 1 -a `var_is_there FLNTC` -eq 1 ]; then
        echo; echo "Creating TOA longwave cloud forcing (LWCF)!"
        for cm in ${LM}; do
            ncap2 -h -O -s 'LWCF=FLNT-FLNTC' ${expname}_${cm}_climo.nc -o tmp.nc
            ncks -h -A -a -v LWCF tmp.nc -o ${expname}_${cm}_climo.nc
            rm -f tmp.nc
        done
    else
        echo "FLNT or/and FLNTC is missing!"; echo
    fi
else
    echo "LWCF already there!"
fi


if [ ! `var_is_there SWCF` -eq 1 ]; then
    if [ `var_is_there FSNT` -eq 1 -a `var_is_there FSNTC` -eq 1 ]; then
        echo; echo "Creating TOA shortwave cloud forcing (SWCF)!"
        for cm in ${LM}; do
            ncap2 -h -O -s 'SWCF=FSNT-FSNTC' ${expname}_${cm}_climo.nc -o tmp.nc
            ncks -h -A -a -v SWCF tmp.nc -o ${expname}_${cm}_climo.nc
            rm -f tmp.nc
        done
    else
        echo "FSNT or/and FSNTC is missing!"; echo
    fi
else
    echo "SWCF already there!"
fi























LIST_CHANGE_SIGN="FLNT FLNTC FLNS FLNSC SHFLX LHFLX TAUX TAUY QFLX"
for field in ${LIST_CHANGE_SIGN}; do
    if [ `var_is_there ${field}` -eq 1 ]; then
        echo; echo "Changing sign of ${field}!"
        for cm in ${LM}; do
            ncap2 -h -O -s "${field}=${field}*-1" ${expname}_${cm}_climo.nc -o tmp.nc
            ncks -h -a -A -v ${field} tmp.nc ${expname}_${cm}_climo.nc
            rm -f tmp.nc
        done
    else
        echo "Field ${field} is missing!"; echo
    fi
done



if [ `var_is_there TGCLDLWP` -eq 1 ]; then
    echo; echo "Switching TGCLDLWP from kg/m^2 to g/m^2!"
    for cm in ${LM}; do
    # Unit !!!
        ncap2 -h -O -s 'TGCLDLWP=1000*TGCLDLWP' ${expname}_${cm}_climo.nc -o tmp.nc
        ncatted -O -a units,TGCLDLWP,o,c,'g/m^2' tmp.nc
        ncks -h -A -a -v TGCLDLWP tmp.nc -o ${expname}_${cm}_climo.nc
        rm -f tmp.nc
    done
else
    echo "TGCLDLWP is missing!"; echo
fi

if [ `var_is_there TGCLDIWP` -eq 1 ]; then
    echo; echo "Switching TGCLDIWP from kg/m^2 to g/m^2!"
    for cm in ${LM}; do
    # Unit !!!
        ncap2 -h -O -s 'TGCLDIWP=1000*TGCLDIWP' ${expname}_${cm}_climo.nc -o tmp.nc
        ncatted -O -a units,TGCLDIWP,o,c,'g/m^2' tmp.nc
        ncks -h -A -a -v TGCLDIWP tmp.nc -o ${expname}_${cm}_climo.nc
        rm -f tmp.nc
    done
else
    echo "TGCLDIWP is missing!"; echo
fi


if [ `var_is_there Z3` -eq 1 ]; then
    echo; echo "Switching Z3 from m^2/s^2 to m !"
    for cm in ${LM}; do
    # Unit !!!
        ncap2 -h -O -s 'Z3=Z3/9.8162' ${expname}_${cm}_climo.nc -o tmp.nc
        ncatted -O -a units,Z3,o,c,'m' tmp.nc
        ncks -h -A -a -v Z3 tmp.nc -o ${expname}_${cm}_climo.nc
        rm -f tmp.nc
    done
else
    echo "Z3 is missing!"; echo
fi


if [ `var_is_there OMEGA` -eq 0 ]; then
    if [ `var_is_there T` -eq 1 ]; then
        echo; echo "STUPID!!!"; echo " => creating OMEGA as 0xT !!!"
        for cm in ${LM}; do
            ncap2 -h -O -s 'OMEGA=T*0' ${expname}_${cm}_climo.nc -o tmp.nc
            ncks -h -A -a -v OMEGA tmp.nc -o ${expname}_${cm}_climo.nc
            rm -f tmp.nc
        done
    else
        echo "T is missing!"; echo
    fi
else
    echo "OMEGA (0) was correctly built from T!"; echo
fi


if [ `var_is_there FLNT` -eq 1 ]; then
    echo; echo "Creating FLUT as a simple copy of FLNT!"
    for cm in ${LM}; do
        ncap2 -h -O -s 'FLUT=FLNT' ${expname}_${cm}_climo.nc -o tmp.nc
        ncks -h -A -a -v FLUT tmp.nc -o ${expname}_${cm}_climo.nc
        rm -f tmp.nc
    done
else
    echo "FLNT is missing!"; echo
fi


if [ `var_is_there FLNTC` -eq 1 ]; then
    echo; echo "Creating FLUTC as a simple copy of FLNTC!"
    for cm in ${LM}; do
        ncap2 -h -O -s 'FLUTC=FLNTC' ${expname}_${cm}_climo.nc -o tmp.nc
        ncks -h -A -a -v FLUTC tmp.nc -o ${expname}_${cm}_climo.nc
        rm -f tmp.nc
    done
else
    echo "FLNTC is missing!"; echo
fi


if [ `var_is_there FSNT` -eq 1 ]; then
    echo; echo "Creating FSNTOA as a simple copy of FSNT!"
    for cm in ${LM}; do
        ncks -h -O -v FSNT ${expname}_${cm}_climo.nc -o tmp.nc
        ncrename -h -v FSNT,FSNTOA tmp.nc
        ncks -h -A -a -v FSNTOA tmp.nc -o ${expname}_${cm}_climo.nc
        rm -f tmp.nc
    done
else
    echo "FSNT is missing!"; echo
fi


if [ `var_is_there FSNTC` -eq 1 ]; then
    echo; echo "Creating FSNTOAC as a simple copy of FSNTC!"
    for cm in ${LM}; do
        ncks -h -O -v FSNTC ${expname}_${cm}_climo.nc -o tmp.nc
        ncrename -h -v FSNTC,FSNTOAC tmp.nc
        ncks -h -A -a -v FSNTOAC tmp.nc -o ${expname}_${cm}_climo.nc
        rm -f tmp.nc
    done
else
    echo "FSNTC is missing!"; echo
fi



if [ `var_is_there CLDTOT` -eq 1 ]; then
    echo; echo "Creating TCLDAREA as a simple copy of CLDTOT!"
    for cm in ${LM}; do
        ncks -h -O -v CLDTOT ${expname}_${cm}_climo.nc -o tmp.nc
        ncrename -h -v CLDTOT,TCLDAREA tmp.nc
        ncks -h -A -a -v TCLDAREA tmp.nc -o ${expname}_${cm}_climo.nc
        rm -f tmp.nc
    done
else
    echo "CLDTOT is missing!"; echo
fi


if [ `var_is_there Q` -eq 1 ]; then
    echo; echo "Creating SHUM as a simple copy of Q!"
    for cm in ${LM}; do
        ncks -h -O -v Q ${expname}_${cm}_climo.nc -o tmp.nc
        ncrename -h -v Q,SHUM tmp.nc
        ncks -h -A -a -v SHUM tmp.nc -o ${expname}_${cm}_climo.nc
        rm -f tmp.nc
    done
else
    echo "Q is missing!"; echo
fi






# Precipitation, AMWG expects precips to be in m/s !!!
#     => in the "post_process" files they come as "kg/m^2/s = mm/s"

for cvp in PRECT PRECC PRECL; do
    if [ `var_is_there ${cvp}` -eq 1 ]; then
        echo; echo "Switching ${cvp} from kg/m^2/s to m/s !"
        for cm in ${LM}; do
            ncap2 -h -O -s "${cvp}=${cvp}/1000." ${expname}_${cm}_climo.nc -o tmp.nc
            ncatted -O -a units,${cvp},o,c,'m/s' tmp.nc
            #ncks -O -h -x -v ${cvp} ${expname}_${cm}_climo.nc -o ${expname}_${cm}_climo.nc ; # deleting ${cvp} from clim file
            ncks -h -A -a -v ${cvp} tmp.nc -o ${expname}_${cm}_climo.nc  ; # adding new ${cvp} from clim file
            rm -f tmp.nc
        done
    else
        echo "${cvp} is missing!"; echo
    fi
done






if [ ${i_ocean} -eq 0 ] ; then
    for cv in SST ICEFRAC; do
        if [ `var_is_there PSL` -eq 1 ]; then
            echo; echo "Creating empty ${cv} field!"
            for cm in ${LM}; do
                ncap2 -h -O -s "${cv}=float(PSL*0.)" ${expname}_${cm}_climo.nc -o tmp.nc
                ncks -h -A -a -v ${cv} tmp.nc -o ${expname}_${cm}_climo.nc
                rm -f tmp.nc
            done
        else
            echo "PSL is missing!"; echo
        fi
    done
fi


echo


















# lolo lili check with resolution of grid specified in the command line!
# => GAUSS_RES


flsm=${DIR_EXTRA}/lsm_IFS_${GAUSS_RES}.nc
fgwh=${DIR_EXTRA}/gauss_weights_${GAUSS_RES}.nc
if [ ! -f ${flsm} ]; then echo "PROBLEM: ${flsm} is missing!!!"; exit; fi
if [ ! -f ${fgwh} ]; then echo "PROBLEM: ${fgwh} is missing!!!"; exit; fi

echo; echo "Adding gauss weight (gw)!"
for cm in ${LM}; do
    ncks -h -A -a -v gw ${fgwh} -o ${expname}_${cm}_climo.nc
done
echo


echo; echo "Adding land fraction (LANDFRAC)!"
for cm in ${LM}; do
    ncrename -O -h -v LSM,LANDFRAC ${flsm} -o tmp.nc
    ncks -h -A -a -v LANDFRAC tmp.nc -o ${expname}_${cm}_climo.nc
    rm -f tmp.nc
done
echo


echo; echo "Creating ocean surface fraction from LANDFRAC (OCNFRAC)!"
for cm in ${LM}; do
    ncap2 -h -O -s 'OCNFRAC=-(LANDFRAC-1)' ${expname}_${cm}_climo.nc -o tmp.nc
    ncks -h -A -a -v OCNFRAC tmp.nc -o ${expname}_${cm}_climo.nc
    rm -f tmp.nc
done
echo










# Flipping latitude and Adding global attributes:
echo; echo "Flipping latitude, correcting levels and adding global attributes source and case!"

for cm in ${LM}; do

    # removing the rif raf...
    ncatted -h -a history,global,d,c, ${expname}_${cm}_climo.nc
    ncatted -h -a CDO,global,d,c, ${expname}_${cm}_climo.nc
    ncatted -h -a CDI,global,d,c, ${expname}_${cm}_climo.nc
    ncatted -h -a NCO,global,d,c, ${expname}_${cm}_climo.nc


    ncatted -h -a Conventions,global,a,c,"CF-1.0"  ${expname}_${cm}_climo.nc
    ncatted -h -a source,global,a,c,"IFS"   ${expname}_${cm}_climo.nc
    ncatted -h -a case,global,a,c,"ECEarth-${expname}_${YEAR1}-${YEAR2}" ${expname}_${cm}_climo.nc

    # Flip latitude:
    ncpdq -O -h -a -lat ${expname}_${cm}_climo.nc ${expname}_${cm}_climo.nc


    # from Pa to hPa (and renaming to mb)
    ncap2 -h -O -s 'lev=lev/100' -s "lev@units=\"mb\"" ${expname}_${cm}_climo.nc -o ${expname}_${cm}_climo.nc


done
echo







echo; echo; echo
echo "Will build ANN DJF JJA !"
echo


cd ${DIR_CL}/

rm -f ${expname}_ANN_climo.nc ${expname}_DJF_climo.nc ${expname}_JJA_climo.nc *.nc.* *.tmp

echo "ANN..."
echo
ls ${expname}_*_climo.nc
echo 
echo "ncra -O ${expname}_*_climo.nc -o ${expname}_ANN_climo.nc"
ncra -O ${expname}_*_climo.nc -o ${expname}_ANN_climo.nc
echo

echo "DJF..."
echo "ncra -O ${expname}_12_climo.nc ${expname}_01_climo.nc ${expname}_02_climo.nc -o ${expname}_DJF_climo.nc"
ncra -O ${expname}_12_climo.nc ${expname}_01_climo.nc ${expname}_02_climo.nc -o ${expname}_DJF_climo.nc
echo

echo "JJA..."
echo "ncra -O ${expname}_06_climo.nc ${expname}_07_climo.nc ${expname}_08_climo.nc -o ${expname}_JJA_climo.nc"
ncra -O ${expname}_06_climo.nc ${expname}_07_climo.nc ${expname}_08_climo.nc -o ${expname}_JJA_climo.nc
echo



rm -f tmp_config.bash

echo; echo " Done !"
echo "2D Climato for run ${expname} stored into:"
echo "${DIR_CL}/"
echo

