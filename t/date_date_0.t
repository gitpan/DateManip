#!/usr/local/bin/perl

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if (defined $runtests) {
  require "test.pl";
} else {
  require "t/test.pl";
}

print "1..8\n"  if (! $runtests);

$calcs="

Jan 1 1996 12:00:00
Jan 1 1996 14:30:30
  +0:0:0:2:30:30

Jan 1 1996 14:30:30
Jan 1 1996 12:00:00
  -0:0:0:2:30:30

Jan 1 1996 12:00:00
Jan 2 1996 14:30:30
  +0:0:1:2:30:30

Jan 2 1996 14:30:30
Jan 1 1996 12:00:00
  -0:0:1:2:30:30

Jan 1 1996 12:00:00
Jan 2 1996 10:30:30
  +0:0:0:22:30:30

Jan 2 1996 10:30:30
Jan 1 1996 12:00:00
  -0:0:0:22:30:30

Jan 1 1996 12:00:00
Jan 2 1997 10:30:30
  +0:0:366:22:30:30

Jan 2 1997 10:30:30
Jan 1 1996 12:00:00
  -0:0:366:22:30:30

";

print "DateCalc (date,date,exact)...\n";
$err="";
&test_Func(\&DateCalc,$calcs,$runtests,\$err,0);

1;
