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

print "1..213\n"  if (! $runtests);
&Date_Init("PersonalCnfPath=./t:.","IgnoreGlobalCnf=1","TZ=EST");

($currS,$currMN,$currH,$currD,$currM,$currY)=localtime(time);
$currY+=1900;
$currM++;
$currM ="0$currM"   while (length $currM < 2);
$currD ="0$currD"   while (length $currD < 2);
$currH ="0$currH"   while (length $currH < 2);
$currMN="0$currMN"  while (length $currMN < 2);
$currS ="0$currS"   while (length $currS < 2);
$today="$currY$currM$currD$currH:$currMN:$currS";
$todaydate    ="$currY$currM$currD";
$yesterdaydate="$currY$currM". $currD-1;
$tomorrowdate ="$currY$currM". $currD+1;
$yesterday    ="$yesterdaydate$currH:$currMN:$currS";
$tomorrow     ="$tomorrowdate$currH:$currMN:$currS";

$dates="

# Test built in strings like today and yesterday.  A few may fail on a
# slow computer.  On the 1st or last day of the month, the yesterday/today
# test will fail because of the simplicity of the test.
now
    >May safely fail on a slow computer.
    ~$today

today
    >May safely fail on a slow computer.
    ~$today

yesterday
    >May safely fail on a slow computer or on 1st day of month.
    ~$yesterday

tomorrow
    >May safely fail on a slow computer or on last day of month.
    ~$tomorrow

today at 4:00
    $todaydate 04:00:00

today at 4:00 pm
    $todaydate 16:00:00

today at 16:00:00:05
    $todaydate 16:00:00

today at 12:00 am
    $todaydate 00:00:00

today at 12:00 GMT
    >May safely fail if not in EST timezone.
    $todaydate 07:00:00

today at 4:00 PST
    >May safely fail if not in EST timezone.
    $todaydate 07:00:00

today at 4:00 -0800
    >May safely fail if not in EST timezone.
    $todaydate 07:00:00

today at noon
    $todaydate 12:00:00

tomorrow at noon
    >May safely fail on last day of month.
    $tomorrowdate 12:00:00

# Test weeks
22nd sunday
    >May safely fail in 1998.
    1997060100:00:00

97W227
    1997060100:00:00

1997W22-7
    1997060100:00:00

1997W23
    1997060200:00:00

1997023
    1997012300:00:00

1997035
    1997020400:00:00

97-035
    1997020400:00:00

97035
    1997020400:00:00

twenty-second sunday 1996
    1996060200:00:00

22 sunday in 1996
    1996060200:00:00

22nd sunday 12:00
    >May safely fail in 1998.
    1997060112:00:00

22nd sunday at 12:00
    >May safely fail in 1998.
    1997060112:00:00

22nd sunday at 12:00 EST
    >May safely fail in 1998 or when not in EST.
    1997060112:00:00

22nd sunday in 1996 at 12:00 EST
    >May safely fail when not in EST.
    1996060212:00:00

sunday wk 22
    >May safely fail in 1998.
    1997060100:00:00

sunday week twenty-second 1996
    1996060200:00:00

sunday w 22 in 1996
    1996060200:00:00

sunday wks 22 12:00
    >May safely fail in 1998.
    1997060112:00:00

sunday week 22 at 12:00
    >May safely fail in 1998.
    1997060112:00:00

sunday week 22 at 12:00 EST
    >May safely fail in 1998 or when not in EST.
    1997060112:00:00

sunday week 22 in 1996 at 12:00 EST
    >May safely fail when not in EST.
    1996060212:00:00

sunday 22 wk
    >May safely fail in 1998.
    1997060100:00:00

sunday twenty-second week 1996
    1996060200:00:00

sunday 22 w in 1996
    1996060200:00:00

sunday 22 wks 12:00
    >May safely fail in 1998.
    1997060112:00:00

sunday 22 week at 12:00
    >May safely fail in 1998.
    1997060112:00:00

sunday 22 week at 12:00 EST
    >May safely fail in 1998 or when not in EST.
    1997060112:00:00

sunday 22 week in 1996 at 12:00 EST
    >May safely fail when not in EST.
    1996060212:00:00

# Tests 'which day in mon' formats
last tue in Jun 96
    1996062500:00:00

last tueSday of June
    >Needs to be fixed in 1998.
    1997062400:00:00

first tue in Jun 1996
    1996060400:00:00

1st tue in June
    >Needs to be fixed in 1998.
    1997060300:00:00

3rd tuesday in Jun 96
    1996061800:00:00

3rd tuesday in Jun 96 at 12:00:00.05
    1996061812:00:00

3rd tuesday in Jun 96 at 10:30am
    1996061810:30:00

3rd tuesday in Jun 96 at 10:30 pm
    1996061822:30:00

3rd tuesday in Jun 96 at 10:30 pm GMT
    >May safely fail if not in EST timezone
    1996061817:30:00

3rd tuesday in Jun 96 at 10:30 pm CET
    >May safely fail if not in EST timezone
    1996061816:30:00

