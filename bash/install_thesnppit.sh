#!/bin/bash
#' ---
#' title: Installation Script For TheSNPPit
#' date:  2019-12-12 16:29:54
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' TheSNPPit software is installed with this script. This should help to 
#' standardise the steps of the installation. This script is written for 
#' non-standard installations which do not follow the normal path as outlined 
#' in the description. The main difference between the installation that is 
#' implemented in this script and the standard installation is that here we 
#' are not able to get root access and hence, we do not have write access to 
#' the system directories such as /usr/local where the software is commonly 
#' installed. Furthermore, we cannot create new users or groups on the OS-level. 
#' Hence everything must be done with an ordinary non-root user. 
#'
#' ## Description
#' {Write a paragraph about how the problems are solved.}
#'
#' ## Bash Settings
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
BASENAME=/usr/bin/basename                 # PATH to basename function               #
DIRNAME=/usr/bin/dirname                   # PATH to dirname function                #
PSQL=psql
CREATEDB=createdb


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
ADMINUSER=snpadmin
OSUSER=zws
# ADMINGROUP=snp
DB_ENCODING=utf8
DB_NAME=TheSNPpit

LOCALBIN=/qualstorzws01/data_projekte/linuxBin

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

#' ### Installation Of TheSNPPit Database
#' The database for TheSNPPit is installed
#+ install-thesnppit-db
install_thesnppit_db () {
    # does database exist?:
    $PSQL -l --tuples-only --quiet --no-align --field-separator=' '|awk '{print $1}' |grep "^${DB_NAME}$" >/dev/null
    if [ $? -eq 0 ]; then
        ok "TheSNPpit Database exists"
    else
        info "Creating TheSNPpit Database ..."
        $CREATEDB --encoding=$DB_ENCODING --owner=$ADMINUSER --no-password $DB_NAME

        # check again:
        $PSQL -l --tuples-only --quiet --no-align --field-separator=' '|awk '{print $1}' |grep "^${DB_NAME}$" >/dev/null
        if [ $? -eq 0 ]; then
            ok "TheSNPpit Database exists"
        fi

        # fill the newly created database with the structure:
        $PSQL -q -f ${SNP_LIB}/TheSNPpit.sql $DB_NAME -U $ADMINUSER
        if [ $? -eq 0 ]; then
            ok "TheSNPpit Database structure created"
        fi
    fi

    # "host    TheSNPpit       snpadmin        127.0.0.1/32            trust"
    # /etc/postgresql/9.4/main/pg_hba.conf

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
  
}

#' ### Check for Multiple Postgres Installations
#' It is verified that only one version of PG is installed
#+ multiple-pg-check-fun
multiple_pg_installations () {
    info "checking for multiple postgresql versions"
    COUNT=$(dpkg -l postgresql* | egrep 'ii ' |egrep "object-relational SQL database, version" |wc -l)
    if [ $COUNT -gt 1 ]; then
        error "You have several installations of the PostgreSQL server"
        dpkg -l postgresql* | egrep 'ii ' |egrep "object-relational SQL database, version"
        info "Only one postgresq installation is allowed"
        info "BEWARE: you need a postgresql version >=9.3"
        err_exit "deinstall unwanted postgresql, Sorry!"
    fi
}

#' ### Obtain Postgres Version
#' Get the version of the installed pg instance
#+ get-pg-version-fun
get_pg_version () {
    info "collecting PG_version information"
    # we get here only after we have tested that there is only one
    # version of postgresql installed.
    # need PG_ALLVERSION  like 9.4 or 10
    # need PG_SUBVERSION  like 4
    # need PG_VERSION     like 9
    # need PG_PACKET      like postgresql_11
    PG_PACKET=$(dpkg -l postgresql*    | egrep 'ii ' |egrep "SQL database, version" |awk '{print $2}')

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
    echo packet_____:$PG_PACKET
    echo version____:$PG_VERSION
    echo subversion_:$PG_SUBVERSION
    echo allversion_:$PG_ALLVERSION
}


#' ### Perl Existence Check
#' Verification whether perl exists on the system
#+ perl-check-fun
check_perl () {
  perl -v >/dev/null
  if [ $? -eq 0 ]; then
      ok "Perl already installed"
  else
      error "Perl is not installed!"
      info "Perl needs to be installed before continuing ..."
      exit 1
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
# a_example=""
# b_example=""
# c_example=""
# while getopts ":a:b:ch" FLAG; do
#   case $FLAG in
#     h)
#       usage "Help message for $SCRIPT"
#       ;;
#     a)
#       a_example=$OPTARG
# OR for files
#      if test -f $OPTARG; then
#        a_example=$OPTARG
#      else
#        usage "$OPTARG isn't a regular file"
#      fi
# OR for directories
#      if test -d $OPTARG; then
#        a_example=$OPTARG
#      else
#        usage "$OPTARG isn't a directory"
#      fi
#       ;;
#     b)
#       b_example=$OPTARG
#       ;;
#     c)
#       c_example="c_example_value"
#       ;;
#     :)
#       usage "-$OPTARG requires an argument"
#       ;;
#     ?)
#       usage "Invalid command line argument (-$OPTARG) found"
#       ;;
#   esac
# done
# 
# shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

#' ## Checks for Command Line Arguments
#' The following statements are used to check whether required arguments
#' have been assigned with a non-empty value
#+ argument-test, eval=FALSE
# if test "$a_example" == ""; then
#   usage "-a a_example not defined"
# fi



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
ln -snf ${BASE_DIR}/TheSNPpit-$CURR_VERSION $SNP_HOME

#' ### Binary
#' create binary snppit:
#+ call-create-bin
log_msg "$SCRIPT" "Create binary ..."
create_binary_snppit

#' ### Checks related to PG
#' The first check verifies whether multiple instances of pg are installed.
#' The second function determines the version of the installed pg
#+ pg-check-call
log_msg "$SCRIPT" "Checking for postgres db installation ..."
multiple_pg_installations
get_pg_version
# operational version installed? if PG_PACKET set: may be more than 1!!
if [ -n "$PG_PACKET" ]; then
   if [ ${PG_VERSION} -eq 9 ] && [ ${PG_SUBVERSION} -le 3 ] ; then
       error "you need to have postgresql version > 9.3, sorry"
   fi
   ok "operational version of postgresql installed:" $PG_PACKET
else
   err_exit "Cannot find operational db installation" 
fi

#' ### Perl Existence Check
#' Call the function that verifies whether perl is installed
#+ perl-check-call
check_perl


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

