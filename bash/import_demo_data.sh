#!/bin/bash
#' ---
#' title: Import Test Data
#' date:  2021-07-13 10:57:47
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' 
#'
#' ## Description
#' Run import statements for checking data imports
#'
#' ## Details
#' Import statements are taken from demo.bat
#'
#' ## Example
#' ./import_demo_data.sh
#'
#' ## Set Directives
#' General behavior of the script is driven by the following settings
#+ bash-env-setting, eval=FALSE
set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails


#' ## Global Constants
#' ### Paths to shell tools
#+ shell-tools, eval=FALSE
ECHO=/bin/echo                             # PATH to echo                            #
DATE=/bin/date                             # PATH to date                            #
MKDIR=/bin/mkdir                           # PATH to mkdir                           #
BASENAME=/usr/bin/basename                 # PATH to basename function               #
DIRNAME=/usr/bin/dirname                   # PATH to dirname function                #

#' ### Directories
#' Installation directory of this script
#+ script-directories, eval=FALSE
INSTALLDIR=`$DIRNAME ${BASH_SOURCE[0]}`    # installation dir of bashtools on host   #

#' ### Files
#' This section stores the name of this script and the
#' hostname in a variable. Both variables are important for logfiles to be able to
#' trace back which output was produced by which script and on which server.
#+ script-files, eval=FALSE
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`       # Set Script Name variable                #
SERVER=`hostname`                          # put hostname of server in variable      #


ADMINUSER=$USER
DEMODB=TheSNPpit_demo_$USER
SNP_HOME=${SNP_HOME-/usr/local/TheSNPpit_current}
SNP_LIB=${SNP_HOME}/lib
DB_ENCODING=utf8


#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -a <a_example> -b <b_example> -c"
  $ECHO "  where -a <a_example> ..."
  $ECHO "        -b <b_example> (optional) ..."
  $ECHO "        -c (optional) ..."
  $ECHO ""
  exit 1
}

#' ### Start Message
#' The following function produces a start message showing the time
#' when the script started and on which server it was started.
#+ start-msg-fun, eval=FALSE
start_msg () {
  $ECHO "********************************************************************************"
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "Server:  $SERVER"
  $ECHO
}

#' ### End Message
#' This function produces a message denoting the end of the script including
#' the time when the script ended. This is important to check whether a script
#' did run successfully to its end.
#+ end-msg-fun, eval=FALSE
end_msg () {
  $ECHO
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "********************************************************************************"
}

#' ### Log Message
#' Log messages formatted similarly to log4r are produced.
#+ log-msg-fun, eval=FALSE
log_msg () {
  local l_CALLER=$1
  local l_MSG=$2
  local l_RIGHTNOW=`$DATE +"%Y%m%d%H%M%S"`
  $ECHO "[${l_RIGHTNOW} -- ${l_CALLER}] $l_MSG"
}

# print errors in red on STDERR
error () {
    if [[ -t 2 ]] ; then
        printf '\E[31m'; echo "ERROR: $@"; printf '\E[0m'
    else
        echo "$@"
    fi >&2
}
##############################################################################
ok () {
    if [[ -t 2 ]] ; then
        printf '\E[32m'; echo "OK:    $@"; printf '\E[0m'
    else
        echo "$@"
    fi
}
##############################################################################
info () {
    if [[ -t 2 ]] ; then
        printf "\E[34mINFO:  %s\E[0m \n" "$@"
    else
        echo "INFO: $@"
    fi >&2
}
##############################################################################
check_for_root() {
    if [ ! $( id -u ) -eq 0 ]; then
        error "Must be run as root"
        exit 1
    fi
}

install_thesnppit_db () {
    # drop database first:
    dropdb --if-exists $DEMODB 2>&1 |grep -v NOTICE
    info "Creating TheSNPpit Demo Database ..."
    createdb --encoding=$DB_ENCODING --owner=$ADMINUSER --no-password $DEMODB

    # check again:
    psql -l --tuples-only --quiet --no-align --field-separator=' '|awk '{print $1}' |grep "^${DEMODB}$" >/dev/null
    if [ $? -eq 0 ]; then
        # fill the newly created database with the structure:
        psql -q -f ${SNP_LIB}/TheSNPpit.sql $DEMODB -U $ADMINUSER
        if [ $? -eq 0 ]; then
            ok "TheSNPpit Demo Database created"
        fi
    else
        error "Something went wrong while creating TheSNPpit Demo Database"
    fi

}


#' ## Main Body of Script
#' The main body of the script starts here with a start script message.
#+ start-msg, eval=FALSE
start_msg

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
while getopts ":h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    :)
      usage "-$OPTARG requires an argument"
      ;;
    ?)
      usage "Invalid command line argument (-$OPTARG) found"
      ;;
  esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

#' TSP-DB Installation
#' Installation of TSP DB and check for root
#+ install-tsp-db
log_msg $SCRIPT " * Installing db: $DEMODB ..."
install_thesnppit_db


#' ## SNP-Map Load
#' load panel map data from file picken.map and give it the name chk-57Illu
#+ load-map
ID="$SNP_HOME/regression/input"
snppit  -T $DEMODB -I panel -f ped -p chk-57Illu -i $ID/picken.map --skipheader


#' ## SNP-Data Load
#' load SNP data for the panel chk-57Illu from file picken.ped
#+ load-snp-data
snppit -T $DEMODB -I data  -f ped -p chk-57Illu -i $ID/picken.ped


#' ## Panel map data
#' load panel map data from 500000 panel
#+ load-panel-map
snppit -T $DEMODB -I panel -f ped -p 500000 -i $ID/00500000-00010.map


#' ## SNP-Data from Panel
#' load panel SNP data from 500000 panel 
#+ load-snp-panel
snppit -T $DEMODB -I data -f ped -p 500000 -i $ID/00500000-00010.ped


#' ## List Elements
#' list all genotype sets, snp_selection and individual_selection in the database
#+ list-all-elements
snppit -T $DEMODB -R genotype_set




#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

