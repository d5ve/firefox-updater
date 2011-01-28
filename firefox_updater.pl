#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

Firefox Updater - fetch and install firefox nightly builds

=head2 DESCRIPTION

Firefox Updater is a perl script which fetches Firefox trunk nightly builds and installs them.

!!This script isn't yet working!!

So far only fetching the latest daily build has been implemented.

=head2 SYNOPSIS

    # Check for a new daily build and install.
    firefox_updater.pl

=head2 VERSION

version 0.01 - 2011-01-27

    Now hosted on github - http://github.com/d5ve/firefox-updater

=cut

use Data::Dumper;
use Net::FTP;
use File::Temp;
use File::Copy;

# Fetching details
my $ftp_host = 'ftp.mozilla.org';
my $ftp_dir  = '/pub/mozilla.org/firefox/nightly/latest-trunk/';
my $nightly_file_suffix = 'linux-i686.tar.bz2';

# Local machine details
my $application_dir = "$ENV{HOME}/Applications/firefox";

my $ftp = Net::FTP->new($ftp_host, Debug => 0)
    or die "Cannot connect to '$ftp_host': $@";
$ftp->login("anonymous",'-anonymous@')
    or die "Cannot login ", $ftp->message;
$ftp->cwd($ftp_dir)
    or die "Cannot change working directory to '$ftp_dir'", $ftp->message;

my @files = $ftp->ls();
my ($nightly_build_file) = grep { m{ $nightly_file_suffix \z }xms } @files;

if ( ! $nightly_build_file ) {
    print "Error: Unable to find nightly file matching '$nightly_file_suffix' in:\n\t" . join("\n\t", @files) . "\nExiting...\n";
    exit 1;
}

my $local_tmp = File::Temp->new();
my $local_tmp_filename = $local_tmp->filename;

print "Fetching nightly file '$nightly_build_file' as '$local_tmp_filename'\n";
    
$ftp->binary() or die "Unable to set binary mode for file transfer", $ftp->message;
$ftp->get($nightly_build_file, $local_tmp_filename)
    or die "Failed to get '$nightly_build_file' -> '$local_tmp_filename'", $ftp->message;

$ftp->quit;

copy($local_tmp_filename, '/tmp/firefox_nightly.bz2');

#system "cd /tmp; tar xf $local_tmp_filename";

exit;

sub get_current_version {
    my $version_file = "$application_dir/application.ini";

    open my $version_fh, '<', $version_file or die "ERROR: Unable to open version file '$version_file' for reading - $!";
    
    while ( my $line = <$version_fh> ) {

    }

    close $version_fh or die "ERROR: Unable to close version file '$version_file' after reading - $!";
}

=head2 TODO

=over 4

=item * Check that firefox isn't currently running.

=item * Check the version number of the nightly is different to that installed.

=item * Install the new version.

=back

=head2 AUTHOR

Dave Webb <firefox-updater@d5ve.com>

=head2 CREDITS

Firefox Updater was inspired by a script for updating the chrome browser, found 
at http://www.macosxhints.com/article.php?story=20090604081030791 and written by 
user oblahdioblidaa.

=head2 LICENCE

Firefox Updater is free software. It comes without any warranty, to the extent permitted
by applicable law. 

Firefox Updater is released under the I<WTFPL Version 2.0> licence - L<http://sam.zoy.org/wtfpl/COPYING>

=cut
