#!/bin/bash
#' ---
#' title: Singularity Pull and Post Installation
#' date:  "2019-10-15"
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' This script can be used to pull a given singularity container image from 
#' singularity hub (shub) and to run all post-installation steps, if any 
#' post-installation steps are defined. For the image in this repository, there 
#' are not post-installation tasks defined so far.
#'
#' The prerequisites for this script to run is to do a git clone of the `quagtsp-sidef`
#' repository from github into the directory /home/zws/simg. This also clones 
#' this script which then can be run directly from where it was cloned to.
#' 
#' ## Description
#' In a first step, the script checks whether the container image has already been 
#' pulled. That is done by checking whether the indicated image file already 
#' exists. As soon as the container image file is available on the server, 
#' the configuration files can be copied from the template directory to where 
#' they are supposed to be for the container instance.
#' 
#' ## Example
#' The following call does just a pull of a new container image
#' 
#' $ cd /home/zws/simg/img 
#' $  ./pull_post_simg.sh -i sitsp -n `date +"%Y%m%d"`_quagtsp.simg -s shub://pvrqualitasag/quagtsp-sidef -w /home/zws/simg/img/tsp
#'
#+ bash-env-setting, eval=FALSE
set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
#set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails

#' ## Global Constants
#' ### Paths to shell tools
#+ shell-tools, eval=FALSE
ECHO=/bin/echo                             # PATH to echo                            #
DATE=/bin/date                             # PATH to date                            #
BASENAME=/usr/bin/basename                 # PATH to basename function               #
DIRNAME=/usr/bin/dirname                   # PATH to dirname function                #

#' ### Directories
#+ script-directories, eval=FALSE
INSTALLDIR=`$DIRNAME ${BASH_SOURCE[0]}`    # installation dir of bashtools on host   #

#' ### Files
#+ script-files, eval=FALSE
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`       # Set Script Name variable                #

#' ### Hostname of the server
#+ server-hostname, eval=FALSE
SERVER=`hostname`                          # put hostname of server in variable      #

#' ### Configuration Files and Templates
#+ conf-file-templ, eval=FALSE
SIMGROOT=/home/zws/simg
IMGDIR=$SIMGROOT/img
SIMGLINK=$SIMGROOT/quagtsp.simg


#' ## Functions
#' In this section user-defined functions that are specific for this script are 
#' defined in this section.
#'
#' * title: Show usage message
#' * param: message that is shown
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -b <bind_path> -i <instance_name> -n <image_file_name> -s <shub_uri>"
  $ECHO "  where    -b <bind_path>        --   paths to be bound when starting an instance"
  $ECHO "           -i <instance_name>    --   name of the instance started from the image"
  $ECHO "           -n <image_file_name>  --   name of the image given after pulling it from shub"
  $ECHO "           -s <shub_uri>         --   URI of image on SHUB"
  $ECHO "  additional option parameters are"
  $ECHO "           -l                    --   Switch to indicate whether link to simg file should be added"
  $ECHO "           -t                    --   Start the instance from the pulled image"
  $ECHO "           -w <image_dir>        --   Specify alternative directory where image is stored"
  $ECHO ""
  exit 1
}

#' produce a start message
#+ start-msg-fun, eval=FALSE
start_msg () {
  $ECHO "********************************************************************************"
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "Server:  $SERVER"
  $ECHO
}

#' produce an end message
#+ end-msg-fun, eval=FALSE
end_msg () {
  $ECHO
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "********************************************************************************"
}

#' functions related to logging
#+ log-msg-fun, eval=FALSE
log_msg () {
  local l_CALLER=$1
  local l_MSG=$2
  local l_RIGHTNOW=`$DATE +"%Y%m%d%H%M%S"`
  $ECHO "[${l_RIGHTNOW} -- ${l_CALLER}] $l_MSG"
}

#' function to start an instance
#+ start-instance-fun, eval=FALSE
start_instance () {
  log_msg 'start_instance' " * Starting instance $INSTANCENAME ..."
  if [ "$BINDPATH" != "" ]
  then
    log_msg 'start_instance' " ** Added bind paths: $BINDPATH ..."
    singularity instance start --bind $BINDPATH $IMAGENAME $INSTANCENAME
  else
    singularity instance start $IMAGENAME $INSTANCENAME
  fi
  # check whether instance is running
  log_msg 'start_instance' " ** Check whether instance $INSTANCENAME is running ..."
  if [ `singularity instance list | grep $INSTANCENAME | wc -l` == "0" ]
  then
    log_msg 'start_instance' " ==> $INSTANCENAME is not running ==> stop here"
    exit 1
  else
    log_msg 'start_instance' " ==> $INSTANCENAME is running"
  fi
}

#' ### Image Pull Function
#' This function is used to pull an image
#+ image-pull-fun
image_pull () {
  if [ -f "$IMAGENAME" ]
  then
    log_msg $SCRIPT " * Found image: $IMAGENAME ..."
  else
    if [ "$SHUBURI" == "" ]
    then
      log_msg $SCRIPT " * -s <shub_uri> not specified, hence cannot pull ..."
    else
      log_msg $SCRIPT " * Pulling img from shub ..."
      singularity pull --name $IMAGENAME $SHUBURI
    fi    
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
BINDPATH=""
INSTANCENAME=""
STARTINSTANCE="FALSE"
IMAGENAME=""
SHUBURI=""
LINKSIMG="FALSE"
while getopts ":b:i:ln:s:w:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      BINDPATH=$OPTARG
      ;;
    i) 
      INSTANCENAME=$OPTARG
      ;;
    l)
      LINKSIMG="TRUE"
      ;;
    n)
      IMAGENAME=$OPTARG
      ;;
    s)
      SHUBURI=$OPTARG
      ;;
    t)
      STARTINSTANCE="TRUE"
      ;;
    w) 
      if [ -d "$OPTARG" ];then
        IMGDIR=$OPTARG
      else
        usage "-w <image_dir> does not seam to be a valid image directory"
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
if test "$IMAGENAME" == ""; then
  usage "variable image_file_name not defined"
fi
if test "$INSTANCENAME" == ""
then
  usage "variable instance_name not defined"
fi

#' ## Change Working Directory
#' Do everything from where image file is stored
#+ cd-wd, eval=FALSE
cd $IMGDIR


#' ## Image Pull From SHUB
#' Start by pulling the image from SHUB where the repository is specified 
#' by $SHUBURI. The image file will be stored in the file called $IMAGENAME
#' At some point, we had difficulties when $IMAGENAME contained also a path.
#' Most likely it is safer to just give an name of the image file. 
#+ image-pull, eval=FALSE
image_pull


#' ## Instance Start
#' Start an instance of the pulled image, if instance name specified
#+ instance-start, eval=FALSE
log_msg $SCRIPT " * Instance start ..."
INSTANCERUNNING=`singularity instance list | grep "$INSTANCENAME" | wc -l`
echo "Instance name: $INSTANCENAME"
log_msg $SCRIPT " * Running status of instance: $INSTANCENAME: $INSTANCERUNNING"
if [ "$INSTANCERUNNING" == "0" ] && [ "$STARTINSTANCE" == "TRUE" ]
then
  start_instance
fi


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg


