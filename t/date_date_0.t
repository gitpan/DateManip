#!/usr/local/bin/perl

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if (defined $runtests) {
  require "test.pl";
} else {
  require "t/test.pl";
}

print "1..11\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

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

Jan 1st 1997 00:00:01
Feb 1st 1997 00:00:00
  +0:0:30:23:59:59

Jan 1st 1997 00:00:01
Mar 1st 1997 00:00:00
  +0:0:58:23:59:59

Jan 1st 1997 00:00:01
Mar 1st 1998 00:00:00
  +0:0:423:23:59:59

";

print "DateCalc (date,date,exact)...\n";
$err="";
&test_Func(\&DateCalc,$calcs,$runtests,\$err,0);

1;
