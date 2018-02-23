function check_environment()
{
    # -- Sanity checks
    [[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_DATADIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_RUNDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_POSTDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_DIAGDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
    [[ -z "${ECE3_POSTPROC_MACHINE:-}" ]] && echo "User environment not set. See ../README." && exit 1
    echo -n
}
