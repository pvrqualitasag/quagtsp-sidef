#!/bin/bash
#' ---
#' title: Post Installation Script For Stand-Alone Version of TheSNPPit (TSP)
#' date:  2019-12-17
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' The stand-alone version of TSP is completely contained in a singularity 
#' container. This includes the postgresql (pg) database and the TSP software. 
#' Because we do not have root-permissions on our system, we have to setup and 
#' to configure the database in a special way. The database configuration and 
#' the setup of the database table structure is done in this script.
#'
#' ## Description
#' {Write a paragraph about how the problems are solved.}
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
SNP_HOME=/usr/local/TheSNPpit_current
SNP_LIB=${SNP_HOME}/lib
ADMINUSER=snpadmin
OSUSER=zws
# ADMINGROUP=snp
DB_ENCODING=utf8
DB_NAME=TheSNPpit
TEST_DB_NAME=TheSNPpit_test

TSPWORKDIR=/home/zws/tsp
PGDATADIR=${TSPWORKDIR}/pgdata
PGLOGDIR=${TSPWORKDIR}/pglog
LOGFILE=$PGLOGDIR/`date +"%Y%m%d%H%M%S"`_postgres.log
PGDATATRG='' # PGDATATRG=/qualstorzws01/data_tmp/tsp/pgdata
PGLOGTRG=''  # PGLOGTRG=/qualstorzws01/data_tmp/tsp/pglog
PG_PORT=''

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

#' ### Check Directory Existence
#' Passed directory is checked for existence, if it is not found stop
#+ check-exist-dir-fail-fun
check_exist_dir_fail () {
  local l_check_dir=$1
  if [  -d "$l_check_dir" ]
  then
    log_msg check_exist_dir_create "Found directory: $l_check_dir ==> ok"  
  else
    log_msg check_exist_dir_create "CANNOT find directory: $l_check_dir ==> stop"
    exit 1
  fi  
}