# Tests YYMMDD time
1996061800:00:00
    1996061800:00:00

1996061800:00
    1996061800:00:00

96-06-1800:00:00
    1996061800:00:00

96-06-1800:00
    1996061800:00:00

93-12-01
    1993120100:00:00

19931201
    1993120100:00:00

93-12-0105:30
    1993120105:30:00

1993120105:30
    1993120105:30:00

1992022905:30
    1992022905:30:00

1990022905:30
    nil

1993120105:30:25
    1993120105:30:25

1992022905:30:61
    nil

1993120105:30:25.05 am
    1993120105:30:25

1993120105:30:25:05 pM
    1993120117:30:25

1993120105:30:25 pM GMT
    >May safely fail if not in EST timezone.
    1993120112:30:25

19931201 at 05:30:25 pM GMT
    >May safely fail if not in EST timezone.
    1993120112:30:25

19931201at05:30:25 pM GMT
    >May safely fail if not in EST timezone.
    1993120112:30:25

# Tests YYMMDDHHMNSS
19960618000000
    1996061800:00:00

# Tests Date Time
#       Date%Time
# Date=mm%dd
12/10/1965
    1965121000:00:00

12/10/65
    1965121000:00:00

12.10.65
    1965121000:00:00

12 10 65
    1965121000:00:00

12/10/65 5:30:25
    1965121005:30:25

12/10/65/5:30 pm
    1965121017:30:00

12/10/65/5:30 pm GMT
    >May safely fail if not in EST timezone.
    1965121012:30:00

12/10/65 at 5:30:25
    1965121005:30:25

12-10-1965 5:30:25
    1965121005:30:25

12-10-65 5:30:25
    1965121005:30:25

12-10-65-5:30 pm
    1965121017:30:00

12-10-65 at 5:30:25
    1965121005:30:25

12  10  65 5:30:25
    1965121005:30:25

12  10  65  5:30 pm
    1965121017:30:00

12  10  65 at 5:30:25
    1965121005:30:25

12  10  1965 at 5:30:25
    1965121005:30:25

12.10.1965 05:61
    nil

12.10.1965 05:30:61
    nil

12/10
    $currY 121000:00:00

12/10 05:30
    $currY 121005:30:00

12/10 at 05:30:25
    $currY 121005:30:25

12/10 at 05:30:25 GMT
    >May safely fail if not in EST timezone.
    $currY 121000:30:25

12/10  5:30
    $currY 121005:30:00

12/10  05:30
    $currY 121005:30:00

12-10  5:30
    $currY 121005:30:00

12.10  05:30
    $currY 121005:30:00

12 10  05:30
    $currY 121005:30:00

2 29 92
    1992022900:00:00

2 29 90
    nil

# Tests Date Time
#       Date%Time
# Date=mmm%dd

Dec/10/1965
    1965121000:00:00

December/10/65
    1965121000:00:00

Dec-10-65
    1965121000:00:00

Dec 10 65
    1965121000:00:00

DecEMBER10 65
    1965121000:00:00

December/10/65 5:30:25
    1965121005:30:25

Dec/10/65/5:30 pm
    1965121017:30:00

Dec/10/65/5:30 pm GMT
    >May safely fail if not in EST timezone.
   1965121012:30:00

Dec/10/65 at 5:30:25
    1965121005:30:25

Dec-10-1965 5:30:25
    1965121005:30:25

December-10-65 5:30:25
    1965121005:30:25

Dec-10-65-5:30 pm
    1965121017:30:00

Dec-10-65 at 5:30:25
    1965121005:30:25

Dec  10  65 5:30:25
    1965121005:30:25

Dec  10  65  5:30 pm
    1965121017:30:00

December  10  65 at 5:30:25
    1965121005:30:25

Dec  10  1965 at 5:30:25
    1965121005:30:25

Dec-10-1965 05:61
    nil

Dec-10-1965 05:30:61
    nil

December/10
    $currY 121000:00:00

Dec/10 05:30
    $currY 121005:30:00

Dec/10 at 05:30:25
    $currY 121005:30:25

Dec/10 at 05:30:25 GMT
    >May safely fail if not in EST timezone.
   $currY 121000:30:25

Dec/10  5:30
    $currY 121005:30:00

Dec/10  05:30
    $currY 121005:30:00

Dec-10  5:30
    $currY 121005:30:00

Dec-10  05:30
    $currY 121005:30:00

December10  05:30
    $currY 121005:30:00

DeC first 1965
    1965120100:00:00

# Tests Date Time
#       Date%Time
# Date=dd%mmm

10/Dec/1965
    1965121000:00:00

10/December/65
    1965121000:00:00

10-Dec-65
    1965121000:00:00

10 Dec 65
    1965121000:00:00

10/December/65 5:30:25
    1965121005:30:25

10/Dec/65/5:30 pm
    1965121017:30:00

10/Dec/65/5:30 pm GMT
    >May safely fail if not in EST timezone.
   1965121012:30:00

