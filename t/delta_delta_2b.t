#!/usr/local/bin/perl

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if (defined $runtests) {
  require "test.pl";
} else {
  require "t/test.pl";
}

print "1..1\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

$calcs="

+1:6:30:30
+1:3:45:45
  +0:0:3:1:46:15

";

&Date_Init("WorkDayBeg=08:30","WorkDayEnd=17:00");
print "DateCalc (delta,delta,business 8:30-5:00)...\n";
$err="";
&test_Func(\&DateCalc,$calcs,$runtests,\$err,2);

1;
