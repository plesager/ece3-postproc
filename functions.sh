function check_environment()
{
    # -- Sanity checks
    [[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo  "User environment ECE3_POSTPROC_TOPDIR not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_DATADIR:-}" ]] && echo "User environment ECE3_POSTPROC_DATADIR not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_POSTDIR:-}" ]] && echo "User environment ECE3_POSTPROC_POSTDIR not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_DIAGDIR:-}" ]] && echo "User environment ECE3_POSTPROC_DIAGDIR not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_MACHINE:-}" ]] && echo "User environment ECE3_POSTPROC_MACHINE not set. See ../README." && exit 1
    echo -n
}

eval_dirs() {
    #
    # Update NEMORESULTS and IFSRESULTS according to the NEMORESULTS0 and
    # IFSRESULTS0 templates.
    # 
    # Expect 1 argument: month number (b/w 1-12).
    # 
    # Require that expname, year, yref, and monthly_leg are defined, since
    # needed for the leg number.
    #
    # Anything else needed in the template must also be defined in the calling script.
    # 
    ! (( $# == 1 )) && echo "*EE* eval_dirs requires ONE argument" && exit 1
    local m=$1

    # This works with 1,2,3,4,6 and 12-month legs
    iLEGNB='$(printf "%03d\n" $(( (year-${yref})*(12/monthly_leg) + (m-1)/monthly_leg +1 )))'

    EXPID=$expname
    LEGNB=$(eval echo $iLEGNB)

    NEMORESULTS=$(eval echo $NEMORESULTS0)
    IFSRESULTS=$(eval echo $IFSRESULTS0)
}
