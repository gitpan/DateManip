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
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

$dates="
# Tests YYMMDD time
1996061800:00:00
    19960618000000

# Tests YYMMDDHHMNSS
19960618000000
    19960618000000
";

print "Date (English,Internal=1)...\n";
&Date_Init("Internal=1");
&test_Func(\&ParseDate,$dates,$runtests);

1;

