#!/bin/bash
##############################################################################
# this loads a chicken Illumina data set in Plink format
# into the snppit testdatabase from where it is exported again.
# here, both ped and map files are compared for identity.
# the export has an added blank at the end (-Z takes care of that)
#
# This is also a test if the bit manipulation in the export
# C code works on this hardware (correct endian).
# bash endian_test [quiet] generates no output but only returns 0 for all
# tests passed and 1 for error
# input parameter:
#    1. quiet    # reduce verbosity
#    2. keep     # keeps the temporary test database. You have to drop it by
#                # yourself.
##############################################################################


### Copyright #############################################################{{{
# Copyright 2011-2016 Cong V.C. Truong, Helmut Lichtenberg, Eildert Groeneveld
#
# This file is part of the software package TheSNPpit.
#
# TheSNPpit is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version.
#
# TheSNPpit is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# TheSNPpit.  If not, see <http://www.gnu.org/licenses/>.
#
# Authors:
# Cong V.C. Truong
# Helmut Lichtenberg (helmut.lichtenberg@fli.de)
# Eildert Groeneveld (eildert.groeneveld@gmx.de)
###########################################################################}}}

LOCALBIN=/qualstorzws01/data_projekte/linuxBin
SNP_HOME=${SNP_HOME-$LOCALBIN/TheSNPpit_current}

if [ ! -d "$SNP_HOME" ]; then
    echo "SNP_HOME is not set and/or $SNP_HOME is not your installation root"
    echo "Terminated!"
    exit
fi

# some helper functions:
##############################################################################
# print errors in red on STDERR
error () {
    if [[ -t 2 ]] ; then
        printf '\E[31m'; echo "ERROR: $@"; printf '\E[0m'
    else
        echo "$@"
    fi >&2
}
##############################################################################
# print errors in red on STDERR
err_exit () {
    if [[ -t 2 ]] ; then
        printf '\E[31m'; echo "ERROR: $@"; printf '\E[0m'
    else
        echo "$@"
    fi >&2
    exit
}
##############################################################################
ok () {
    if [[ -t 2 ]] ; then
        printf '\E[32m'; echo "OK:    $@"; printf '\E[0m'
    else
        echo "$@"
    fi
}
##############################################################################
info () {
    if [[ -t 2 ]] ; then
        printf "\E[34mINFO:  %s\E[0m \n" "$@"
    else
        echo "INFO: $@"
    fi >&2
}
##############################################################################
get_logdir () {
    DIRS="${SNP_HOME}/var/log . /tmp"
    for dir in $DIRS; do
        test -w $dir && echo $dir && return
    done
}
##############################################################################

LOGDIR=$(get_logdir)
LOG="${LOGDIR}/install_testdb.log"
echo "Writing installation logfile to $LOG" && sleep 3

NOW=$(date +"%Y-%m-%d %H:%M:%S")
echo "Starting $0 at $NOW" >$LOG

TEST_DB="snppit-$$"
INDIR="$SNP_HOME/regression/input/"
TMPDIR="$SNP_HOME/regression/tmp/"
test -d $TMPDIR || mkdir -p $TMPDIR

if [ "xx$1" == 'xxquiet' -o "xx$2" == 'xxquiet' ]; then
    QUIET='quiet'
fi
if [ "xx$1" == 'xxkeep' -o "xx$2" == 'xxkeep' ]; then
    KEEP='keep'
fi
ALLOK=0

##############################################################################
[ "$QUIET" != "quiet" ] && info "Creating new TheSNPpit test database"
createdb $TEST_DB >>$LOG
if [ $? -ne 0 ]; then
    err_exit "Installing $TEST_DB failed"
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Filling TheSNPpit test database structure"
psql $TEST_DB -f $SNP_HOME/lib/TheSNPpit.sql >/dev/null 2>>$LOG
if [ $? -ne 0 ]; then
    err_exit "Installing $TEST_DB database structure failed"
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Loading panel chk-57Illu"
snppit -q -T $TEST_DB -I panel -f ped -p chk-57Illu --skipheader -i $INDIR/picken.map >/dev/null 2>>$LOG
if [ $? -ne 0 ]; then
    err_exit "Inserting panel chk-57Illu failed"
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Loading data for chk-57Illu"
snppit -q -T $TEST_DB -I data  -f ped -p chk-57Illu -i $INDIR/picken.ped >/dev/null 2>>$LOG
if [ $? -ne 0 ]; then
    err_exit "Inserting data for panel chk-57Illu failed"
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Exporting data from chk-57Illu"
snppit -q -T $TEST_DB -E genotype_set --name gs_001 -o $TMPDIR/picken-ex
if [ $? -ne 0 ]; then
    err_exit "Exporting gs_001 failed"
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Comparing exported ped with original import file"
cat $TMPDIR/picken-ex.ped | sed -e "s/ \{1,\}$//"> $TMPDIR/yyyy
sort -nk 2 $TMPDIR/yyyy > $TMPDIR/picken-ex.sort
sort -nk 2 $INDIR/picken.ped > $TMPDIR/picken-im.sort
FAIL="OK"
if diff -Z $TMPDIR/picken-ex.sort $TMPDIR/picken-im.sort >/dev/null 2>>$LOG
then
    [ "$QUIET" != "quiet" ] && ok "job01: $NOW import/export ped Step 1: passed"
