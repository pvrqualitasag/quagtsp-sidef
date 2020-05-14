#!/bin/bash
###
###
###
###   Purpose:   Based on a singularity definition file build a new container
###   started:   2019-08-13 11:07:29 (pvr)
###
### ###################################################################### ###

set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails

# ======================================== # ======================================= #
# global constants                         #                                         #
# ---------------------------------------- # --------------------------------------- #
# prog paths                               #                                         #  
ECHO=/bin/echo                             # PATH to echo                            #
DATE=/bin/date                             # PATH to date                            #
BASENAME=/usr/bin/basename                 # PATH to basename function               #
DIRNAME=/usr/bin/dirname                   # PATH to dirname function                #
# ---------------------------------------- # --------------------------------------- #
# directories                              #                                         #
INSTALLDIR=`$DIRNAME ${BASH_SOURCE[0]}`    # installation dir of bashtools on host   #
# ---------------------------------------- # --------------------------------------- #
# files                                    #                                         #
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`       # Set Script Name variable                #
# ---------------------------------------- # --------------------------------------- #
# server name                              #                                         #
SERVER=`hostname`                          # put hostname of server in variable      #  
# ======================================== # ======================================= #



### # ====================================================================== #
# Function definitions local to this script
#==========================================
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -d <simg_definition> -w <work_dir>"
  $ECHO "  where    <simg_definition>     --  singularity definition file"
  $ECHO "           <work_dir> (optional) -- work directory where image is build"
  $ECHO ""
  exit 1
}

### # produce a start message
start_msg () {
  $ECHO "********************************************************************************"
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "Server:  $SERVER"
  $ECHO
}

### # produce an end message
end_msg () {
  $ECHO
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "********************************************************************************"
}

### # functions related to logging
log_msg () {
  local l_CALLER=$1
  local l_MSG=$2
  local l_RIGHTNOW=`$DATE +"%Y%m%d%H%M%S"`
  $ECHO "[${l_RIGHTNOW} -- ${l_CALLER}] $l_MSG"
}


### # ====================================================================== #
### # Main part of the script starts here ...
start_msg

### # ====================================================================== #
### # Use getopts for commandline argument parsing ###
### # If an option should be followed by an argument, it should be followed by a ":".
### # Notice there is no ":" after "h". The leading ":" suppresses error messages from
### # getopts. This is required to get my unrecognized option code to work.
SIMGDEF=""
SWORKDIR=/home/quagadmin/simg/img/thesnppit
while getopts ":d:w:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      SIMGDEF=$OPTARG
      ;;
    w)
      SWORKDIR=$OPTARG
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

# Check whether required arguments have been defined
if test "$SIMGDEF" == ""; then
  usage "-d <simg_definition> not defined"
fi


### # check whether working directory exists
if [ ! -d "$SWORKDIR" ]
then
  log_msg $SCRIPT " * Cannot find working directory: $SWORKDIR - create it"
  mkdir -p $SWORKDIR
  chown quagadmin:quagadmin $SWORKDIR
fi

### # change to work directory
CURRWD=`pwd`
cd $SWORKDIR

### # check whether definition file can still be found after cd
if [ ! -f "$SIMGDEF" ]
then
  log_msg $SCRIPT " * ERROR: Cannot find definition file: $SIMGDEF"
  exit 1
fi



### # create the image file
SIMGFN=`date +"%Y%m%d%H%M%S"`_quagtsp_ubuntu1804lts.img
log_msg $SCRIPT " * Creating image file: $SIMGFN ..."
singularity image.create --size 1024 $SIMGFN

### # start installation
log_msg $SCRIPT " * Installing based on definition: $SIMGDEF ..."
singularity build $SIMGFN $SIMGDEF &> `date +"%Y%m%d%H%M%S"`_quagtsp_ubuntu1804lts_build.log

### # change back to original directory
cd $CURRWD


### # ====================================================================== #
### # Script ends here
end_msg

