#!/usr/local/bin/perl

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if (defined $runtests) {
  require "test.pl";
} else {
  require "t/test.pl";
}

print "1..6\n"  if (! $runtests);

$calcs="

1:1:1:1
2:2:2:2
  +0:0:3:3:3:3

1:1:1:1
2:-1:1:1
  +0:0:3:0:0:0

1:1:1:1
0:-11:5:6
  +0:0:0:13:55:55

1:1:1:1
0:-25:5:6
  -0:0:0:0:4:5

1:1:1:1:1:1
2:12:2:48:120:120
 +4:1:5:3:3:1

1:1:1:1:1:1
2:12:-2:48:120:120
 +4:1:-3:1:0:59

";

print "DateCalc (delta,delta,approx)...\n";
$err="";
&test_Func(\&DateCalc,$calcs,$runtests,\$err,1);

1;