else
    [ "$QUIET" != "quiet" ] && error "job01: $NOW import/export ped Step 1: failed"
    FAIL="error";
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Comparing exported map with original import file"
if  diff -Z  -I '^#' $INDIR/picken.map $TMPDIR/picken-ex.map >/dev/null 2>>$LOG
then
    [ "$QUIET" != "quiet" ] && ok "job01: $NOW import/export map Step 2: passed"
else
    [ "$QUIET" != "quiet" ] && error "job01: $NOW import/export map Step 2: failed"
    FAIL="error";
fi

if [ "$FAIL" = 'OK' ]
then
    [ "$QUIET" != "quiet" ] && ok "AB 2.8 mio SNPs import and export files identical"
else
    ALLOK=1
    [ "$QUIET" != "quiet" ] && error "AB test failed. Do not use TheSNPpit on this hardware."
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Loading panel 500000"
snppit -q -T $TEST_DB -I panel -p 500000 -f ped -i $INDIR/00500000-00010.map >/dev/null 2>>$LOG
if [ $? -ne 0 ]; then
    err_exit "Inserting panel 500000 failed"
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Loading data for panel 500000"
snppit -q -T $TEST_DB -I data  -p 500000 -f ped -i $INDIR/00500000-00010.ped >/dev/null 2>>$LOG
if [ $? -ne 0 ]; then
    err_exit "Inserting data for panel 500000 failed"
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Exporting data from panel 500000"
snppit -q -T $TEST_DB -E genotype_set --name gs_002 -o $TMPDIR/500000-ex
if [ $? -ne 0 ]; then
    err_exit "Exporting gs_002 failed"
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Comparing exported ped with original import file"
cat $TMPDIR/500000-ex.ped | sed -e "s/ \{1,\}$//"> $TMPDIR/yyyy
sort -nk 2       $TMPDIR/yyyy > $TMPDIR/500000-ex.sort
sort -nk 2 $INDIR/00500000-00010.ped > $TMPDIR/500000-im.sort
FAIL="OK"
if diff -Z $TMPDIR/500000-ex.sort $TMPDIR/500000-im.sort >/dev/null 2>>$LOG
then
    [ "$QUIET" != "quiet" ] && ok "job02: $NOW import/export ped Step 1: passed"
else
    [ "$QUIET" != "quiet" ] && error "job02: $NOW import/export ped Step 1: failed"
    FAIL="error";
fi

##############################################################################
[ "$QUIET" != "quiet" ] && info "Comparing exported map with original import file"
# skip the AT column 5:
cat $INDIR/00500000-00010.map | tr -s ' ' |sed 's/^ *//g'|cut -d' ' -f1-4> $TMPDIR/500000-im.map
if  diff -Z -w -I '^#' $TMPDIR/500000-im.map $TMPDIR/500000-ex.map >/dev/null 2>>$LOG
then
    [ "$QUIET" != "quiet" ] && ok "job02: $NOW import/export map Step 2: passed"
else
    FAIL="error";
    [ "$QUIET" != "quiet" ] && error "job02: $NOW import/export map Step 2: failed"
fi

if [ "$FAIL" = 'OK' ]
then
    [ "$QUIET" != "quiet" ] && ok "ATGC - 50 mio SNPs, import and export files identical"
else
    ALLOK=1
    [ "$QUIET" != "quiet" ] && error "ATGC - test FAILED. Do not use TheSNPpit on this hardware."
fi

##############################################################################
# cleanup:
[ "$ALLOK" == 0 ] && rm -f $TMPDIR/50000* $TMPDIR/picken* $TMPDIR/yyyy
if [ "$KEEP" == "keep" ]; then
    info "Keeping temporary test database $TEST_DB"
else
    dropdb $TEST_DB
fi

exit $ALLOK

# vim: foldenable:foldmethod=marker
