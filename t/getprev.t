#!/usr/local/bin/perl

require 5.001;
use Date::Manip;
$runtests=shift(@ARGV);
if (defined $runtests) {
  require "test.pl";
} else {
  require "t/test.pl";
}

print "1..32\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

$tests ="

Fri Nov 22 1996 17:49:30
thu
0
   1996112117:49:30

Fri Nov 22 1996 17:49:30
thu
1
   1996112117:49:30

Fri Nov 22 1996 17:49:30
fri
0
   1996111517:49:30

Fri Nov 22 1996 17:49:30
5
0
   1996111517:49:30

Fri Nov 22 1996 17:49:30
fri
1
   1996112217:49:30

Fri Nov 22 1996 17:49:30
fri
0
18:30
   1996111518:30:00

Fri Nov 22 1996 17:49:30
fri
0
18:30:45
   1996111518:30:45

Fri Nov 22 1996 17:49:30
fri
0
18
30
   1996111518:30:00

Fri Nov 22 1996 17:49:30
fri
0
18
30
45
   1996111518:30:45

Fri Nov 22 1996 17:49:30
nil
0
18
   1996112118:00:00

Fri Nov 22 1996 17:49:33
nil
0
18:30
   1996112118:30:00

Fri Nov 22 1996 17:49:33
nil
0
18
30
   1996112118:30:00

Fri Nov 22 1996 17:49:33
nil
0
18:30:45
   1996112118:30:45

Fri Nov 22 1996 17:49:33
nil
0
18
30
45
   1996112118:30:45

Fri Nov 22 1996 17:49:33
nil
0
18
nil
45
   1996112118:00:45


Fri Nov 22 1996 17:00:00
nil
0
17
   1996112117:00:00

Fri Nov 22 1996 17:00:00
nil
1
17
   1996112217:00:00

Fri Nov 22 1996 17:49:00
nil
0
17
49
   1996112117:49:00

Fri Nov 22 1996 17:49:00
nil
1
17
49
   1996112217:49:00

Fri Nov 22 1996 17:49:33
nil
0
17
49
33
   1996112117:49:33

Fri Nov 22 1996 17:49:33
nil
1
17
49
33
   1996112217:49:33

Fri Nov 22 1996 17:00:33
nil
0
17
nil
33
   1996112117:00:33

Fri Nov 22 1996 17:00:33
nil
1
17
nil
33
   1996112217:00:33



Fri Nov 22 1996 17:49:30
nil
0
nil
30
   1996112217:30:00

Fri Nov 22 1996 17:49:30
nil
0
nil
30
45
   1996112217:30:45

Fri Nov 22 1996 17:49:30
nil
0
nil
nil
30
   1996112217:48:30



Fri Nov 22 1996 17:30:00
nil
0
nil
30
   1996112216:30:00

Fri Nov 22 1996 17:30:00
nil
1
nil
30
   1996112217:30:00

Fri Nov 22 1996 17:30:45
nil
0
nil
30
45
   1996112216:30:45

Fri Nov 22 1996 17:30:45
nil
1
nil
30
45
   1996112217:30:45

Fri Nov 22 1996 17:30:45
nil
0
nil
nil
45
   1996112217:29:45

Fri Nov 22 1996 17:30:45
nil
1
nil
nil
45
   1996112217:30:45

";

print "GetPrev...\n";
&test_Func(\&Date_GetPrev,$tests,$runtests);

1;
