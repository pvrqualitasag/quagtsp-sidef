#!/bin/bash
#' ---
#' title: Install Bash Alias File
#' date:  2020-05-28 14:04:27
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless installation of .bash_alias file for a user {Write a paragraph about what problems are solved with this script.}
#'
#' ## Description
#' Install .bash_alias file for the user from a template {Write a paragraph about how the problems are solved.}
#'
#' ## Details
#' The template contains the possibility to have placeholders which are replaced by values {Give some more details here.}
#'
#' ## Example
#' ./install_bash_alias.sh {Specify an example call of the script.}
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
  $ECHO "Usage: $SCRIPT -t <template_path>"
  $ECHO "  where -t <template_path>  --  specify the path to the template"
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
TEMPLATE=""
b_example=""
c_example=""
while getopts ":t:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    t)
      if test -f $OPTARG; then
        TEMPLATE=$OPTARG
      else
        usage "$OPTARG isn't a regular file"
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
if test "$TEMPLATE" == ""; then
  usage "-t <template_file> not defined"
fi


#' ## Replacement of Place-holders
#' grep for placeholders
#+ replace-placeholders
# NRPH=$(grep '{' "$TEMPLATE" | wc -l)
# log_msg "$SCRIPT" " * Number of placeholders: $NRPH ..."

# place holders found or not
# if [ "$NRPH" != "0" ]
# then
#   log_msg "$SCRIPT" "RE"
#   cp $TEMPLATE ${TEMPLATE}.org
#   grep '{' "$TEMPLATE" | cut -d '{' -f2 | cut -d '}' -f1 | sort -u | while read e
#   do
#     log_msg "$SCRIPT" " * Replacing placeholder $e ..."
#     sed -i "s|"
#   done
# 
# else
# 
# fi

#' ## Install place-holders
#' Install template to alias file.
#+ install-bash-alias
log_msg $SCRIPT " * Installing bash alias file ..."
cp $TEMPLATE $HOME/.bash_aliases

#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

