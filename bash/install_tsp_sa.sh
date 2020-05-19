#!/bin/bash
#' ---
#' title: Stand-Alone Installation Script For TheSNPPit (TSP)
#' date:  2019-12-17
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' TheSNPPit (TSP) software is installed as stand-alone containerized version 
#' with this script. The skeleton of TSP including the postgresql (PG) database 
#' are installed during a container build. The skeleton installation involves 
#' steps 1 to 5 of the README.install documentation that comes with the downloaded 
#' tarball. From step 6 only the first part is done up and until the creation of 
#' the TSP executable script. The remaining installation steps that involves 
#' configuring the database and creating the standard structure of the database 
#' is done later as a post-pull process inside of the instance of the container 
#' image.
#'
#' ## Description
#' From the singularity container definition (scd) file, this script is downloaded 
#' from the github-repository and stored in the extracted TSP-tarball. Then the 
#' build job executes this script which links the downloaded TSP-version to 
#' TheSNPpit_current and it creates an executable bash script which is stored in 
#' /usr/local/bin.
#'
#' ## Bash Settings
#+ bash-env-setting, eval=FALSE
# set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails


#' ## Global Constants
#' ### Paths to shell tools
#+ shell-tools, eval=FALSE
ECHO=/bin/echo                             # PATH to echo                            #
DATE=/bin/date                             # PATH to date                            #
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

#' ### Configure start
#' The items that cannot be used are commented out. 
#+ config-start
# BASE_DIR=/usr/local
CURR_VERSION=$(cat etc/VERSION)
LOCALBIN=/usr/local/bin
ADMINUSER=zws
ADMINGROUP=zws
DB_ENCODING=utf8
DB_NAME=TheSNPpit

#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT"
  $ECHO ""
  exit 1
}

#' ### Start Message
#' The following function produces a start message showing the time
#' when the script started and on which server it was started.
#+ start-msg-fun, eval=FALSE
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

#' ### Error and Exit
#' print errors in red on STDERR and exit
#+ err-exit
err_exit () {
    if [[ -t 2 ]] ; then
        printf '\E[31m'; echo "ERROR: $@"; printf '\E[0m'
    else
        echo "$@"
    fi >&2
    exit 1
}

#' ### Print Error On STDERR
#' print errors in red on STDERR
#+ print-error
error () {
    if [[ -t 2 ]] ; then
        printf '\E[31m'; echo "ERROR: $@"; printf '\E[0m'
    else
        echo "$@"
    fi >&2
}

#' ### Print OK
#' Print ok message
#+ print-ok
ok () {
    if [[ -t 2 ]] ; then
        printf '\E[32m'; echo "OK:    $@"; printf '\E[0m'
    else
        echo "$@"
    fi
}

#' ### Print Info Message
#' Print an info message to STDERR
#+ print-info
info () {
    if [[ -t 2 ]] ; then
        printf "\E[34mINFO:  %s\E[0m \n" "$@"
    else
        echo "INFO: $@"
    fi >&2
}

#' ### Determine Base Directory 
#' Find out were the base directory is.
#+ get-base-dir
get_base_dir () {
    BASE_DIR=$(pwd -P)
    BASE_DIR=$(echo $BASE_DIR |sed -e "s/TheSNPpit-$CURR_VERSION//")

    echo -n "Installing TheSNPpit in $BASE_DIR (Terminate with Ctrl-C): " && read 
    if [ ! -d $BASE_DIR ]; then
        mkdir -p $BASE_DIR
        info "$BASE_DIR created"
    fi
    info "Installing TheSNPpit in $BASE_DIR"
}


#' ### Check Current Version
#' The following check verifies that the current version of TheSNPPit is set
#+ check-cur-version-fun-def
check_current_version () {
  if [ -z "$CURR_VERSION" ]; then
    error    "This is not a distribution of TheSNPpit for installation"
    error    "or you are in the wrong directory."
    err_exit "Unknown version. Can't read etc/VERSION"
  else
    ok "TheSNPpit Version $CURR_VERSION"
  fi
}

#' ### Create Binary for TheSNPPit
#' A small shell script that is used to start TheSNPPit is created
#+ create-binary-fun-def
create_binary_snppit () {
  cat > $LOCALBIN/snppit <<EndOfSNPpitsh
#!/bin/bash
SNP_HOME=$SNP_HOME
exec ${SNP_HOME}/bin/TheSNPpit "\$@"

EndOfSNPpitsh
  # adjust permissions
  chmod 755 $LOCALBIN/snppit
  
}

#' ### Set Permissions
#' Permissions of directories for TSP are set. These permissions are adapted 
#' from the original installation script.
#+ set-permission-fun
set_permission () {
  find -L ${SNP_HOME}/ -type d -print0 |xargs -0 chmod 755
  find -L ${SNP_HOME}/ -type f -print0 |xargs -0 chmod 644
  chmod 755 ${SNP_HOME}/bin/*
  chmod 755 ${SNP_HOME}/contrib/bin/*
  mkdir -p ${SNP_HOME}/regression/tmp
  chmod 775 ${SNP_HOME}/regression/tmp
  chown -R -L ${ADMINUSER}:$ADMINGROUP $SNP_HOME
  chown ${ADMINUSER}:$ADMINGROUP /usr/local/bin/snppit
  chmod 755 /usr/local/bin/snppit
}

#' ### Checking Installation of Perl
#' Check whether perl is installed.
#+ check-perl-fun
check_perl () {
  perl -v >/dev/null
  if [ $? -eq 0 ]; then
    ok "Perl already installed"
  else
    error "Perl is not installed!"
    info "Installing Perl with dependencies ..."
    apt-get --yes install perl
  fi
}


#' ## Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ## Main Part Of Installation
#' The main steps of the installation start here. In a first step, we check
#' whether the current version is set
#+ cur-version-check
log_msg "$SCRIPT" "Checking whether current version is set ..."
check_current_version

#' ### Base Directory
#' The base directory is where TheSNPPit will be installed
#+ det-base-dir
log_msg "$SCRIPT" "Specifying base directory ..."
get_base_dir
SNP_HOME=${BASE_DIR}/TheSNPpit_current
SNP_LIB=${SNP_HOME}/lib
log_msg "$SCRIPT" "Defined SNP_HOME: $SNP_HOME"
log_msg "$SCRIPT" "Defined SNP_LIB: $SNP_LIB"

#' ### Link Installed Version
#' link latest version to TheSNPpit_current:
#+ link-latest
log_msg "$SCRIPT" "Linking current version ..."
if [ ! -e "$SNP_HOME" ]
then
  ln -snf ${BASE_DIR}/TheSNPpit-$CURR_VERSION $SNP_HOME
fi

#' ### Binary
#' create binary snppit:
#+ call-create-bin
log_msg "$SCRIPT" "Create binary ..."
create_binary_snppit

#' ### Setting Permissions
#' Permissions of TSP dirs and files are set
#+ set-permission
log_msg "$SCRIPT" "Set permissions ..."
set_permission

#' ### Check Perl
#' Check whether perl is installed
log_msg "$SCRIPT" "Check perl ..."
check_perl


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

