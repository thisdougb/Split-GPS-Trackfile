#!/usr/bin/python
""" GPX file splitter

This is a simple script to split a large GPX trackfile into sub files
suitable for Garmin GPS device limits.   Sub files have an ordered
numeric suffix, and the track name (visible on the device) will also
be numbered.

Author: Doug Bridgens @ Far Oeuf
Bugs,comments,features via: https://github.com/thisdougb/Split-GPX-Trackfile
"""

import sys
import re
import string

# parse command line args
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("maxpoints", help="upper limit of trackpoints per track your GPS device supports", type=int)
parser.add_argument("source", help="your large .gpx file to split")
args = parser.parse_args()

# open and read gpx file
try:
    with open(args.source, 'r') as fh:
        file_as_string = fh.read()
except IOError as e:
    print "IO error ({0}) : {1}".format(e.errno, e.strerror)

# strip whitespace, using re.compile for python -2.7
r = re.compile(r">\s+<", re.MULTILINE)
file_as_string = r.sub("><", file_as_string)

# strip gpx header
s = re.search("^<\?xml.*?<trkseg>", file_as_string)
if s:
    gpx_file_header = s.group()
    file_as_string = file_as_string[s.end():]
else:
    print 'Error: source file is not valid GPX format'
    sys.exit(0)

# strip gpx footer
s = re.search("<\/trkseg>.*", file_as_string)
if s:
    gpx_file_footer = s.group()
    file_as_string = file_as_string[:s.start()]
else:
    print 'Error: source file is not valid GPX format'
    sys.exit(0)

# loop remaining data writing chunks as files
filenamebase = args.source.split('.', 1)[0]
trklist = []
count = 1
c = re.compile(r"<trkpt.*?<\/trkpt>", re.IGNORECASE)
for match in c.finditer(file_as_string):
    trklist.append(match.group())
    if (len(trklist) == args.maxpoints) or (match.end() == len(file_as_string)):
        trackpoints = string.join(trklist, '')
        outfilename = '{}_{:02d}.gpx'.format(filenamebase, count)
        try:
            with open(outfilename, 'w') as fh:
                p = re.compile('</name>', flags=re.IGNORECASE)
                fh.write(p.sub(' {:02d}</name>'.format(count), gpx_file_header) + trackpoints + gpx_file_footer)
                fh.close
        except IOError as e:
            print "IO error ({0}) : {1}".format(e.errno, e.strerror)
            sys.exit(0)
        else:
            print 'created ' + outfilename
        trklist = []
        count += 1
