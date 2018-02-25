function check_environment()
{
    # -- Sanity checks
    [[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo  "User environment ECE3_POSTPROC_TOPDIR not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_DATADIR:-}" ]] && echo "User environment ECE3_POSTPROC_DATADIR not set. See ../README." && exit 1
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
    # Require that expname, year, yref, and months_per_leg are defined, since
    # needed for the leg number.
    #
    # Anything else needed in the template must also be defined in the calling script.
    # 
    ! (( $# == 1 )) && echo "*EE* eval_dirs requires ONE argument" && exit 1
    local m=$1

    # This works with 1,2,3,4,6 and 12-month legs
    iLEGNB='$(printf "%03d" $(( (year-${yref})*(12/months_per_leg) + (m-1)/months_per_leg +1 )))'

    # These are the valid tokens for the end user, and evaluated here
    EXPID=$expname
    LEGNB=$(eval echo $iLEGNB)

    NEMORESULTS=$(eval echo $NEMORESULTS0)
    IFSRESULTS=$(eval echo $IFSRESULTS0)

    # hiresclim2 output, and also default climatology ouput from EC-mean
    OUTDIR0=$(eval echo ${ECE3_POSTPROC_POSTDIR})

}
