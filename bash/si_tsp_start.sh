#!/bin/bash
#' ---
#' title: Singularity TheSNPpit Start Script
#' date:  2020-07-09 14:20:47
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless start process of tsp container together with database.
#'
#' ## Description
#' Singularity container instance containing TheSNPpit (tsp) is started including the postgresql database.
#'
#' ## Details
#' Depending on whether the database directory is empty, the database is initialised, otherwise it is just started.
#'
#' ## Example
#' ./si_tsp_start.sh -b <bind_path> -i <instance_name> -n <image_name>
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
  $ECHO "Usage: $SCRIPT -b <bind_path> -i <instance_name> -n <image_name>  -d <pg_data_dir>"
  $ECHO "  where -b <bind_path>      --  specify bind path between host and container (optional)"
  $ECHO "        -i <instance_name>  --  specify instance name                        (optional)"
  $ECHO "        -n <image_name>     --  specify name of image file                   (optional)"
  $ECHO "        -d <pg_data_dir>    --  postgresql data directory                    (optional)"
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
BINDPATH="/home/zws/tsp/tsplog:/usr/local/TheSNPpit-1.1.4/var/log,/home/zws/tsp/tspregtmp:/usr/local/TheSNPpit-1.1.4/regression/tmp,/qualstore03,/qualstorora01,/qualstororatest01,/qualstorzws01"
SINGULARITYINSTANCENAME=sitsp
SINGULARITYIMAGENAME=/home/zws/simg/tsp.img
PGDATADIR=/home/zws/tsp/pgdata
while getopts ":b:d:i:n:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      BINDPATH=$OPTARG
      ;;
    d)
      PGDATADIR=$OPTARG
      ;;
    i)
      INSTANCENAME=$OPTARG
      ;;
    n)
      IMAGEFILE=$OPTARG
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
if test "$SINGULARITYINSTANCENAME" == ""; then
  usage "-i <singularity_instance_name> not defined"
fi
if test "$SINGULARITYIMAGENAME" == ""; then
  usage "-n <singularity_image_name> not defined"
fi


#' ## Check Status of Instance
#' First check that the instance is not already running
#+ check-instance running
if [ `singularity instance list | grep $SINGULARITYINSTANCENAME | wc -l` -ne 0 ]
then
  usage " *** ERROR: Instance $SINGULARITYINSTANCENAME already running ..."
fi


#' ## Start Singularity Instance
#' Singularity instance is started
#+ singularity-instance-start
if [ "$BINDPATH" == '' ]
then
  log_msg "$SCRIPT" " * Starting singularity instance $SINGULARITYINSTANCENAME from image $SINGULARITYIMAGENAME ..."
  singularity instance start $SINGULARITYIMAGENAME $SINGULARITYINSTANCENAME
else
  log_msg "$SCRIPT" " * Starting singularity instance $SINGULARITYINSTANCENAME from image $SINGULARITYIMAGENAME using bind-path $BINDPATH ..."
  singularity instance start --bind $BINDPATH $SINGULARITYIMAGENAME $SINGULARITYINSTANCENAME
fi

#' ## Start PostgreSQL DB-Server
#' The pg-db inside the image is started using the start script
#+ pg-db-start
if [ `ls -1 $PGDATADIR | wc -l` -eq 0 ]
then
  log_msg "$SCRIPT" " * Initialise pg-db ..."
  singularity exec instance://$SINGULARITYINSTANCENAME $INSTALLDIR/post_install_tsp_sa.sh
else
  log_msg "$SCRIPT" " * Starting pg-db ..."
  singularity exec instance://$SINGULARITYINSTANCENAME $INSTALLDIR/pg_start.sh
fi

#' ## Check Status of DB-Server
#' Using the pg-command to check whether the DB-server is running
#+ pg-db-check
singularity exec instance://$SINGULARITYINSTANCENAME /usr/lib/postgresql/10/bin/pg_isready



#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