check_non_empty_dir_fail_create_non_exist () {
  local l_check_dir=$1
  if [ -d $l_check_dir ]
  then
    if [ `ls -1 $l_check_dir | wc -l` -gt 0 ]
    then
      err_exit "check_non_empty_dir_fail_create_non_exist: Data directory $l_check_dir exists and is non-empty ==> stop"
    fi
  else
    log_msg "check_non_empty_dir_fail_create_non_exist" " * Create data directory: $l_check_dir"
    mkdir -p $l_check_dir
  fi
  
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


#' ### Installation Of TheSNPPit Database
#' The database for TheSNPPit is installed
#+ install-thesnppit-db
install_thesnppit_db () {
    local l_DB_NAME=$1
    # does database exist?:
    $PSQL -l --tuples-only --quiet --no-align --field-separator=' '|awk '{print $1}' |grep "^${l_DB_NAME}$" >/dev/null
    if [ $? -eq 0 ]; then
        ok "TheSNPpit Database exists"
    else
        info "Creating TheSNPpit Database ..."
        $CREATEDB --encoding=$DB_ENCODING --owner=$ADMINUSER --no-password $l_DB_NAME

        # check again:
        $PSQL -l --tuples-only --quiet --no-align --field-separator=' '|awk '{print $1}' |grep "^${l_DB_NAME}$" >/dev/null
        if [ $? -eq 0 ]; then
            ok "TheSNPpit Database exists"
        fi

        # fill the newly created database with the structure:
        $PSQL -q -f ${SNP_LIB}/TheSNPpit.sql $l_DB_NAME -U $ADMINUSER
        if [ $? -eq 0 ]; then
            ok "TheSNPpit Database structure created"
        fi
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
    echo packet_____:$PG_PACKET
    echo version____:$PG_VERSION
    echo subversion_:$PG_SUBVERSION
    echo allversion_:$PG_ALLVERSION
}

#' ### Initialisation of the PG db-server
#' All initialisation steps are done in this function
#+ init-pg-server-fun
init_pg_server () {
  # check that data directory does not exist
  check_non_empty_dir_fail_create_non_exist $PGDATADIR
  # initialise a database for $OSUSER
  log_msg "init_pg_server" " * Init db ..."
  $INITDB -D $PGDATADIR -A trust -U $OSUSER
  if [ $? -eq 0 ]
  then
    ok "Initdb successful ..."
  else
    err_exit "Initdb was not possible"
  fi
}

#' ### Determine the port of pg
#' The port specified in /etc/postgres/10/main/postgres.conf is used
#+ get-pg-port-fun
get_pg_port () {
  PG_PORT=`grep '^port' $ETCPGCONF | cut -d '=' -f2 | cut -f1 | sed -e 's/ //'`
}

#' ### Setting the PG-Port
#' Make sure that the pg-port is the same as in the global config.
#+ set-pg-port-fun
set_pg_port () {
  # determine the pg-port from the global configuration
  get_pg_port
  # Set the same port in the local configuration
  LOCALCONF=$PGDATADIR/postgresql.conf
  # keep old version
  mv ${LOCALCONF} ${LOCALCONF}.org
  # if port setting is uncommented, comment it out
  if [ `grep '^port' ${LOCALCONF}.org | wc -l` -eq 1 ]
  then
    cat ${LOCALCONF}.org | sed -e 's/#port/port/' > ${LOCALCONF}
    mv ${LOCALCONF} ${LOCALCONF}.org
  fi
  # check whether port setting is commented out, then just add corrected port to the end
  if [ `grep '^#port' ${LOCALCONF}.org | wc -l` -eq 1 ]
  then
    (cat ${LOCALCONF}.org;echo "port = $PG_PORT") > ${LOCALCONF}
  fi
}

#' ### Start the PG db-server
#' After initialisation the pg-server must be started
#+ start-pg-server-fun
start_pg_server () {
  log_msg 'start_pg_server' ' * Starting pg-db-server ...'
  $PGCTL -D $PGDATADIR -l $LOGFILE start
  if [ $? -eq 0 ]
  then
    ok "PG server started successfully ..."
  else
    err_exit "Cannot start pg server ..."
  fi
}

#' ### Move data items
#' Data items are moved from original data directory to new data target
#+ mv-data-item-fun
mv_data_item () {
  # check whether target data dir exists
  check_non_empty_dir_fail_create_non_exist $PGDATATRG
  # move all files in $PGDATADIR to
  log_msg mv_data_item " * Create list of items ..."
  l_pglist=()
  ls -1 $PGDATADIR | while read e;
  do
    log_msg mv_data_item "   + Add item $e to list ..."
    l_pglist+=( $e )
  done
  cur_wd=`pwd`
  cd $PGDATADIR
  log_msg mv_data_item " * Move items from data dir to data trg ..."
  for f in "${l_pglist[@]}";
  do
    log_msg mv_data_item "   + Moving item $f ..."    
    mv $f $PGDATATRG
    log_msg mv_data_item "   + Linking $PGDATATRG/$f to $f ..."    
    ln -s $PGDATATRG/$f $f
    sleep 2;
  done
  cd $cur_wd
}

#' ### Check Status Of DB Server
#' Verification whether the pg DB-server is running or not
#+ pg-db-server-check-fun
pg_server_running () {
  if [ "$PG_PORT" != '' ]
  then
    $PGISREADY -h localhost -p $PG_PORT
  else
    $PGISREADY -h localhost 
  fi
  # check the return value
  if [ $? -eq 0 ]
  then
    ok "PG db-server is running ..."
  else
    err_exit "PG database server not running"
  fi
}

#' ### Access To DB
#' Check wheter we can access the database
#+ has-pg-access-fun
has_pg_access () {
    $PSQL -l >/dev/null 2>&1
    return $?
}

#' ### Check HBA Config
#' Check configuration in pag_hba.conf
#+ check-hba-conf-fun
check_hba_conf () {
    # save old pg_hba.conf and prepend a line:
    grep -q "^host  *all  *snpadmin .*trust$" $ETC_DIR/pg_hba.conf >/dev/null
    if [ $? -eq 0 ]; then
        ok "$ETC_DIR/pg_hba.conf already configured"
    else
        NOW=$(date +"%Y-%m-%d_%H:%M:%S")
        mv $ETC_DIR/pg_hba.conf $ETC_DIR/pg_hba.conf-saved-$NOW
        echo "# next line added by TheSNPpit installation routine ($NOW)" >$ETC_DIR/pg_hba.conf
        echo "# only these two lines are required, that standard configuration"
        echo "# as usually (2019) can be found the end can stay as is"
        # IPV4:
        echo "host  all   snpadmin   127.0.0.1/32   trust" >>$ETC_DIR/pg_hba.conf
        # IPV6:
        echo "host  all   snpadmin   ::1/128        trust" >>$ETC_DIR/pg_hba.conf
        cat $ETC_DIR/pg_hba.conf-saved-$NOW >>$ETC_DIR/pg_hba.conf
        info "Note: $ETC_DIR/pg_hba.conf saved to $ETC_DIR/pg_hba.conf-saved-$NOW and adapted"
        $PGCTL reload -D $DATA_DIR >/dev/null
    fi
}

#' ### Configure PG Database
#' Configuration of pg database
#+ config-pg-fun
configure_postgresql () {
    log_msg 'configure_postgresql' ' ** Start pg-db config ...'
    # create snpadmin with superuser privilege
    # info "Running configure_postgresql ..."
    # as of version 10 no subversion: postgresql-10: use the 10
    # VERSION is now version.subversion as used in ETC_DIR
    ETC_DIR="$PGDATADIR"
    if [ ! -d $ETC_DIR ]; then
        err_exit "ETC_DIR $ETC_DIR doesn't exist"
    fi
    # setting the port
    
    log_msg 'configure_postgresql' ' ** Checking pg-access ...'
    has_pg_access
    if [ $? -ne 0 ]; then
        error "You have no right to access postgresql ..."
    fi

    DATA_DIR=$(echo "show data_directory" | $PSQL --tuples-only --quiet --no-align postgres)
    if [ ! -d $DATA_DIR ]; then
        err_exit "DATA_DIR $DATA_DIR doesn't exist"
    fi

    echo "select usename from pg_user where usename = '$ADMINUSER'" | $PSQL postgres --tuples-only --quiet --no-align | grep -q $ADMINUSER >/dev/null
    if [ $? -eq 0 ]; then
        ok "PostgreSQL ADMINUSER $ADMINUSER exists"
    else
        $CREATEUSER --superuser $ADMINUSER
        $PGCTL reload -D $DATA_DIR >/dev/null
        ok "PostgreSQL ADMINUSER $ADMINUSER created"
    fi

    # save old pg_hba.conf and prepend a line:
    check_hba_conf
}

#' ## Check Status of TSP Binary
#' Verify that tsp-binary can be run without error
#+ check-tsp-bin-fun
check_tsp_bin () {
  log_msg 'check_tsp_bin' ' * Checking tsp-binary ...'
  snppit --help >/dev/null
  if [ $? -eq 0 ]; then
     ok "snppit now seems to run ok"
  else
     error "There seems to be a problem running snppit"
     exit 1
  fi
  
}

#' ## Run TSP-Tests
#' TSP is tested with given tests
#+ run-install-testdb-fun
run_install_testdb () {
  log_msg 'run_install_testdb' ' * Running tsp install_testdb ...'
  
  $SNP_HOME/bin/install_testdb
  if [ $? -eq 0 ]; then
    ok "===> Basic tests ok. Installation of TheSNPpit complete"
  else
    error "Basic tests failed."
 fi
  
}

#' ## Check Existence of TSP WorkDir
#' If working directory for tsp does not exist, create it
#+ check-tsp-workdir-fun
check_tsp_workdir () {
  log_msg 'check_tsp_workdir' ' ** Checking existence of tsp-workdir ...'
  if [ ! -d "$TSPWORKDIR" ]
  then
    log_msg 'check_tsp_workdir' ' ** Create tsp-workdir ...'
    $INSTALLDIR/init_tsp_workdir.sh
  else
    log_msg 'check_tsp_workdir' ' ** TSP-Workdir found ...'
  fi
}

#' ##  #################################################################### ###
#' ## 
#' ##    Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ### Determine Version of PG
#' The version of pg is determined
#+ get-pg-version
get_pg_version

#' ### Postgresql Programs
#' Explicit definitions of pg programs depending on pg version
#+ pg-prog-def
INITDB="/usr/lib/postgresql/$PG_ALLVERSION/bin/initdb"
PSQL="/usr/lib/postgresql/$PG_ALLVERSION/bin/psql"
CREATEDB="/usr/lib/postgresql/$PG_ALLVERSION/bin/createdb"
CREATEUSER="/usr/lib/postgresql/$PG_ALLVERSION/bin/createuser"
PGCTL="/usr/lib/postgresql/$PG_ALLVERSION/bin/pg_ctl"
PGISREADY="/usr/lib/postgresql/$PG_ALLVERSION/bin/pg_isready"
ETCPGCONF="/etc/postgresql/$PG_ALLVERSION/main/postgresql.conf"

#' ### Check Existence of TSP-Working-Dir
#' Data-directory and Log-directory of pg are put into a working directory.
#' The following function checks whether this directory exists or not
#+ check-tsp-workdir
log_msg "$SCRIPT" "Check whether TSP-workdir exist ..."
check_tsp_workdir


#' ### Initialisation of PG-DB
#' The configuration steps of the pg database that require to be run as 
#' user zws with its home directory available are done from here on.
#+ init-pg-server-call
log_msg "$SCRIPT" "Initialise the postgres db instance ..."
init_pg_server


#' ### Setting the port in the local configuration
#' The pg-port must be set to be consistent
#+ set-pg-port
#log_msg "$SCRIPT" "Set PG-Port ..."
#set_pg_port


#' ### Start the PG-db-server
#' After initialisation the db-server must be started
#+ start-pg-db-server
log_msg "$SCRIPT" ' * Starting pg server ...'
start_pg_server


#' ### Configure PG
#' Configurationf of pg database
#+ configure-pg
log_msg "$SCRIPT" ' * Configure pg db ...'
configure_postgresql


#' move data items from data directory to data target
#+ mv-data-item
if [ "$PGDATATRG" != "" ]
then
  log_msg "$SCRIPT" ' * Move data items ...'
  mv_data_item
fi


#' check whether the pg db-server is running
log_msg "$SCRIPT" ' * Check whether pg server is running ...'
pg_server_running


#' ### Check snppit binary
#' Check whether the tsp-binary can be run without an error
#+ check-tsp-bin
log_msg "$SCRIPT" ' * Check TSP binary ...'
check_tsp_bin


#' ### Run Basic Tsp-Tests
#' Similarily to regression tests, tsp installation is tested
#+ run-install-testdb
log_msg "$SCRIPT" ' * Run tsp testdb commands ...'
run_install_testdb


#' ### Install TSP Test Database
#' The test database for tsp is installed
#+ install-tsp-test-db
log_msg "$SCRIPT" ' * Install test DB ...'
install_thesnppit_db $TEST_DB_NAME


#' ### Install TSP Production Database
#' The production database for tsp is installed
#+ install-tsp-prod-db
log_msg "$SCRIPT" ' * Install production DB ...'
install_thesnppit_db $DB_NAME


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

