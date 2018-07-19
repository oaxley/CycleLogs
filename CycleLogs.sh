# @file		CycleLogs.sh
# @author	Sebastien LEGRAND
# @date		2010-08-12
#
# @brief	Recycle logs directory weekly/monthly or yearly
# @history
#           2018-07-18 - 1.1.0 - SLE
#           Add 'last' business day link
#
#			2018-07-12 - 1.0.0 - SLE
#			Initial Version

#------ Globals

# determine program execution directory
SCRIPT_DIR=$(dirname $0)
[[ "${SCRIPT_DIR}" == "." ]] && SCRIPT_DIR=$(pwd)

# script name
SCRIPT_NAME=$(basename $0)
SCRIPT_SHORT_NAME=$(echo ${SCRIPT_NAME} | cut -d. -f1)

# version information
VERSION="1.0.0"

# script variables
CONFIG_FILE=""
PARAMETER=""


#------ Functions

# show help
function _help
{
    cat <<EOF
${SCRIPT_NAME} - Recycle logs directory regularly - ${VERSION}
Syntax:
    ${SCRIPT_NAME} [OPTIONS]

Specials symlinks 'today' & 'yesterday' will be created to reflect the current directory in use.
The previous business day will be represented by the symlink 'last'.

-- OPTIONS --

1. Specify the parameters on the command line with the following format:
    directory:<weekly|monthly|yearly>:<purge|compress>

directory : the directory to use for the logs recycling

period for keeping the logs:
    weekly  : the logs will be recycled every week
    monthly : the logs will be recycled every month
    yearly  : the logs will be recycled every year

behavior when recycling occurs:
    purge   : remove the logs from the directory
    archive : compress the logs, move them to .archive and remove the files from the directory

2. Use the '-f' (or --file) flag to load the configuration from a file:
    -f <configuration file>

One directory per line using the same format than the command line.
Comments '#' and empty lines are authorized in the file.

-- NOTES --

Script should be run everyday via crontab to update the current working directory
as well as the symlinks. It must be the 1st script executed in the morning.
Crontab example:
05 00 * * * \${HOME}/scripts/bin/CycleLogs.sh -f \${HOME}/scripts/conf/CycleLogs.conf
EOF
    exit 0
}

# weekly architecture
# $1 : a directory
function _createWeekly
{
    # create the directory and move inside
    mkdir -p "$1"
    pushd "$1" >/dev/null 2>&1

    # create the weekly directories
    mkdir -p Mon Tue Wed Thu Fri Sat Sun

    popd >/dev/null 2>&1
}

# monthly architecture
# $1 : a directory
function _createMonthly
{
    # create directory
    mkdir -p "$1"
    pushd "$1" >/dev/null 2>&1

    # create structure
    for i in $(seq 31)
    do
        DAY=$(printf "%02d" $i)
        mkdir -p ${DAY}
    done

    popd >/dev/null 2>&1
}

# yearly architecture
# $1 : a directory
function _createYearly
{
    # create the directory
    mkdir -p "$1"
    pushd "$1" >/dev/null 2>&1

    # create structure
    for i in $(seq 12)
    do
        MONTH=$(date -d "2010-$i-01" "+%m-%b")
        for j in $(seq 31)
        do
            DAY=$(printf "%02d" $j)
            mkdir -p ${MONTH}/${DAY}
        done
    done

    popd >/dev/null 2>&1
}

# create the architecture (main function)
# $1 : the directory where to create the architecture
# $2 : the period
function _createArchitecture
{
    # check for the marker inside the directory
    [[ -d "$1" && -e "$1/.${SCRIPT_SHORT_NAME}.$2" ]] && return

    case "$2" in
        "weekly")
            _createWeekly "$1"
            ;;
        "monthly")
            _createMonthly "$1"
            ;;
        "yearly")
            _createYearly "$1"
            ;;
        *)
            echo "Error: I don't know what to do with this period [$2]!"
            exit 1
            ;;
    esac

    # create the marker
    touch $1/.${SCRIPT_SHORT_NAME}.$2
}

