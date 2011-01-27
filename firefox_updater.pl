#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use Net::FTP;
use File::Temp;

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
    
$ftp->get($nightly_build_file, $local_tmp_filename)
    or die "Failed to get '$nightly_build_file' -> '$local_tmp_filename'", $ftp->message;

$ftp->quit;

exit;

sub get_current_version {
    my $file = "$application_dir/application.ini";

}

