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
