#!/usr/local/bin/perl

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if (defined $runtests) {
  require "test.pl";
} else {
  require "t/test.pl";
}

print "1..4\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=.:./t","IgnoreGlobalCnf=1");

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
&test_Func(\&ParseDateDelta,$deltas,$runtests);

1;
