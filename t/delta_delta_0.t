#!/usr/local/bin/perl -w

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if ( -f "t/test.pl" ) {
  require "t/test.pl";
} elsif ( -f "test.pl" ) {
  require "test.pl";
} else {
  die "ERROR: cannot find test.pl\n";
}
$ntest=6;

print "1..$ntest\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

$calcs="

1:1:1:1
2:2:2:2
  +0:0:0:3:3:3:3

1:1:1:1
2:-1:1:1
  +0:0:0:3:0:0:0

1:1:1:1
0:-11:5:6
  +0:0:0:0:13:55:55

1:1:1:1
0:-25:5:6
  -0:0:0:0:0:4:5

1:1:0:1:1:1:1
2:12:1:2:48:120:120
 +4:1:1:5:3:3:1

1:1:0:1:1:1:1
2:12:0:-2:48:120:120
 +4:1:-0:3:1:0:59

";

print "DateCalc (delta,delta,exact)...\n";
&test_Func($ntest,\&DateCalc,$calcs,$runtests,0);

1;
