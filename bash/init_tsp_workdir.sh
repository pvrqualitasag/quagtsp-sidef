#!/bin/bash
#' ---
#' title: Initialisation of TSP Working Directory
#' date:  2020-06-11 08:48:33
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless setup process for tsp infrastructure.
#'
#' ## Description
#' Initialisation of working directory for the tsp database. The working directory contains subdirectories for data and logfiles.
#'
#' ## Details
#' Before creating an instance of a tsp-singularity-container, we have to prepare the local directory infrastructure for the tsp-pg-database.
#'
#' ## Example
#' ./init_tsp_workdir.sh -w ${HOME}/tsp
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
  $ECHO "Usage: $SCRIPT -d <tsp_data_dir> -l <tsp_log_dir> -r <tsp_reg_temp> -t <tsp_log_dir> -w <tsp_work_dir> -f"
  $ECHO "  where -d <pg_data_dir>   --  specify the data directory for the pg database (optional)"
  $ECHO "        -l <pg_log_dir>    --  specify the log directory for the pg database (optional)"
  $ECHO "        -m <mv_trg_dir>    --  specify the move-items target directory (optional)"
  $ECHO "        -r <tsp_reg_temp>  --  specify the temporary regression directory (optional)"
  $ECHO "        -t <tsp_log_dir>   --  specify tsp log directory (optional)"
  $ECHO "        -w <tsp_work_dir>  --  specify the workdir for tsp (optional)"
  $ECHO "        -f                 --  use the defaults specified in the script (optional)"
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

#' ### Create Dir 
#' Specified directory is created, if it does not yet exist
#+ check-exist-dir-create-fun
check_exist_dir_create () {
  local l_check_dir=$1
  if [ ! -d "$l_check_dir" ]
  then
    log_msg check_exist_dir_create "CANNOT find directory: $l_check_dir ==> create it ..."
    $MKDIR -p $l_check_dir
  else
    log_msg check_exist_dir_create "FOUND directory: $l_check_dir ..."
  fi  

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
TSPWORKDIRDEFAULT=${HOME}/tsp
USEDEFAULTS='FALSE'
TSPWORKDIR=''
DATADIR=''
LOGDIR=''
TSPLOGDIR=''
TSPREGTMP=''
MVTRGDIR=''
while getopts ":d:l:m:r:t:w:fh" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      DATADIR=$OPTARG
      ;;  
    f)
      USEDEFAULTS='TRUE'
      ;;
    l)
      LOGDIR=$OPTARG
      ;;  
    m)
      MVTRGDIR=$OPTARG
      ;;  
    r)
      TSPREGTMP=$OPTARG
      ;;
    t)
      TSPLOGDIR=$OPTARG
      ;;  
    w)
      TSPWORKDIR=$OPTARG
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


#' ## Update Directories
#' If the data directory and the log directory were not specified, then 
#' define them based on the TSPWORKDIR
#+ update-dir
if [ "$USEDEFAULTS" == 'TRUE' ]
then
  if [ "$TSPWORKDIR" == "" ]
  then
    TSPWORKDIR=${TSPWORKDIRDEFAULT}
  fi
  if [ "$DATADIR" == "" ]
  then
    DATADIR=${TSPWORKDIR}/pgdata
  fi
  if [ "$LOGDIR" == "" ]
  then
    LOGDIR=${TSPWORKDIR}/pglog
  fi
  if [ "$TSPLOGDIR" == "" ]
  then
    TSPLOGDIR=${TSPWORKDIR}/tsplog
  fi
  if [ "$TSPREGTMP" == "" ]
  then
    TSPREGTMP=${TSPWORKDIR}/tspregtmp
  fi  
fi

#' ## Create TSP Working Directory
#' Create TSP working directory, if it does not exist
#+ check-create-tsp-workdir
if [ "$TSPWORKDIR" != "" ]
then
  check_exist_dir_create $TSPWORKDIR
fi
if [ "$DATADIR" != "" ]
then
  check_exist_dir_create $DATADIR
fi  
if [ "$LOGDIR" != "" ]
then
  check_exist_dir_create $LOGDIR
fi  
if [ "$TSPLOGDIR" != "" ]
then
  check_exist_dir_create $TSPLOGDIR
fi  
if [ "$TSPREGTMP" != "" ]
then
  check_exist_dir_create $TSPREGTMP
fi
if [ "$MVTRGDIR" != "" ]
then
  check_exist_dir_create $MVTRGDIR
fi


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

