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

$calcs="

Mer Nov 20 1996 12h00
il y a 3 jour 2 heures
  1996111510:00:00

Mer Nov 20 1996 12:00
5 heure
  1996112108:00:00

Mer Nov 20 1996 12:00
+0:2:0:0
  1996112014:00:00

Mer Nov 20 1996 12:00
3 jour 2 h
  1996112514:00:00

";

&Date_Init("Language=French","WorkDayBeg=08:00","WorkDayEnd=17h00");
print "DateCalc (French,date,delta,business 8:00-5:00)...\n";
$err="";
&test_Func(\&DateCalc,$calcs,$runtests,\$err,2);

1;
