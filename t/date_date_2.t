#!/usr/local/bin/perl

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if (defined $runtests) {
  require "test.pl";
} else {
  require "t/test.pl";
}

print "1..22\n"  if (! $runtests);

$calcs="

Wed Jan 10 1996 noon
Wed Jan  7 1998 noon
  +1:11:18:0:0:0

Wed Jan  7 1998 noon
Wed Jan 10 1996 noon
  -1:11:18:0:0:0

Wed Jan 10 1996 noon
Wed Jan  8 1997 noon
  +0:11:19:0:0:0

Wed Jan  8 1997 noon
Wed Jan 10 1996 noon
  -0:11:19:0:0:0

Wed May  8 1996 noon
Wed Apr  9 1997 noon
  +0:11:1:0:0:0

Wed Apr  9 1997 noon
Wed May  8 1996 noon
  -0:11:1:0:0:0

Wed Apr 10 1996 noon
Wed May 14 1997 noon
  +1:1:2:4:0:0

Wed May 14 1997 noon
Wed Apr 10 1996 noon
  -1:1:2:4:0:0

Wed Jan 10 1996 noon
Wed Feb  7 1996 noon
  +0:0:19:0:0:0

Wed Feb  7 1996 noon
Wed Jan 10 1996 noon
  -0:0:19:0:0:0

Mon Jan  8 1996 noon
Fri Feb  9 1996 noon
  +0:1:1:0:0:0

Fri Feb  9 1996 noon
Mon Jan  8 1996 noon
  -0:1:1:0:0:0

Tue Jan  9 1996 12:00:00
Tue Jan  9 1996 14:30:30
  +0:0:0:2:30:30

Tue Jan  9 1996 14:30:30
Tue Jan  9 1996 12:00:00
  -0:0:0:2:30:30

Tue Jan  9 1996 12:00:00
Wed Jan 10 1996 14:30:30
  +0:0:1:2:30:30

Wed Jan 10 1996 14:30:30
Tue Jan  9 1996 12:00:00
  -0:0:1:2:30:30

Tue Jan  9 1996 12:00:00
Wed Jan 10 1996 10:30:30
  +0:0:0:7:30:30

Wed Jan 10 1996 10:30:30
Tue Jan  9 1996 12:00:00
  -0:0:0:7:30:30

Tue Jan  9 1996 12:00:00
Fri Jan 10 1997 10:30:30
  +1:0:0:7:30:30

Fri Jan 10 1997 10:30:30
Tue Jan  9 1996 12:00:00
  -1:0:0:7:30:30

Mon Dec 30 1996 noon
Mon Jan  6 1997 noon
  +0:0:4:0:0:0

Mon Jan  6 1997 noon
Mon Dec 30 1996 noon
  -0:0:4:0:0:0

";

&Date_Init("WorkDayBeg=08:00","WorkDayEnd=17:00");
print "DateCalc (date,date,business 8:00-5:00)...\n";
$err="";
&test_Func(\&DateCalc,$calcs,$runtests,\$err,2);

1;
