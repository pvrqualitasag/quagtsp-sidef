#!/bin/bash
#' ---
#' title: Cleanup of TSP Installation
#' date:  2020-06-16 09:16:47
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless cleanup process of installation output.
#'
#' ## Description
#' Cleanup output and logfiles after installation of tsp.
#'
#' ## Details
#' During the installation, regression tests are run and a demo script is run to test the functionality of TSP. The output of all these processes are deleted with this script.
#'
#' ## Example
#' ./clean_up_tsp_install.sh
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



#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -p <pattern_list>"
  $ECHO "  where -p <pattern_list>  --  list of patterns to be cleaned up (optional)"
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


#' ## Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
PATSTRING=''
while getopts ":p:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    p)
      PATSTRING=$OPTARG
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


#' ## Define Pattern To Be Cleanedup
#' The following list of patterns is used to cleanup
if [ "$PATSTRING" == "" ]
then
  patlist=('gs_001.ss_001.is_001.*' 'SNPpit-*.log' 'wk0125.*')
else
  patlist=()
  for f in `echo $PATSTRING | sed -e "s/,/\n/"`
  do
    patlist=("${patlist[@]}" $f)
  done
fi


#' ## Do the Cleanup
#' Loop over patlist and delete content
#+ cleanup
for p in "${patlist[@]}"
do
  log_msg "$SCRIPT" " * Cleanup pattern: $p ..."
  log_msg "$SCRIPT" " * Should the following items be deleted [y/n] ..."
  ls -la "$p"
  read answer
  if [ "$answer" == "y"]
  then
    log_msg "$SCRIPT" " * Deleting items matchin $p ..."
    rm -rf $p
  fi
done



#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