# update the links
# $1 : a directory
# $2 : a period
# $3 : an action
function _updateLinks
{
    DIRECTORY="$1"
    PERIOD="$2"
    ACTION="$3"

    pushd "${DIRECTORY}" >/dev/null 2>&1

    # previous business day
    PREVIOUS_DAY=$(date "+%w")
    if [ $PREVIOUS_DAY == 1 ]; then
        LOOK_BACK=3
    else
        LOOK_BACK=1
    fi

    # compute the value for today/yesterday
    case "${PERIOD}" in
        "weekly")
            TODAY=$(date "+%a")
            YESTERDAY=$(date --date "yesterday" "+%a")
            LAST=$(date --date "${LOOK_BACK} day ago" "+%a")
            ;;
        "monthly")
            TODAY=$(date "+%d")
            YESTERDAY=$(date --date "yesterday" "+%d")
            LAST=$(date --date "${LOOK_BACK} day ago" "+%d")
            ;;
        "yearly")
            TODAY=$(date "+%m-%b/%d")
            YESTERDAY=$(date --date "yesterday" "+%m-%b/%d")
            LAST=$(date --date "${LOOK_BACK} day ago" "+%m-%b/%d")
            ;;
    esac

    # remove previous link
    rm -f today yesterday last

    # recreate the links
    ln -sf ${TODAY} today
    ln -sf ${YESTERDAY} yesterday
    ln -sf ${LAST} last

    # take the proper action for today
    pushd ${TODAY} >/dev/null 2>&1
    case "${ACTION}" in
        "purge")
            rm -f *
            ;;
        "archive")
            mkdir -p ${DIRECTORY}/.archive
            DATE=$(date "+%Y%m%d-%H%M%S")
            tar cpf - * 2>/dev/null | bzip2 -c > ${DIRECTORY}/.archive/${DATE}.tar.bz2 
            rm -f *
            ;;
    esac
    popd >/dev/null 2>&1
    popd >/dev/null 2>&1
}

# main function
# $1 : parameter
function _setDirectory
{
    DIRECTORY=$(echo $1 | cut -d: -f1)
    DIRECTORY=$(eval echo ${DIRECTORY})
    PERIOD=$(echo $1 | cut -d: -f2 | tr "[:upper:]" "[:lower:]")
    ACTION=$(echo $1 | cut -d: -f3 | tr "[:upper:]" "[:lower:]")

    # ensure that all the info is here
    if [[ -z ${DIRECTORY} || -z ${PERIOD} || -z ${ACTION} ]]; then
        echo "Error: Wrong format specified for the parameter!"
        exit 1
    fi

    # set the directory properly
    ROOT_DIR=$(dirname ${DIRECTORY})
    [[ "${ROOT_DIR}" == "." ]] && ROOT_DIR=$(pwd) && DIRECTORY=${ROOT_DIR}/${DIRECTORY}

    # execute the functions
    _createArchitecture "${DIRECTORY}" "${PERIOD}"
    _updateLinks "${DIRECTORY}" "${PERIOD}" "${ACTION}"
}


#------ Begin

# no arguments provided
if [ $# -eq 0 ]; then
    _help
    exit 0
fi

# check command line arguments
while [ $# -gt 0 ]
do
    case "$1" in
        "-f"|"--file")
            shift
            CONFIG_FILE=$1
            shift
            ;;
        "-h"|"--help")
            _help
            ;;
        *)
            PARAMETER=$1
            shift
            ;;
    esac
done

# if file has been provided, ignore the parameter
[[ "${CONFIG_FILE}" != "" ]] && PARAMETER=""

# a parameter has been provided
if [ "${PARAMETER}" != "" ]; then
    _setDirectory "${PARAMETER}"
fi

# read parameters from the file
if [ "${CONFIG_FILE}" != "" ]; then
    REGEXP='^$|^#'
    while read LINE
    do
        # remove empty lines and comments
        [[ $LINE =~ $REGEXP ]] && continue
        _setDirectory "${LINE}"
    done < "${CONFIG_FILE}"
fi