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

print "1..2\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

$dates="
# Tests YYMMDD time
1996061800:00:00
    1996-06-18_00:00:00

# Tests YYMMDDHHMNSS
19960618000000
    1996-06-18_00:00:00
";

print "Date (English,Internal=2)...\n";
&Date_Init("Internal=2");
&test_Func(\&ParseDate,$dates,$runtests);

1;