#!/usr/local/bin/perl

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if (defined $runtests) {
  require "test.pl";
} else {
  require "t/test.pl";
}

print "1..2\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=.:./t","IgnoreGlobalCnf=1");

$calcs="

Wed Nov 20 1996 noon
+0:5:0:0
  1996112108:30:00

Wed Nov 20 1996 noon
+3:7:0:0
  1996112610:30:00

";

&Date_Init("WorkDayBeg=08:30","WorkDayEnd=17:00");
print "DateCalc (date,delta,business 8:30-5:00)...\n";
$err="";
&test_Func(\&DateCalc,$calcs,$runtests,\$err,2);

1;
