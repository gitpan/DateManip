#!/usr/local/bin/perl

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if (defined $runtests) {
  require "test.pl";
} else {
  require "t/test.pl";
}

print "1..5\n"  if (! $runtests);

$tests="

Jan 1, 1996  at 10:30
12:40
   1996010112:40:00

1996010110:30:40
12:40:50
   1996010112:40:50

1996010110:30:40
12:40
   1996010112:40:00

1996010110:30:40
12
40
   1996010112:40:00

1996010110:30:40
12
40
50
   1996010112:40:50

";

print "SetTime...\n";
&test_Func(\&Date_SetTime,$tests,$runtests);

1;
