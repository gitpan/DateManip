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
$ntest=4;

print "1..$ntest\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

&Date_Init("DeltaSigns=1");

$deltas="

1:2:3:4:5:6
    +1:+2:+3:+4:+5:+6

-1:2:3:4:5:6
    -1:-2:-3:-4:-5:-6

35x
    nil

+0
    +0:+0:+0:+0:+0:+0

";

print "Delta (signs)...\n";
&test_Func($ntest,\&ParseDateDelta,$deltas,$runtests);

1;
