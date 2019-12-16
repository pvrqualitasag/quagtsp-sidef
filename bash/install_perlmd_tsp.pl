#!/usr/bin/env perl
##############################################################################
# $Id: install_perlmd 
# This is just a basic script that checks to make sure that all
# the modules needed by TheSNPpit before you can install it.
##############################################################################

=cut #########################################################################
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
# Authors: Cong V.C. Truong    (cong.chi@fli.bund.de) Helmut Lichtenberg
# (helmut.lichtenberg@fli.bund.de) Eildert Groeneveld
# (eildert.groeneveld@fli.bund.de)
=cut #########################################################################

use strict;
use warnings;

# standard perl modules:
use Getopt::Long;
Getopt::Long::Configure ("bundling"); # allow argument bundling
use Pod::Usage;
use FindBin qw($RealBin);

my %args;
my $core_mod_file = $RealBin . '/needed_perl_modules_tsp';
my @modfiles;

# handling the command line args:
GetOptions( \%args,
    'help|h|?',
    'man|m|pod|p',
    'quiet|q',
    'install|i',
    'debian|d',
    'file|f=s@'
) or pod2usage( -verbose => 1);

pod2usage( -verbose => 1) if $args{'help'};
pod2usage( -verbose => 2) if $args{'man'};

# reading $mod_file(s):
if ( exists $args{file} ){
    @modfiles = @{$args{file}}; # could be several
} else {
    push @modfiles, $core_mod_file;
}

PROJECT:
for my $needed (@modfiles) {
    my $FILE;
    eval {
        open $FILE, '<', $needed or die "$!\n";
        # or die "Problems opening file\n\t$needed:\n$!\n";
    };
    if ($@) {
        my $string = $@;
        printf STDERR "%s\n", '#' x 78;
        printf STDERR "# %s\n", 'Problems opening file:';
        printf STDERR "# %s\n", $needed;
        printf STDERR "# %s", $string;
        printf STDERR "# %s\n", 'Skipped!';
        printf STDERR "%s\n", '#' x 78;
        next PROJECT;
    }

    # some nice printing:
    if ( !$args{quiet} ) {
        my $string = "# $needed: #";
        printf "%s\n", '#' x length($string);
        printf "%s\n", $string;
        printf "%s\n", '#' x length($string);
    }

    my $section = 'UNSORTED';
    my @sections;    # store in an array to keep the order
    my %deps;

    # read file and separate sections and entries:
    while (<$FILE>) {
        next if /^\s*#/;    # comments
        next if /^\s*$/;    # empty lines
        if (/^\s*\[([^]]*)\]/) {
            $section = $1;
            push @sections, $section;
        }
        else {
            chomp;
            push @{ $deps{$section} }, $_;
        }
    }
    close $FILE;

    # process entries per section
    foreach my $section (@sections) {
        print "$section\n" if !$args{quiet};
        my @deps = ( @{ $deps{$section} } );
        foreach my $entry (@deps) {
            $entry =~ s/^\s*//;
            $entry =~ s/\s*$//;
            my ( $module, $version ) = split /\s+/, $entry;
            my $ret = test_dep( $module, $version );

            if ( !$ret ) {
                die "\t$module: Only root can install Perl modules. Sorry.\n"
                    if ( $< != 0 or $> != 0 );
                resolve_dep($module) if $args{'install'} and !$args{'debian'};
                debian_inst($module) if $args{'debian'};
            }
        }
        print "\n" if !$args{quiet};
    }
}

sub test_dep {
    my $module  = shift;
    my $version = shift;
    my $string  = $module;
    $string .= " $version" if defined $version;

    eval "use $string ()";
    if ($@) {
        my $error = $@;
        $error =~ s/\n(.*)$//s;
        if ( !$args{quiet} ) {
            print "\t$string";
            print ' ' x ( 30 - length($string) );
            print "... MISSING\n";
            print "\t\t$error\n" if $error =~ /this is only/;
        }

        return undef;
    }
    else {
        if ( !$args{quiet} ) {
            print "\t$string";
            print ' ' x ( 30 - length($string) );
            print "... found\n";
        }
        return 1;
    }
}

sub resolve_dep {
    my $module = shift;
    use CPAN();
    CPAN::Shell->install($module);
}

sub debian_inst {
    my $module = shift;
    $module =~ tr/A-Z/a-z/;
    $module =~ s/::/-/g;
    $module = 'lib' . $module . '-perl';
    my $ret = system("apt-get install -q --yes $module");
    $ret;
}

__END__

=pod

=head1 NAME

install_perlmd

=head1 SYNOPSIS

install_perlmd [Options]

=head1 OPTIONS

   -h | -? | --help            short help
   -m | --man | -p | --pod     detailed man page
   -q | --quiet                quiet execution
   -i | --install              install missing modules (only as root)
   -d | --debian               install missing modules as debian package (only as root)
   -f | --file <filename>      take <filename> instead of the default file in ../etc/needed_modules

=head1 DESCRIPTION

install_perlmd determines whether you have installed all the
perl modules needs to run snptk. If you want to install the missing modules
you must be root.

=head1 FILES

The needed modules and optionally the required versions are taken from the
file ../etc/needed_modules unless you pass -f <filename> on the
commandline. This option enables you to also check the modules for your
projects. You can specify several -f <filename> options on the command line.

Example:

   install_perlmd -d

This checks the modules of the Apiis core and of the projects ref_breedprg and
efabis. They will be installed as Debian packages.

=head1 AUTHOR

Modified by Cong Truong <cong.chi@fli.bund.de>
Written by Helmut Lichtenberg <heli@tzv.fal.de>

This program is based on rt-test-dependencies by Jesse Vincent
<jesse@bestpractical.com>, which is part of the RT request tracking
system.


