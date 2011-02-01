#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

Firefox Updater - fetch and install firefox nightly builds

=head2 DESCRIPTION

Firefox Updater is a perl script which fetches Firefox trunk nightly builds and
installs them.

This script checks the currently installed version against the latest one
hosted at ftp.mozilla.org. If a new version is found, and firefox isn't
currently running, then the new version is downloaded, unpacked and installed.
This completely replaces the old version's files, but settings, history, and
bookmarks are safe, as they're stored outside the application directory.

=head2 SYNOPSIS

    # Check for a new daily build and install if one is found.
    firefox_updater.pl

=head2 VERSION

version 1.00 - 2011-02-01

    Now works from end to end.

=cut

use Data::Dumper;
use File::Copy ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use Net::FTP;

my $debug = 0;

# Fetching details
my $ftp_host = 'ftp.mozilla.org';
my $ftp_dir  = '/pub/mozilla.org/firefox/nightly/latest-trunk/';
my $nightly_build_file_suffix   = 'linux-i686.tar.bz2';
my $nightly_version_file_suffix = 'linux-i686.txt';

# Local machine details
my $base_name               = 'firefox';
my $application_root_dir    = "$ENV{HOME}/Applications";
my $application_dir         = "$application_root_dir/$base_name";
my $process_name            = "$application_dir/firefox-bin";
my $temp_dir                = File::Spec->tmpdir;
my $unpack_command          = "tar -C $temp_dir -xf";

# Check for a newer version
my $current_build_id = get_current_build_id();
my $latest_build_id = get_latest_build_id();
print "Current build ID: $current_build_id, Latest build ID: $latest_build_id\n";
if ( $current_build_id < $latest_build_id ) {
    # Check to see if firefox is currently running,
    if ( is_firefox_running() ) {
        print "Firefox is currently running. Please stop it first. Exiting...\n";
        exit 10;
    }
    else {
        # Fetch and install new build
        fetch_and_install_latest_build();
    }
}
else {
    print "No new build found. Exiting...\n";
    exit 20;
}

exit;

# Check whether firefox is already running.
# Probably should use /proc.
sub is_firefox_running {

    my $command = qq{ ps auxww | grep -v grep | grep "$process_name" | awk '{print \$2}' }; # vim's syntax highlighting sucks.
    my $pid = `$command`;
    chomp $pid;

    return $pid;
}

# Fetch the latest build from the FTP repos.
sub fetch_and_install_latest_build {
    my $local_tmp          = File::Temp->new();
    my $local_tmp_filename = $local_tmp->filename;

    print "Fetching latest build\n";
    fetch_file_via_ftp($nightly_build_file_suffix, $local_tmp_filename);

    # Unpack the new build.
    print "Unpacking latest build\n";
    system("$unpack_command $local_tmp_filename");


    # Make sure application dir exists
    File::Path::make_path($application_dir) unless -d $application_dir;

    # Remove any existing install
    File::Path::remove_tree($application_dir) or die "ERROR: Unable to remove current install '$application_dir' - $!"; 

    # Move the new build into place
    File::Copy::move("$temp_dir/$base_name", $application_dir) or die "ERROR: Unable to move '$temp_dir/$base_name' to '$application_dir' - $!";

}

sub fetch_file_via_ftp {
    my $file_suffix = shift or die 'fetch_file_via_ftp() missing required $file_suffix param. Exiting...';
    my $local_filename = shift or die 'fetch_file_via_ftp() missing required $local_filename param. Exiting...';

    my $ftp = Net::FTP->new($ftp_host, Debug => 0)
        or die "Cannot connect to '$ftp_host': $@";
    $ftp->login("anonymous",'-anonymous@')
        or die "Cannot login ", $ftp->message;
    $ftp->cwd($ftp_dir)
        or die "Cannot change working directory to '$ftp_dir'", $ftp->message;

    my @files = $ftp->ls();
    my ($requested_file) = grep { m{ $file_suffix \z }xms } @files;

    if ( ! $requested_file ) {
        print "Error: Unable to find nightly file matching '$file_suffix' in:\n\t" . join("\n\t", @files) . "\nExiting...\n";
        exit 1;
    }

    print "Fetching file '$requested_file' as '$local_filename'\n" if $debug;

    $ftp->binary() or die "Unable to set binary mode for file transfer", $ftp->message;
    $ftp->get($requested_file, $local_filename)
        or die "Failed to get '$requested_file' -> '$local_filename'", $ftp->message;

    $ftp->quit;
}

# Read the latest build ID from the FTP repository
sub get_latest_build_id {
    my $latest_build_id = 0;
    my $local_tmp          = File::Temp->new();
    my $local_tmp_filename = $local_tmp->filename;

    fetch_file_via_ftp($nightly_version_file_suffix, $local_tmp_filename);

    open my $version_fh, '<', $local_tmp_filename or die "ERROR: Unable to open version file '$local_tmp_filename' for reading - $!";
    while ( my $line = <$version_fh> ) {
        # 20110201030339
        # http://hg.mozilla.org/mozilla-central/rev/8b5cb26bbb10
        print "DEBUG: $line" if $debug;
        if ( $line =~ m{ \A (\d{10,}) \s* \z }xms ) {
            $latest_build_id = $1;
            last;
        }
    }
    close $version_fh or die "ERROR: Unable to close version file '$local_tmp_filename' after reading - $!";

    return $latest_build_id;

}

# Read the build ID from the currently installed firefox.
sub get_current_build_id {
    my $version_file = "$application_dir/application.ini";

    my $current_build_id = 0;
    my $version_fh;
    open($version_fh, '<', $version_file) or do {
        print "WARNING: Unable to open version file '$version_file' for reading - $!\n";
        print "         Assuming that this is the first run of the script\n";
        return $current_build_id;
    };

    while ( my $line = <$version_fh> ) {
        #BuildID=20110127030333
        if ( $line =~ m{ \A BuildID=(\d+) \s* \z }xms ) {
            $current_build_id = $1;
            last;
        }
    }

    close $version_fh or die "ERROR: Unable to close version file '$version_file' after reading - $!";

    return $current_build_id;
}

=head2 TODO

=over 4

=item * Test on OSX

=back

=head2 HISTORY

version 0.01 - 2011-01-27

    Now hosted on github - http://github.com/d5ve/firefox-updater

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