10/Dec/65 at 5:30:25
    1965121005:30:25

10-Dec-1965 5:30:25
    1965121005:30:25

10-December-65 5:30:25
    1965121005:30:25

10-Dec-65-5:30 pm
    1965121017:30:00

10-Dec-65 at 5:30:25
    1965121005:30:25

10  Dec   65 5:30:25
    1965121005:30:25

10  Dec 65  5:30 pm
    1965121017:30:00

10December  65 at 5:30:25
    1965121005:30:25

10 Dec  1965 at 5:30:25
    1965121005:30:25

10Dec  1965 at 5:30:25
    1965121005:30:25

10 Dec1965 at 5:30:25
    1965121005:30:25

10Dec1965 at 5:30:25
    1965121005:30:25

10-Dec-1965 05:61
    nil

10-Dec-1965 05:30:61
    nil

10/December
    $currY 121000:00:00

10/Dec 05:30
    $currY 121005:30:00

10/Dec at 05:30:25
    $currY 121005:30:25

10-Dec at 05:30:25 GMT
    >May safely fail if not in EST timezone.
   $currY 121000:30:25

10-Dec  5:30
    $currY 121005:30:00

10/Dec  05:30
    $currY 121005:30:00

10December 05:30
    $currY 121005:30:00

1st DeC 65
    1965120100:00:00

# Tests time only formats
5:30
    $todaydate 05:30:00

5:30:02
    $todaydate 05:30:02

# Tests TimeDate
#       Time%Date
5:30 pm 12/10/65
    1965121017:30:00

5:30 pm GMT 12/10/65
    >May safely fail if not in EST timezone.
    1965121012:30:00

5:30:25/12/10/65
    1965121005:30:25

5:30:25.05/12/10/65
    1965121005:30:25

5:30:25:05/12/10/65
    1965121005:30:25

5:30:25 12-10-1965
    1965121005:30:25

5:30:25 12-10-65
    1965121005:30:25

5:30 pm 12-10-65
    1965121017:30:00

5:30:25/12-10-65
    1965121005:30:25

5:30:25 12  10  65
    1965121005:30:25

5:30 pm 12  10  65
    1965121017:30:00

5:30 pm GMT 12  10  65
    >May safely fail if not in EST timezone.
    1965121012:30:00

5:30:25 12  10  1965
    1965121005:30:25

05:61 12-10-1965
    nil

05:30:61 12-10-1965
    nil

05:30 12/10
    $currY 121005:30:00

05:30/12/10
    $currY 121005:30:00

05:30:25 12/10
    $currY 121005:30:25

05:30:25/12-10
    $currY 121005:30:25

05:30:25 GMT 12/10
    >May safely fail if not in EST timezone.
    $currY 121000:30:25

5:30 12/10
    $currY 121005:30:00

05:30 12/10
    $currY 121005:30:00

5:30 12-10
    $currY 121005:30:00

05:30 12-10
    $currY 121005:30:00

05:30 12 10
    $currY 121005:30:00

# Tests TimeDate
#       Time%Date
# Date=mmm%dd, dd%mmm

4:50  DeC  10
    $currY 121004:50:00

4:50  DeCember  10
    $currY 121004:50:00

4:50:40  DeC  10
    $currY 121004:50:40

4:50:42  DeCember  10
    $currY 121004:50:42

4:50  10  DeC
    $currY 121004:50:00

4:50  10  DeCember
    $currY 121004:50:00

4:50 10DeC
    $currY 121004:50:00

4:50 10DeCember
    $currY 121004:50:00

4:50:51  10  DeC
    $currY 121004:50:51

4:50:52  10  DeCember
    $currY 121004:50:52

4:50:53 10DeC
    $currY 121004:50:53

4:50:54  10DeCember
    $currY 121004:50:54

4:50:54DeCember10
    $currY 121004:50:54

4:50:54DeCember1065
    1965121004:50:54

5:30 DeC 1
    $currY 120105:30:00

05:30 DeC 10
    $currY 121005:30:00

05:30:11 DeC 10
    $currY 121005:30:11

5:30 DeCember 1
    $currY 120105:30:00

05:30 DeCember 10
    $currY 121005:30:00

05:30:12 DeCember 10
    $currY 121005:30:12

# Test ctime formats
DeCember 10 05:30:12 1996
    1996121005:30:12

DeC10 05:30:12 96
    1996121005:30:12

# Test some tricky timezone conversions
Feb 28 1997 23:00-0900
    1997030103:00:00

Feb 27 1997 23:00-0900
    1997022803:00:00

Feb 01 1997 01:00-0100
    1997013121:00:00

Feb 02 1997 01:00-0100
    1997020121:00:00

Feb 02 1997 01:00+0100
    1997020119:00:00

Feb 02 1997 01:00+01
    1997020119:00:00

Feb 02 1997 01:00+01:00
    1997020119:00:00

# More tests...
last day in October 1997
    1997103100:00:00
";

print "Date...\n";
&test_Func(\&ParseDateString,$dates,$runtests);

1;

