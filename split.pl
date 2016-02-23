#!/usr/bin/perl
#
# https://github.com/thisdougb/Split-GPX-Trackfile
#
# Author: Doug Bridgens @ Far Oeuf
# Bugs,comments,features via: https://github.com/thisdougb/Split-GPX-Trackfile
# 

use 5.0;
use warnings;
use strict;

use Getopt::Long;

my %options;

GetOptions(
    \%options, "source=s", "maxpoints=i", "help",
);

if ( defined $options{'help'} && $options{'help'} == 1 ) { usage(); }

# check the source option points to an existing an readable file
if ( ! defined $options{'source'} || $options{'source'} !~ m/\.gpx/ || ! -r $options{'source'} ) { usage(); }

# check maxpoints is great than zero
if ( ! defined $options{'maxpoints'} || $options{'maxpoints'} < 1 ) { usage(); }

parse_gpx_file();

sub usage {

    # shown with --help or invalid options
    print "Simple script which splits a GPX track file into smaller chunks suitable for Garmin devices.\n"
        . "Chunked files will created with a numeric postifx, <source>_01.gpx, etc.\n"
        . "\n"
        . "perl split.pl --source <path> --maxpoints <maxpoints>\n"
        . "\n"
        . "  --source <path>       path to the GPX file to split\n"
        . "  --maxpoints <size>    maximum number of trackpoints Garmin device supports\n"
        . "\n"
        . "This script assumes your .gpx file is valid.  If you put garbage in, you get garbage out.\n"
        . "Bugs, comments, feature requests to https://github.com/thisdougb/garmin-gpx-splitter\n"
        . "\n";

    exit 0;
}

sub parse_gpx_file {

    # TODO: get the encoding first, then re-open the file with correct encoding for reading?

    my $file_as_string = do {
        open(my $fh, "<", $options{'source'}) or die "Can't open $options{'source'}: $!\n";
        local $/ = undef;
        <$fh>;
    };

    # strip unnecessary whitespace
    $file_as_string =~ s/>\s+</></g;

    # strip and store the xml header
    $file_as_string =~ m/<\?xml.+?<trkseg>/;
    $file_as_string = $';
    my $gpx_file_header = $&;

    # strip and store the xml footer
    $file_as_string =~ m/<\/trkseg>.*/;
    $file_as_string = $`;
    my $gpx_file_footer = $&;

    my $chunk_number = 1;
    while ($file_as_string =~ /(<trkpt.+?<\/trkpt>){1,$options{'maxpoints'}}/g) {

        # strip this chunk from the main gpx string
        $file_as_string = $';
        my $gpx_chunk = $&;

        # filename for this chunk
        $options{'source'} =~ m/\.gpx/;
        my $chunk_filename = sprintf("%s_%02d.gpx", $`, $chunk_number);

        # add the chunk number to the name string, so this shows up on the GPS device
        my $chunk_count_string = sprintf("%02d", $chunk_number);
        $gpx_file_header =~ s/(<name>.*?)[0-9\s]{0,3}(<\/name>)/$1 $chunk_count_string$2/;

        open (my $fh, '>', $chunk_filename) or die "Can't open $options{'source'}: $!\n";
        print $fh $gpx_file_header . $gpx_chunk . $gpx_file_footer;
        close $fh;

        $chunk_number++;
    }
}
