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

$tests="

Wed Jan 3, 1996  at 8:11:12
%y %Y %m %f %b %h %B %U %W %j %d %e %v %a %A %w %E
   96_1996_01__1_Jan_Jan_January_01_01_003_03__3__W_Wed_Wednesday_3_3rd

Wed Jan 3, 1996  at 8:11:12
%H %k %i %I %p %M %S %s %o %z %Z
   08__8__8_08_AM_11_12_820674672_820656672_EST_EST

";

print "UnixDate...\n";
&test_Func(\&UnixDate,$tests,$runtests);

1;

