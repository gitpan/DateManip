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

print "1..9\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

$calcs="

Wed Nov 20 1996 noon
+0:5:0:0
  1996112108:00:00

Wed Nov 20 1996 noon
+0:2:0:0
  1996112014:00:00

Wed Nov 20 1996 noon
+3:2:0:0
  1996112514:00:00

Wed Nov 20 1996 noon
-3:2:0:0
  1996111510:00:00

Wed Nov 20 1996 noon
+3:7:0:0
  1996112610:00:00

Wed Nov 20 1996 noon
+6:2:0:0
  1996112914:00:00

Dec 31 1996 noon
+1:2:0:0
  1997010214:00:00

Dec 30 1996 noon
+1:2:0:0
  1996123114:00:00

Mar 31 1997 16:59:59
+ 1 sec
  1997040108:00:00

";

&Date_Init("WorkDayBeg=08:00","WorkDayEnd=17:00");
print "DateCalc (date,delta,business 8:00-5:00)...\n";
$err="";
&test_Func(\&DateCalc,$calcs,$runtests,\$err,2);

1;
