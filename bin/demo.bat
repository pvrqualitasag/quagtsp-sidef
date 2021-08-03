#!/bin/bash

ADMINUSER=$USER
DEMODB=TheSNPpit_demo_$USER
SNP_HOME=${SNP_HOME-/usr/local/TheSNPpit_current}
SNP_LIB=${SNP_HOME}/lib
DB_ENCODING=utf8

### Functions start ##########################################################
# print errors in red on STDERR
error () {
    if [[ -t 2 ]] ; then
        printf '\E[31m'; echo "ERROR: $@"; printf '\E[0m'
    else
        echo "$@"
    fi >&2
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
check_for_root() {
    if [ ! $( id -u ) -eq 0 ]; then
        error "Must be run as root"
        exit 1
    fi
}
##############################################################################
install_thesnppit_db () {
    # drop database first:
    dropdb --if-exists $DEMODB 2>&1 |grep -v NOTICE
    info "Creating TheSNPpit Demo Database ..."
    createdb --encoding=$DB_ENCODING --owner=$ADMINUSER --no-password $DEMODB

    # check again:
    psql -l --tuples-only --quiet --no-align --field-separator=' '|awk '{print $1}' |grep "^${DEMODB}$" >/dev/null
    if [ $? -eq 0 ]; then
        # fill the newly created database with the structure:
        psql -q -f ${SNP_LIB}/TheSNPpit.sql $DEMODB -U $ADMINUSER
        if [ $? -eq 0 ]; then
            ok "TheSNPpit Demo Database created"
        fi
    else
        error "Something went wrong while creating TheSNPpit Demo Database"
    fi

}
##############################################################################
# works only with root privileges (esp. concerning database):
# removed to make it work as a demo for every snp user (8.6.2018 - heli):
# check_for_root
# first install the demo database:
install_thesnppit_db

##############################################################################
info "************************************************************"
info "*      load panel map data from file picken.map            *"
info "*          and give it the name chk-57Illu                 *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    -I panel          => insert new panel                 *"
info "*    -f ped            => use ped   format                 *"
info "*    -p chk-57Illu     => panel name                       *"
info "*    -i picken.map     => input file                       *"
info "*                                                          *"
info "* Hit RETURN to run command:                               *"
info "************************************************************"
echo ""
ID="$SNP_HOME/regression/input"
read -e -i "snppit  -T $DEMODB -I panel -f ped -p chk-57Illu -i $ID/picken.map --skipheader"
eval $REPLY

echo ""
info "************************************************************"
info "*         load SNP data for the panel chk-57Illu           *"
info "*                   from file picken.ped                   *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    -I data           => insert data for panel            *"
info "*    -f ped            => use ped format                 *"
info "*    -p chk-57Illu     => panel name                       *"
info "*    -i picken.ped     => input file                       *"
info "***************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -I data  -f ped -p chk-57Illu -i $ID/picken.ped"
eval $REPLY

info "************************************************************"
info "*      load panel map data from 500000 panel               *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo     => use demo database            *"
info "*    -I panel              => insert new panel             *"
info "*    -f ped                => use ped   format             *"
info "*    -p 500000             => panel name                   *"
info "*    -i 00500000-00010.map => input file                   *"
info "*                                                          *"
info "* Hit RETURN to run command:                               *"
info "************************************************************"
echo ""
ID="$SNP_HOME/regression/input"
read -e -i "snppit -T $DEMODB -I panel -f ped -p 500000 -i $ID/00500000-00010.map"
eval $REPLY

echo ""
info "************************************************************"
info "*      load panel SNP data from 500000 panel               *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo     => use demo database            *"
info "*    -I data               => insert new panel             *"
info "*    -f ped                => use ped   format             *"
info "*    -p 500000             => panel name                   *"
info "*    -i 00500000-00010.ped => input file                   *"
info "*                                                          *"
info "* Hit RETURN to run command:                               *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -I data -f ped -p 500000 -i $ID/00500000-00010.ped"
eval $REPLY

echo ""
info "************************************************************"
info "*                      list all                            *"
info "*  genotype sets, snp_selection and individual_selection   *"
info "*                   in the database                        *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    -R genotype_set   => print report of genotype_sets    *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -R genotype_set"
eval $REPLY

echo ""
info "************************************************************"
info "* list all snp_selections                                  *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    -R snp_selection  => print report of snp_selections   *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -R snp_selection"
eval $REPLY

echo ""
info "************************************************************"
info "* list all individual_selections                           *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    -R individual_selection => print report               *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -R individual_selection"
eval $REPLY

echo ""
info "************************************************************"
info "  export the genotype set gs_001 in ped format             *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    -E genotype_set   => export genotype_set gs_001       *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -E genotype_set --name gs_001"
eval $REPLY

echo ""
info "************************************************************"
info "  export the genotype set gs_001 in 0125  format           *"
info "         to the file wk0125.ped and wg0125.map             *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    -E genotype_set   => export genotype_set gs_001       *"
info "*    -f 0125           => export in this format            *"
info "*    -o wk0125         => output file wk0125.<ext>         *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -E genotype_set --name gs_001 -f 0125 -o wk0125"
eval $REPLY

echo ""
info "************************************************************"
info "*  create a new subset based on major allele frequencies   *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    --maf =.01        => maf at .01                       *"
info "*    -S genotype_set   => use gs_001 as starting subset    *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -S genotype_set --name gs_001 --maf=.01"
eval $REPLY


echo ""
info "************************************************************"
info "*  create a new subset based on major allele frequencies   *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    --maf =.02        => maf at .02                       *"
info "*    -S genotype_set   => use gs_001 as starting subset    *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -S genotype_set --name gs_001 --maf=.02"
eval $REPLY

echo ""
info "************************************************************"
info "*  create a new subset based on major allele frequencies   *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    --maf =.06        => maf at .06                       *"
info "*    -S genotype_set   => use gs_001 as starting subset    *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -S genotype_set --name gs_001 --maf=.06"
eval $REPLY

echo ""
info "************************************************************"
info "*          create a new subset based on no calls           *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    --maf =.06        => maf at .06                       *"
info "*    -S genotype_set   => use gs_003 as starting subset    *"
info "*    --ncsnp=.03       => no calls for SNP at .03          *"
info "*    --ncind=.05       => no calls for Individuals at .05  *"
info "*    --first='snp'     => do SNPs first                    *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB  -S genotype_set --name gs_003 --ncsnp=.03 --ncind=.05 --first='snp'"
eval $REPLY


echo ""
info "************************************************************"
info "*          create a new subset based on no calls           *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    --maf =.06        => maf at .06                       *"
info "*    -S genotype_set   => use gs_003 as starting subset    *"
info "*    --ncsnp=.03       => no calls for SNP at .03          *"
info "*    --ncind=.05       => no calls for Individuals at .05  *"
info "*    --first='ind'     => do INDs first                    *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB  -S genotype_set --name gs_003 --ncsnp=.03 --ncind=.05 --first='ind'"
eval $REPLY

info "************************************************************"
info "*                      list all                            *"
info "*                    genotype sets                         *"
info "*                   in the database                        *"
info "*                                                          *"
info "* Parameters:                                              *"
info "*    -T TheSNPpit_demo => use demo database                *"
info "*    -R genotype_set   => print report of genotype_sets    *"
info "************************************************************"
echo ""
read -e -i "snppit -T $DEMODB -R genotype_set"
eval $REPLY


ok "done"

# vim:ft=sh
