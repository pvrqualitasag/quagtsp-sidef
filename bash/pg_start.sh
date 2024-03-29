#!/bin/bash
#' ---
#' title: Start Postgresql DB-Server
#' date:  2020-06-15 09:36:42
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless starting of a pg-server such that it can be restarted again. 
#'
#' ## Description
#' Starting instance of postgresql db-server.
#'
#' ## Details
#' The starting process should also include removing any pid or lockfiles.
#'
#' ## Example
#' ./pg_start.sh -d <data_dir> 
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
  $ECHO "Usage: $SCRIPT -d <data_directory> -l <log_directory>"
  $ECHO "  where -d <data_directory>  --  specify the data directory with which the pg-server is running (optional)"
  $ECHO "        -l <log_directory>   --  specify the log directory (optional)"
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

#' ### Obtain Postgres Version
#' Get the version of the installed pg instance
#+ get-pg-version-fun
get_pg_version () {
    log_msg 'get_pg_version' "collecting PG_version information ..."
    # we get here only after we have tested that there is only one
    # version of postgresql installed.
    # need PG_ALLVERSION  like 9.4 or 10
    # need PG_SUBVERSION  like 4
    # need PG_VERSION     like 9
    # need PG_PACKET      like postgresql_11
    PG_PACKET=$(dpkg -l postgresql*    | egrep 'ii ' |egrep "SQL database, version" |awk '{print $2}')
    PG_SUBVERSION=''
    if [ -n "$PG_PACKET"  ]; then
       if [[ $PG_PACKET = *9.* ]]; then
# subv wird packet bei 10 11 etc
          PG_SUBVERSION=$(dpkg -l postgresql*| egrep 'ii ' |egrep "SQL database, version" |awk '{print $2}'|sed -e 's/postgresql-9.//')
       else
          PG_SUBVERSION=' '
          echo no subversion
       fi
    fi

    PG_ALLVERSION=$(dpkg -l postgresql*| egrep 'ii ' |egrep "SQL database, version" |awk '{print $2}'|sed -e 's/postgresql-//')
    PG_VERSION=$(echo $PG_ALLVERSION |  cut -d. -f1)
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
DATADIR=/home/zws/tsp/pgdata
LOGDIR=/home/zws/tsp/pglog
while getopts ":d:l:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      if test -d $OPTARG; then
        DATADIR=$OPTARG
      else
        usage "$OPTARG isn't a directory"
      fi
      ;;
    l)
      if test -d $OPTARG; then
        LOGDIR=$OPTARG
      else
        usage "$OPTARG isn't a directory"
      fi
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

#' ## Checks for Command Line Arguments
#' The following statements are used to check whether required arguments
#' have been assigned with a non-empty value
#+ argument-test, eval=FALSE
if test "$DATADIR" == ""; then
  usage "-d <data_directory> not defined"
fi
if test "$LOGDIR" == ""; then
  usage "-l <log_directory> not defined"
fi

#' ### Determine Version of PG
#' The version of pg is determined
#+ get-pg-version
get_pg_version


#' ### Define Variable
#' Commands used with pg are defined with variables
#+ pg-var-def
PGCTL="/usr/lib/postgresql/$PG_ALLVERSION/bin/pg_ctl"
LOGFILE=$LOGDIR/`date +"%Y%m%d%H%M%S"`_postgres.log

#' ## Starting the pg-server
#' The pg-server is started with the pg_ctl command
#+ pg-server-start
$PGCTL -D $DATADIR -l $LOGFILE start



#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

