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
$ntest=1;

print "1..$ntest\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

$calcs="

+1:6:30:30
+1:3:45:45
  +0:0:0:3:1:16:15

";

&Date_Init("WorkDayBeg=08:00","WorkDayEnd=17:00");
print "DateCalc (delta,delta,business 8:00-5:00)...\n";
&test_Func($ntest,\&DateCalc,$calcs,$runtests,2);

1;
