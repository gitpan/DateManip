package Date::Manip;

# Copyright (c) 1995,1996 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

###########################################################################
# The following two variables are used in initializing the date
# routines.  This allows support for international dates.

# Which language to use when parsing dates.
$Date::Manip::DefLang="English";

# Most US people look at the date 12/10/96 as MM/DD/YY or Dec 10, 1996.
# Many countries would regard this as Oct 12, 1996 instead.  Setting
# the following variable to "US" forces the first one.  Anything else
# forces the 2nd.
$Date::Manip::DefDateFormat="US";

# The above values are defaults only and can be overidden in a script.
# Refer to the documentation below on Date_Init.
###########################################################################

=head1 NAME

Date::Manip - powerful date manipulation routines

=head1 SYNOPSIS

 use DateManip;

 $date=&ParseDate(\@args)
 $date=&ParseDate($string)
 $date=&ParseDate(\$string)

 @date=&UnixDate($date,@format)
 $date=&UnixDate($date,@format)

 $delta=&ParseDateDelta(\@args)
 $delta=&ParseDateDelta($string)
 $delta=&ParseDateDelta(\$string)

 $d=&DateCalc($d1,$d2,$errref,$del)

 $date=&Date_SetTime($date,$hr,$min,$sec)
 $date=&Date_SetTime($date,$time)

 $date=&Date_GetPrev($date,$dow,$today,$hr,$min,$sec)
 $date=&Date_GetPrev($date,$dow,$today,$time)

 $date=&Date_GetNext($date,$dow,$today,$hr,$min,$sec)
 $date=&Date_GetNext($date,$dow,$today,$time)

 &Date_Init($lang,$format)

 The following routines are used by the above routines (though they can
 also be called directly).  Make sure that $y is entered as the full 4
 digit year... 2 digit years may give wrong results.

 $day=&Date_DayOfWeek($m,$d,$y)
 $secs=&Date_SecsSince1970($m,$d,$y,$h,$mn,$s)
 $days=&Date_DaysSince999($m,$d,$y)
 $day=&Date_DayOfYear($m,$d,$y)
 $days=&Date_DaysInYear($y)
 $wkno=&Date_WeekOfYear($m,$d,$y,$first)
 $flag=&Date_LeapYear($y)
 $day=&Date_DaySuffix($d)
 $tz=&Date_TimeZone()

=head1 DESCRIPTION

This is a set of routines to work with the Gregorian calendar (the one
currently in use).  The Julian calendar defined leap years as every 4th
year.  The Gregorian calendar improved this by making every 100th year
NOT a leap year, unless it was also the 400th year.  The Gregorian
calendar has been extrapolated back to the year 1000 AD and forward to
the year 9999 AD.  Note that in historical context, the Julian calendar
was in use until 1582 when the Gregorian calendar was adopted by the
Catholic church.  Protestant countries did not accept it until later;
Germany and Netherlands in 1698, British Empire in 1752, Russia in 1918.

Note that the Gregorian calendar is itself imperfect.  Each year is on
average 26 seconds too long, which means that every 3,323 years, a day
should be removed from the calendar.  No attempt is made to correct for
that.

Among other things, these routines allow you to:

1.  Enter a date and be able to choose any format conveniant

2.  Compare two dates, entered in widely different formats to determine
    which is earlier

3.  Extract any information you want from ANY date using a format string
    similar to the Unix date command

4.  Determine the amount of time between two dates

5.  Add a time offset to a date to get a second date (i.e. determine the
    date 132 days ago or 2 years and 3 months after Jan 2, 1992)

6.  Work with dates with dates using international formats (foreign month
    names, 12-10-95 referring to October rather than December, etc.).

Each of these tasks is trivial (one or two lines at most) with this package.

Although the word date is used extensively here, it is actually somewhat
misleading.  This package works with the full date AND time (year, month,
day, hour, minute, second).

In the documentation below, US formats are used, but in most cases, a
non-English equivalent will work equally well.

=head1 EXAMPLES

1.  Parsing a date from any conveniant format

  $date=&ParseDate("today");
  $date=&ParseDate("1st thursday in June 1992");
  $date=&ParseDate("05-10-93");
  $date=&ParseDate("12:30 Dec 12th 1880");
  $date=&ParseDate("8:00pm december tenth");
  if (! $date) {
    # Error in the date
  }

2.  Compare two dates

  $date1=&ParseDate($string1);
  $date2=&ParseDate($string2);
  if ($date1 lt $date2) {
    # date1 is earlier
  } else {
    # date2 is earlier (or the two dates are identical)
  }

3.  Extract information from a date.

  print &UnixDate("today","The time is now %T on %b %f, %Y.");
  =>  "The time is now 13:24:08 on Feb  3, 1996."

4.  The amount of time between two dates.

  $date1=&ParseDate($string1);
  $date2=&ParseDate($string2);
  $delta=&DateCalc($date1,$date2,\$err);
  => 0:0:DD:HH:MM:SS   the days, hours, minutes, and seconds between the two
  $delta=&DateCalc($date1,$date2,\$err,1);
  => YY:MM:DD:HH:MM:SS  the years, months, etc. between the two

  Read the documentation below for an explanation of the difference.

5.  To determine a date a given offset from another.

  $date=&DateCalc("today","+ 3hours 12minutes 6 seconds",\$err);
  $date=&DateCalc("12 hours ago","12:30 6Jan90",\$err);

6.  To work with dates in another language.

  &Date_Init("French","non-US");
  $date=&ParseDate("1er decembre 1990");

=over 2

=item ParseDate

 $date=&ParseDate(\@args)
 $date=&ParseDate($string)
 $date=&ParseDate(\$string)

This takes an array or a string containing a date and parses it.  When the
date is included as an array (for example, the arguments to a program) the
array should contain a valid date in the first one or more elements
(elements after a valid date are ignored).  Elements containing a valid
date are shifted from the array.  The largest possible number of elements
which can be correctly interpreted as a valid date are always used.  If a
string is entered rather than an array, that string is tested for a valid
date.  The string is unmodified, even if passed in by reference.

When a part ofq the date is not given, defaults are used: year defaults to
current year; hours, minutes, seconds to 00.

Times may be written as:
  1) HH:MN
     HH:MN:SS
     HH:MN am
     HH:MN:SS am
  2) hh:MN
     hh:MN:SS
     hh:MN am
     hh:MN:SS am

Valid formats for a full date and time (and examples of how Dec 10, 1965 at
9:00 pm might appear) are:
  DateTime
     Date=YYMMDD             1965121021:00:00  65121021:00
     Time=format 1

  Date Time
  Date%Time
    Date=mm%dd, mm%dd%YY     12/10/65 21:00    12 10 1965 9:00pm
    Date=mmm%dd, mmm%dd%YY   December-10-65-9:00:00pm
    Date=dd%mmm, dd%mmm%YY   10/December/65 9:00:00pm

  Date Time
    Date=mmmdd, mmmdd YY, mmmDDYY, mmm DDYY
                             Dec10 65 9:00:00 pm    December 10 1965 9:00pm
    Date=ddmmm, ddmmm YY, ddmmmYY, dd mmmYY
                             10Dec65 9:00:00 pm     10 December 1965 9:00pm

  TimeDate
  Time Date
  Time%Date
    Date=mm%dd, mm%dd%YY     9:00pm 12.10.65      21:00 12/10/1965
    Date=mmm%dd, mmm%dd%YY   9:00pm December/10/65
    Date=dd%mmm, dd%mmm%YY   9:00pm 10-December-65  21:00/10/Dec/65

  TimeDate
  Time Date
    Date=mmmdd, mmmdd YY, mmmDDYY
                             21:00:00DeCeMbEr10
    Date=ddmmm, ddmmm YY, ddmmmYY, dd mmmYY
                             21:00 10Dec95

  which dofw in mmm at time
  which dofw in mmm YY at time  "first sunday in june 1996"

In addition, the following strings are recognized:
  today
  now       (synonym for today)
  yesterday (exactly 24 hours before now)
  tomorrow  (exactly 24 hours from now)

 %       One of the valid date separators: - . / or whitespace (the same
         character must be used for all occurences of a single date)
         example: mm%dd%YY works for 1-1-95, 1 1 95, or 1/1/95
 YY      year in 2 or 4 digit format
 MM      two digit month (01 to 12)
 mm      one or two digit month (1 to 12 or 01 to 12)
 mmm     month name or 3 character abbreviation
 DD      two digit day (01 to 31)
 dd      one or two digit day (1 to 31 or 01 to 31)
 HH      two digit hour in 12 or 24 hour mode (00 to 23)
 hh      one or two digit hour in 12 or 24 hour mode (0 to 23 or 00 to 23)
 MN      two digit minutes (00 to 59)
 SS      two digit seconds (00 to 59)
 which   one of the strings (first-fifth, 1st-5th, or last)
 dofw    either the 3 character abbreviation or full name of a day of
         the week

In the above, the mm%dd formats can be switched to dd%mm by calling
Date_Init and telling it to use a non-US date format.

All "Date Time" and "DateTime" type formats allow the word "at" in them
(i.e.  Jan 12 at 12:00) (and at can replace the space).  So the following
are both acceptable: "Jan 12at12:00" and "Jan 12 at 12:00".  Also, the day
of the week can be given practically anywhere in the date.  If it is given,
it is checked to see if it is correct.  So, the string "Tue Jun 25 1996"
works but "Mon Jun 25 1996" doesn't.  Note that depending on where the
weekday comes, it may give unexpected results when used in array context.
For example, the date ("Jun","25","Sun","1990") would return June 25 of the
current year since only Jun 25, 1990 is not Sunday.

Any time you have HH:MM or HH:MM:SS, it can be followed by an am or pm to
force have it in 12 hour mode (it defaults to 24 hour mode).

The year may be entered as 2 or 4 digits.  If entered as 2 digits, it is
taken to be the year in the range CurrYear-89 to CurrYear+10.  So, if the
current year is 1996, the range is [1907 to 2006] so entering the year 00
crefers to 2000, 05 to 2005, but 07 refers to 1907.

When entered as a single element, the different parts of the date may be
separated by any number of whitespaces including spaces and tabs.

The date returned is YYYYMMDDHH:MM:SS.  The advantage of this time
format is that two times can be compared using simple string
comparisons to find out which is later.

Dates are checked to make sure they are valid.

The elements containing a valid date are removed from the array!  If no
valid date is found, the array is unmodified and nothing returned.

In all of the formats, the day of week ("Friday") can be entered anywhere
in the date and it will be checked for accuracy.  In other words,
  "Tue Jul 16 1996 13:17:00"
will work but
  "Jul 16 1996 Wednesday 13:17:00"
will not (because Jul 16, 1996 is Tuesday, not Wednesday).

=item UnixDate

 @date=&UnixDate($date,@format)
 $date=&UnixDate($date,@format)

This takes a date and a list of strings containing formats roughly
identical to the format strings used by the UNIX date(1) command.  Each
format is parsed and an array of strings corresponding to each format is
returned.

$date must be of the form produced by &ParseDate.

The format options are:

 Year
     %y     year                     - 00 to 99
     %Y     year                     - 0001 to 9999
 Month, Week
     %m     month of year            - 01 to 12
     %f     month of year            - " 1" to "12"
     %b,%h  month abbreviation       - Jan to Dec
     %B     month name               - January to December
     %U     week of year, Sunday
            as first day of week     - 00 to 53
     %W     week of year, Monday
            as first day of week     - 00 to 53
 Day
     %j     day of the year          - 001 to 366
     %d     day of month             - 01 to 31
     %e     day of month             - " 1" to "31"
     %v     weekday abbreviation     - " S"," M"," T"," W","Th"," F","Sa"
     %a     weekday abbreviation     - Sun to Sat
     %A     weekday name             - Sunday to Saturday
     %w     day of week              - 0 (Sunday) to 6
     %E     day of month with suffix - 1st, 2nd, 3rd...
 Hour
     %H     hour                     - 00 to 23
     %k     hour                     - " 0" to "23"
     %i     hour                     - " 1" to "12"
     %I     hour                     - 01 to 12
     %p     AM or PM
 Minute, Second, Timezone
     %M     minute                   - 00 to 59
     %S     second                   - 00 to 59
     %s     seconds from Jan 1, 1970 - negative if before 1/1/1970
     %z,%Z  timezone (3 characters)  - "EDT"
 Date, Time
     %c     %a %b %e %H:%M:%S %Y     - Fri Apr 28 17:23:15 1995
     %C,%u  %a %b %e %H:%M:%S %z %Y  - Fri Apr 28 17:25:57 EDT 1995
     %D,%x  %m/%d/%y                 - 04/28/95
     %l     date in ls(1) format
              %b %e $H:$M            - Apr 28 17:23  (if within 6 months)
              %b %e  %Y              - Apr 28  1993  (otherwise)
     %r     %I:%M:%S %p              - 05:39:55 PM
     %R     %H:%M                    - 17:40
     %T,%X  %H:%M:%S                 - 17:40:58
     %V     %m%d%H%M%y               - 0428174095
     %F     %A, %B %e, %Y            - Sunday, January  1, 1996
 Other formats
     %n     insert a newline character
     %t     insert a tab character
     %%     insert a `%' character
     %+     insert a `+' character
 All other formats insert the character following the %.  If a lone
 percent is the final character in a format, it is ignored.

Note that the ls format applies to date within the past OR future 6 months!

The following formats are currently unused but may be used in the future:
  goq GJKLNOPQ 1234567890 !@#$^&*()_|-=\`[];',./~{}:<>?

This routine is loosely based on date.pl (version 3.2) by Terry McGonigal.
No code was used, but most of his formats were.

=item ParseDateDelta

 $delta=&ParseDateDelta(\@args)
 $delta=&ParseDateDelta($string)
 $delta=&ParseDateDelta(\$string)

This takes an array and shifts a valid delta date (an amount of time)
from the array.  Recognized deltas are of the form:
  +Yy +Mm +Dd +Hh +MNmn +Ss
  +Y:+M:+D:+H:+MN:+S

A field in the format +Yy is a sign, a number, and a string specifying
the type of field.  The sign is "+", "-", or absent (defaults to the
last sign given).  The valid strings specifying the field type
are:
   y:  y, yr, year, years
   m:  m, mon, month, months
   d:  d, day, days
   h:  h, hr, hour, hours
   mn: mn, min, minute, minutes
   s:  s, sec, second, seconds

Also, the "s" string may be omitted.  The sign, number, and string may
all be separated from each other by any number of whitespaces.

In the date, all fields must be given in the order: y m d h mn s.  Any
number of them may be omitted provided the rest remain in the correct
order.  In the 2nd (colon) format, from 2 to 6 of the fields may be given.
For example +D:+H:+MN:+S may be given to specify only four of the fields.
In any case, both the MN and S field may be present.  No spaces may be
present in the colon format.

Deltas may also be given as a combination of the two formats.  For example,
the following is valid: +Yy +D:+H:+MN:+S.  Again, all fields must be given
in the correct order.

The word in may be prepended to the delta ("in 5 years") and the word ago
may be appended ("6 months ago").  The "in" is completely ignored.  The
"ago" has the affect of reversing all signs that appear in front of the
components of the delta.  I.e. "-12 yr 6 mon ago" is identical to "+12yr
+6mon" (don't forget that there is an impled minus sign in front of the 6
because when no sign is explicitely given, it carries the previously
entered sign).

=item DateCalc

 $d=&DateCalc($d1,$d2,\$err,$del)

This takes two dates, deltas, or one of each and performs the appropriate
calculation with them.  Dates must be in the format given by &ParseDate and
or must be a string which can be parsed as a date.  Deltas must be in the
format returned by &ParseDateDelta or must be a string that can be parsed
as a delta.  Two deltas add together to form a third delta.  A date and a
delta returns a 2nd date.  Two dates return a delta (the difference between
the two dates).

Note that in many cases, it is somewhat ambiguous what the delta actually
refers to.  Although it is ALWAYS known how many months in a year, hours in
a day, etc., it is NOT known how many days form a month.  As a result, the
part of the delta containing month/year and the part with sec/min/hr/day
must be treated separately.  For example, "Mar 31, 12:00:00" plus a delta
of 1month 2days would yield "May 2 12:00:00".  The year/month is first
handled while keeping the same date.  Mar 31 plus one month is Apr 31 (but
since Apr only has 30 days, it becomes Apr 30).  Apr 30 + 2 days is May 2.

In the case where two dates are entered, the resulting delta can take on
two different forms.  By default, an absolutely correct delta (ignoring
daylight savings time) is returned in days, hours, minutes, and seconds.
If $del is non-nil, a delta is returned using years and months as well.
The year and month part is calculated first followed by the rest.  For
example, the two dates "Mar 12 1995" and "Apr 10 1995" would have an
absolutely correct delta of "29 days" but if $del is non-nil, it would be
returned as "1 month - 2 days".  Also, "Mar 31" and "Apr 30" would have
deltas of "30 days" or "1 month" (since Apr 31 doesn't exist, it drops down
to Apr 30).

$err is set to:
   1 is returned if $d1 is not a delta or date
   2 is returned if $d2 is not a delta or date
   3 is returned if the date is outside the years 1000 to 9999

Nothing is returned if an error occurs.

If $del is non-nil, both $d1 and $d2 must be dates.

=item Date_SetTime

 $date=&Date_SetTime($date,$hr,$min,$sec)
 $date=&Date_SetTime($date,$time)

This takes a date sets the time in that date.  For example, to get
the time for 7:30 tomorrow, use the lines:

   $date=&ParseDate("tomorrow")
   $date=&Date_SetTime($date,"7:30")

=item Date_GetPrev

 $date=&Date_GetPrev($date,$dow,$today,$hr,$min,$sec)
 $date=&Date_GetPrev($date,$dow,$today,$time)

This takes a date and returns the date of the previous $day.  For example,
if $day is "Fri", it returns the date of the previous Friday.  If $date is
Friday, it will return either $date (if $today is non-zero) or the Friday a
week before (if $today is 0).  The time is also set according to the
optional $hr,$min,$sec (or $time in the format HH:MM:SS).

=item Date_GetNext

 $date=&Date_GetNext($date,$dow,$today,$hr,$min,$sec)
 $date=&Date_GetNext($date,$dow,$today,$time)

Similar to Date_GetPrev.

=item Date_DayOfWeek

 $day=&Date_DayOfWeek($m,$d,$y);

Returns the day of the week (0 for Sunday, 6 for Saturday).  Dec 31, 0999
was Tuesday.

=item Date_SecsSince1970

 $secs=&Date_SecsSince1970($m,$d,$y,$h,$mn,$s)

Returns the number of seconds since Jan 1, 1970 00:00 (negative if date is
earlier).

=item Date_DaysSince999

 $days=&Date_DaysSince999($m,$d,$y)

Returns the number of days since Dec 31, 0999.

=item Date_DayOfYear

 $day=&Date_DayOfYear($m,$d,$y);

Returns the day of the year (001 to 366)

=item Date_DaysInYear

 $days=&Date_DaysInYear($y);

Returns the number of days in the year (365 or 366)

=item Date_WeekOfYear

 $wkno=&Date_WeekOfYear($m,$d,$y,$first);

Figure out week number.  $first is the first day of the week which is
usually 0 (Sunday) or 1 (Monday), but could be any number between 0 and 6
in practice.

=item Date_LeapYear

 $flag=&Date_LeapYear($y);

Returns 1 if the argument is a leap year
Written by David Muir Sharnoff <muir@idiom.com>

=item Date_DaySuffix

 $day=&Date_DaySuffix($d);

Add `st', `nd', `rd', `th' to a date (ie 1st, 22nd, 29th).  Works for
international dates.

=item Date_TimeZone

 $tz=&Date_TimeZone

This returns a timezone.  It looks in the following places for a
timezone in the following order:
   POSIX::tzname
   $ENV{TZ}
   $main::TZ
   /etc/TIMEZONE
If it's not found in any of those places, GMT is returned.
Obviously, this does not guarantee the correct timezone.

=item Date_Init

 $flag=&Date_Init()
 $flag=&Date_Init($lang,$format)

Normally, it is not necessary to explicitely call Date_Init.  The first
time any of the other routines are called, Date_Init will be called to set
everything up.  If for some reason you want to parse dates in multiple
languages, you can pass in the language and format information and
reinitialize everything for a different language.

Recognized values of $lang are "English" and "French".  Others will be
added in the future.  $format should be "US" or any other string.  Most US
people look at the date 12/10/96 as MM/DD/YY or Dec 10, 1996.  Many
countries would regard this as Oct 12, 1996 instead.  Setting the $form
variable to "US" forces the first one.  Anything else forces the 2nd.

=head1 AUTHOR

Sullivan Beck (beck@qtp.ufl.edu)

=cut

require 5.000;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
   ParseDate
   UnixDate
   ParseDateDelta
   DateCalc
   Date_SetTime
   Date_GetPrev
   Date_GetNext
   Date_DayOfWeek
   Date_SecsSince1970
   Date_DaysSince999
   Date_DayOfYear
   Date_DaysInYear
   Date_WeekOfYear
   Date_LeapYear
   Date_DaySuffix
   Date_TimeZone
   Date_Init
);
use strict;
#use POSIX qw(tzname);

########################################################################
# HISTORY
########################################################################

# Written by:
#    Sullivan Beck (beck@qtp.ufl.edu)
# Any suggestions, bug reports, or donations :-) should be sent to
# me.

# Version 1.0  01/20/95
#    Combined all routines into one library
#
# Version 1.1  02/08/95
#    Added leap year checking
#    Both "Feb" and "February" formats available
#
# Version 1.2  03/31/95
#    Made months case insensitive
#    Added a few date formats
#
# Version 2.0  04/17/95
#    Included routines from packages
#       Time::ParseDate (David Muir Sharnoff <muir@idiom.com>)
#       date.pl 3.2     (Terry McGonigal <tmcgonigal@gvc.com>)
#    Made error checking much nicer
#    Added seconds to ParseDate
#
# Version 3.0  05/03/95
#    Added %DATE_ global variable to clean some stuff up
#    Simplified several routines
#    Added today/now/tomorrows/etc. formats
#    Added UnixDate
#    Added ParseDateDelta
#
# Version 4.0  08/13/95
#    Switched to perl 5
#    Cleaned up ParseDate, ParseDateDelta
#    Added time first formats to ParseDate
#    First public release
#
# Version 4.1  10/18/95
#    Changed %DATE_ to %DateManip::Date
#    Rewrote ParseDateDelta
#    Added DataCalc
#
# Version 4.2  10/23/95
#    UnixDate will now return a scalar or list depending on context
#    ParseDate/ParseDateDelta will now take a scalar, a reference to a
#       scalar, or a eference to an array
#    Added copyright notice (requested by Tim Bunce)
#    Simple timezone handling
#    Added Date_SetTime, Date_GetPrev, Date_GetNext
#
# Version 4.3  10/26/95
#    Added "which dofw in mmm" formats to ParseDate
#    Added a bugfix of Adam Nevins where "12:xx pm" used to be parsed
#        "24:xx:00".
#
# Version 5.00  06/21/96
#    Switched to a package (patch supplied by Peter Bray)
#      o  renamed to Date::Manip
#      o  changed version number to 2 decimal places
#      o  added POD documentation
#      Thanks to Peter Bray, Randal Schwartz, Andreas Koenig for ideas
#    Fixed a bug pointed out by Peter Bray where it was complaining of
#       an uninitialized variable.
#
# Version 5.01  06/24/96
#    Fixes suggested by Rob Perelman
#      o  Fixed a typo (Friday misspelled Fridat)
#      o  Documentation problem for \$err in DateCalc
#    Reworked a number of the ParseDate regular expressions to make
#       them more flexible
#    Added "Date at Time" types
#    Weekdays can be entered and checked
#    Two digit years fall in the range CurrYear-89 to CurrYear+10
#
# Version 5.02  07/15/96
#    Fixed a bug where repeated calls to ParseDate("today") was not reset
#    Replaced the %Date::Manip::Date variable with a large number of
#       other, more flexible variables
#    Added some internationalization (most of the routines had to be
#       modified at least slightly)
#    Rewrote the Init routine
#
# Version 5.03  07/17/96
#    Fixed a couple of bugs in UnixDate.
#    Commented out some global variables that were never used.  If needed
#       in the future, uncomment them.  They are marked with "***FUTURE"
#    Declared package variables to avoid warning "Identifier XXX used
#       only once".  Thanks to Peter Bray for the suggestion.

########################################################################
# TODO
########################################################################

# ### SHORT TERM ###

# Add a variable to NOT run Init each time.
# Add better support for the syntax of international dates.
#
# Use Graham Barr's Time::Zone stuff
# ParseDate:
#     ignore commas when they would be appropriate
#     noon, midnight
#     add "next/last Friday", "next/last week"
# ParseDateDelta:
#     add weeks
#
# Fix POSIX::tzname

# ### LONG TERM STUFF ###

# Add full timezone and daylight saving time handling.
# Add "delta FROM date", "IN delta ON date", "delta AGO ON date"

########################################################################
########################################################################
#
# Declare variables so we don't get any warnings about variables only
# being used once.  I often define a whole batch of related variables
# knowing that I only have immediate use for some of them since I may
# need others in the future.  To avoid the "Identifier XXX used only once:
# possibly typo" errors, all are declared here.

#
# Pacakge Variables
#

$Date::Manip::Am = undef;
$Date::Manip::AmExp = undef;
$Date::Manip::AmPmExp = undef;
$Date::Manip::At = undef;
$Date::Manip::Curr = undef;
$Date::Manip::CurrAmPm = undef;
$Date::Manip::CurrD = undef;
$Date::Manip::CurrH = undef;
$Date::Manip::CurrM = undef;
$Date::Manip::CurrMn = undef;
$Date::Manip::CurrS = undef;
$Date::Manip::CurrY = undef;
$Date::Manip::DExp = undef;
$Date::Manip::DateFormat = undef;
$Date::Manip::DayExp = undef;
$Date::Manip::HExp = undef;
$Date::Manip::In = undef;
$Date::Manip::Init = undef;
$Date::Manip::Lang = undef;
$Date::Manip::MExp = undef;
$Date::Manip::MnExp = undef;
$Date::Manip::Mon = undef;
$Date::Manip::MonExp = undef;
$Date::Manip::Month = undef;
$Date::Manip::Now = undef;
$Date::Manip::Offset = undef;
$Date::Manip::Pm = undef;
$Date::Manip::PmExp = undef;
$Date::Manip::SExp = undef;
$Date::Manip::W = undef;
$Date::Manip::Week = undef;
$Date::Manip::WhichExp = undef;
$Date::Manip::Wk = undef;
$Date::Manip::WkExp = undef;
$Date::Manip::YExp = undef;

%Date::Manip::AmPm = ();
%Date::Manip::Day = ();
%Date::Manip::DayInv = ();
%Date::Manip::Mon = ();
%Date::Manip::MonInv = ();
%Date::Manip::Month = ();
%Date::Manip::MonthInv = ();
%Date::Manip::Offset = ();
%Date::Manip::Replace = ();
%Date::Manip::WInv = ();
%Date::Manip::Week = ();
%Date::Manip::WeekInv = ();
%Date::Manip::Which = ();
%Date::Manip::Wk = ();
%Date::Manip::WkInv = ();

########################################################################
########################################################################

sub Date_SetTime {
  my($date,$hr,$min,$sec)=@_;
  my($tmp)=();
  if ($hr =~ /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/) {
    $hr=$1;
    $min=$2;
    $sec=$3   if (defined $3);
    $sec="00" if (! defined $sec);
  } else {
    $hr="00"   if (! defined $hr);
    $min="00"  if (! defined $min);
    $sec="00"  if (! defined $sec);
  }
  return ""  if (! &IsInt($hr,0,23) or
                 ! &IsInt($min,0,59) or
                 ! &IsInt($sec,0,59));
  $tmp=&UnixDate($date,"%Y%m%d") . "$hr:$min:$sec";
  $date=&ParseDate($tmp);
  return $date;
}

sub Date_GetPrev {
  my($date,$day,$today,$hr,$min,$sec)=@_;
  my($day_w)=();
  my($date_w)=&UnixDate($date,"%w");
  my(%days)=%Date::Manip::Wk;
  return ""  if (! exists $days{lc($day)});
  $day_w=$days{lc($day)};
  if ($day_w == $date_w) {
    $date=&DateCalc($date,"-7:0:0:0")  if (! $today);
  } else {
    $day_w -= 7  if ($day_w>$date_w); # make sure previous day is less
    $day = $date_w - $day_w;
    $date=&DateCalc($date,"-$day:0:0:0");
  }
  $date=&Date_SetTime($date,$hr,$min,$sec)  if (defined $hr);
  return $date;
}

sub Date_GetNext {
  my($date,$day,$today,$hr,$min,$sec)=@_;
  my($day_w)=();
  my($date_w)=&UnixDate($date,"%w");
  my(%days)=%Date::Manip::Wk;
  return ""  if (! exists $days{lc($day)});
  $day_w=$days{lc($day)};
  if ($day_w == $date_w) {
    $date=&DateCalc($date,"7:0:0:0")  if (! $today);
  } else {
    $date_w -= 7  if ($date_w>$day_w); # make sure next date is greater
    $day = $day_w - $date_w;
    $date=&DateCalc($date,"$day:0:0:0");
  }
  $date=&Date_SetTime($date,$hr,$min,$sec)  if (defined $hr);
  return $date;
}

sub DateCalc {
  my($D1,$D2,$errref,$del)=@_;
  my($d1,$d2,$tmp,$delta,@delta1,@delta2,@delta,$i,@date1,@date2)=();
  my($y,$m,$d,$h,$mn,$s,@d_in_m)=();

  if ($tmp=&ParseDate([$D1])) {
    $d1=1;
    $D1=$tmp;
  } elsif ($tmp=&ParseDateDelta([$D1])) {
    $d1=0;
    $D1=$tmp;
  } else {
    $$errref=1;
    return;
  }

  if ($tmp=&ParseDate([$D2])) {
    $d2=1;
    $D2=$tmp;
  } elsif ($tmp=&ParseDateDelta([$D2])) {
    $d2=0;
    $D2=$tmp;
  } else {
    $$errref=2;
    return;
  }

  # If there is a date and a delta, the date comes first.
  if ($d1==0 && $d2==1) {
    $tmp=$D2;
    $D2=$D1;
    $D1=$tmp;
    $d1=1;
    $d2=0;
  }

  if ($d1==0 and $d2==0) {
    # Two deltas
    @delta1=split(/:/,$D1);
    @delta2=split(/:/,$D2);
    for ($i=0; $i<6; $i++) {
      $delta[$i]=$delta1[$i]+$delta2[$i];
    }
    $delta=join(":",@delta);
    return $delta;

  } elsif ($d1==1 and $d2==0) {
    # Date, delta
    ($y,$m,$d,$h,$mn,$s)=&UnixDate($D1,"%Y","%m","%d","%H","%M","%S");
    @delta=split(/:/,$D2);

    # do the month/year part
    $tmp=int($delta[1]/12);
    $delta[0] += $tmp;
    $delta[1] -= $tmp*12;
    $m += $delta[1];
    if ($m>12) {
      $m -= 12;
      $delta[0]++;
    } elsif ($m<1) {
      $m += 12;
      $delta[0]--;
    }
    $y += $delta[0];

    # seconds
    $tmp=int($delta[5]/60);
    $delta[5] -= $tmp*60;
    $delta[4] += $tmp;
    $s += $delta[5];
    if ($s>59) {
      $s -= 60;
      $delta[4]++;
    } elsif ($s<0) {
      $s += 60;
      $delta[4]--;
    }

    # minutes
    $tmp=int($delta[4]/60);
    $delta[4] -= $tmp*60;
    $delta[3] += $tmp;
    $mn += $delta[4];
    if ($mn>59) {
      $mn -= 60;
      $delta[3]++;
    } elsif ($mn<0) {
      $mn += 60;
      $delta[3]--;
    }

    # hours
    $tmp=int($delta[3]/24);
    $delta[3] -= $tmp*24;
    $delta[2] += $tmp;
    $h += $delta[3];
    if ($h>23) {
      $h -= 24;
      $delta[2]++;
    } elsif ($h<0) {
      $h += 24;
      $delta[2]--;
    }

    # days
    @d_in_m=(0,31,28,31,30,31,30,31,31,30,31,30,31);
    if (&Date_LeapYear($y)) {
      $d_in_m[2]=29;
    } else {
      $d_in_m[2]=28;
    }
    $d += $delta[2];
    while ($d<1) {
      $m--;
      if ($m==0) {
        $m=12;
        $y--;
        if (&Date_LeapYear($y)) {
          $d_in_m[2]=29;
        } else {
          $d_in_m[2]=28;
        }
      }
      $d += $d_in_m[$m];
    }
    while ($d>$d_in_m[$m]) {
      $d -= $d_in_m[$m];
      $m++;
      if ($m==13) {
        $m=1;
        $y++;
        if (&Date_LeapYear($y)) {
          $d_in_m[2]=29;
        } else {
          $d_in_m[2]=28;
        }
      }
    }
    if ($y<1000 or $y>9999) {
      $$errref=3;
      return;
    }
    $m ="0$m"  if (length($m)<2);
    $d ="0$d"  if (length($d)<2);
    $h ="0$h"  if (length($h)<2);
    $mn="0$mn" if (length($mn)<2);
    $s ="0$s"  if (length($s)<2);
    return "$y$m$d$h:$mn:$s";

  } else {
    # Two dates
    @d_in_m=(0,31,28,31,30,31,30,31,31,30,31,30,31);
    @date1=&UnixDate($D1,"%Y","%m","%d","%H","%M","%S");
    @date2=&UnixDate($D2,"%Y","%m","%d","%H","%M","%S");

    if ($del) {
      # Return delta format

      # make sure that the day in date1 is not past the end of the
      # month in $date2
      if (&Date_LeapYear($date2[0])) {
        $d_in_m[2]=29;
      } else {
        $d_in_m[2]=28;
      }
      $date1[2]=$d_in_m[$date2[1]]  if ($date1[2]>$d_in_m[$date2[1]]);

      # form the delta
      for ($i=0; $i<6; $i++) {
        $delta[$i]=$date2[$i]-$date1[$i];
      }

    } else {
      # Return absolute difference

      # form the delta for hour/min/sec
      for ($i=3; $i<6; $i++) {
        $delta[$i]=$date2[$i]-$date1[$i];
      }

      # form the delta for yr/mon/day
      $delta[0]=$delta[1]=0;
      $d=0;
      if ($date2[0]>$date1[0]) {
        $d=&Date_DaysInYear($date1[0])-
          &Date_DayOfYear($date1[1],$date1[2],$date1[0]);
        $d+=&Date_DayOfYear($date2[1],$date2[2],$date2[0]);
        for ($y=$date1[0]+1; $y<$date2[0]; $y++) {
          $d+= &Date_DaysInYear($y);
        }
      } elsif ($date2[0]<$date1[0]) {
        $d=&Date_DaysInYear($date2[0])-
          &Date_DayOfYear($date2[1],$date2[2],$date2[0]);
        $d+=&Date_DayOfYear($date1[1],$date1[2],$date1[0]);
        for ($y=$date2[0]+1; $y<$date1[0]; $y++) {
          $d+= &Date_DaysInYear($y);
        }
        $d *= -1;
      } else {
        $d=&Date_DayOfYear($date2[1],$date2[2],$date2[0])-
          &Date_DayOfYear($date1[1],$date1[2],$date1[0]);
      }
      $delta[2]=$d;
    }
    $delta=join(":",@delta);
    return $delta;
  }
}

sub ParseDateDelta {
  my($args,@args,@a,$ref,$date)=();
  @a=@_;

  my($y,$m,$d,$h,$mn,$s,$ys,$ms,$ds,$hs,$mns,$ss,$ago)=();
  my($def,@delta1,@delta2,$colon,$sign,$delta,$i,$sign)=();
  my($from,$to)=();

  # @a : is the list of args to ParseDateDelta.  Currently, only one argument
  #      is allowed and it must be a scalar (or a reference to a scalar)
  #      or a reference to an array.

  if ($#a!=0) {
    print "ERROR:  Invalid number of arguments to ParseDateDelta.\n";
    return "";
  }
  $args=$a[0];
  $ref=ref $args;
  if (! $ref) {
    @args=($args);
  } elsif ($ref eq "ARRAY") {
    @args=@$args;
  } elsif ($ref eq "SCALAR") {
    @args=($$args);
  } else {
    print "ERROR:  Invalid arguments to ParseDateDelta.\n";
    return "";
  }
  @a=@args;

  # @args : a list containing all the arguments (dereferenced if appropriate)
  # @a    : a list containing all the arguments currently being examined
  # $ref  : nil, "SCALAR", or "ARRAY" depending on whether a scalar, a
  #         reference to a scalar, or a reference to an array was passed in
  # $args : the scalar or refererence passed in

  my($signexp)='(\+|-)';
  my($numexp)='(\d+)';
  my($exp1)='\s* (?: '.$signexp.'? \s* '.$numexp.'  \s*)?';
  my($yexp) ="(?: $exp1 $Date::Manip::YExp \s* )?";
  my($mexp) ="(?: $exp1 $Date::Manip::MExp \s* )?";
  my($dexp) ="(?: $exp1 $Date::Manip::DExp \s* )?";
  my($hexp) ="(?: $exp1 $Date::Manip::HExp \s* )?";
  my($mnexp)="(?: $exp1 $Date::Manip::MnExp \s* )?";
  my($sexp) ="(?: $exp1 $Date::Manip::SExp? \s* )?";

  $delta="";
  PARSE: while (@a) {
    $_ = join(" ",@a);
    s/\s*$//;

    foreach $from (keys %Date::Manip::Replace) {
      $to=$Date::Manip::Replace{$from};
      s/([^a-zA-Z])$from$/$1$to/i;
      s/([^a-zA-Z])$from([^a-zA-Z])/$1$to$2/i;
    }

    # in or ago
#***INT
    s/^\s* in \s*//ix;
    $ago=1;
#***INT
    $ago=-1  if (s/\s* ago \s*$//ix);

    # the colon part of the delta
    if (s/$signexp?$numexp?(:($signexp?$numexp)?)+$//) {
      $colon=$&;
      @delta2=split(/:/,$colon);
    }

    # the non-colon part of the delta
    $sign="+";
    s/^$yexp $mexp $dexp $hexp $mnexp $sexp$//xi;
    ($ys,$y,$ms,$m,$ds,$d,$hs,$h,$mns,$mn,$ss,$s)=
      ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12);
    (defined($ys))  ? ($sign=$ys)  : ($ys=$sign);
    (defined($ms))  ? ($sign=$ms)  : ($ms=$sign);
    (defined($ds))  ? ($sign=$ds)  : ($ds=$sign);
    (defined($hs))  ? ($sign=$hs)  : ($hs=$sign);
    (defined($mns)) ? ($sign=$mns) : ($mns=$sign);
    (defined($ss))  ? ($sign=$ss)  : ($ss=$sign);

    # keep track of the last defined element (from -1 to 5)
    $def=-1;
    (defined($y))  ? ($def=0) : ($y=0);
    (defined($m))  ? ($def=1) : ($m=0);
    (defined($d))  ? ($def=2) : ($d=0);
    (defined($h))  ? ($def=3) : ($h=0);
    (defined($mn)) ? ($def=4) : ($mn=0);
    (defined($s))  ? ($def=5) : ($s=0);

    @delta1=("$ys$y","$ms$m","$ds$d","$hs$h","$mns$mn","$ss$s");

    # check to see that too many fields have not been entered and that
    # the entire argument list has been used
    if ($_ or ($def+$#delta2)>4) {
      pop(@a);
      next PARSE;
    }

    # set the sign of the colon part
    for ($i=0; $i<=$#delta2; $i++) {
      if ($delta2[$i] =~ /$signexp/) {
        $sign=$1;
      } else {
        $delta2[$i]=$sign.$delta2[$i];
      }
    }

    # add the colon and non-colon part together (and take care of ago)
    unshift (@delta2,"+0")  while ($#delta2<5);
    for ($i=0; $i<=5; $i++) {
      $delta1[$i] += $delta2[$i];
      $delta1[$i] *= $ago  if ($delta1[$i] != 0);
    }

    # form the delta and shift off the valid part
    $delta=join(":",@delta1);
    splice(@args,0,$#a+1);
    @$args=@args  if (defined $ref  and  $ref eq "ARRAY");
    last PARSE;
  }

  return $delta;
}

sub UnixDate {
  my($date,@format)=@_;
  my($format,%f,$out,@out,$c,$date1,$date2)=();
  my($scalar)=();
  $date=&ParseDate($date);
  return  if (! $date);

  $date =~ /^(\d{2}(\d{2}))(\d{2})(\d{2})(\d{2}):(\d{2}):(\d{2})$/;
  ($f{"Y"},$f{"y"},$f{"m"},$f{"d"},$f{"H"},$f{"M"},$f{"S"})=
    ($1,$2,$3,$4,$5,$6,$7);
  my($m,$d,$y)=($f{"m"},$f{"d"},$f{"Y"});
  &Date_Init();

  if (! wantarray) {
    $format=join(" ",@format);
    @format=($format);
    $scalar=1;
  }

  # month, week
  $_=$m;
  s/^0//;
  $f{"b"}=$f{"h"}=$Date::Manip::MonInv{$_};
  $f{"B"}=$Date::Manip::MonthInv{$_};
  $_=$m;
  s/^0/ /;
  $f{"f"}=$_;
  $f{"U"}=&Date_WeekOfYear($m,$d,$y,0);
  $f{"W"}=&Date_WeekOfYear($m,$d,$y,1);

  # day
  $f{"j"}=&Date_DayOfYear($m,$d,$y);
  $_=$d;
  s/^0/ /;
  $f{"e"}=$_;
  $f{"w"}=&Date_DayOfWeek($m,$d,$y);
  $f{"v"}=$Date::Manip::WInv{$f{"w"}};
  $f{"a"}=$Date::Manip::WkInv{$f{"w"}};
  $f{"A"}=$Date::Manip::WeekInv{$f{"w"}};
  $f{"E"}=&Date_DaySuffix($f{"e"});

  # hour
  $_=$f{"H"};
  s/^0/ /;
  $f{"k"}=$_;
  $f{"i"}=$f{"k"}+1;
  $f{"i"}=$f{"k"};
  $f{"i"}=12          if ($f{"k"}==0);
  $f{"i"}=$f{"k"}-12  if ($f{"k"}>12);
  $f{"i"}=$f{"i"}-12  if ($f{"i"}>12);
  $f{"i"}=" ".$f{"i"} if (length($f{"i"})<2);
  $f{"I"}=$f{"i"};
  $f{"I"}=~ s/^ /0/;
  $f{"p"}=$Date::Manip::Am;
  $f{"p"}=$Date::Manip::Pm  if ($f{"k"}>11);

  # minute, second, timezone
  $f{"s"}=&Date_SecsSince1970($m,$d,$y,$f{"H"},$f{"M"},$f{"S"});
  $f{"z"}=$f{"Z"}=&Date_TimeZone;

  # date, time
  $f{"c"}=qq|$f{"a"} $f{"b"} $f{"e"} $f{"H"}:$f{"M"}:$f{"S"} $y|;
  $f{"C"}=$f{"u"}=
    qq|$f{"a"} $f{"b"} $f{"e"} $f{"H"}:$f{"M"}:$f{"S"} $f{"z"} $y|;
  $f{"D"}=$f{"x"}=qq|$m/$d/$f{"y"}|;
  $f{"r"}=qq|$f{"I"}:$f{"M"}:$f{"S"} $f{"p"}|;
  $f{"R"}=qq|$f{"H"}:$f{"M"}|;
  $f{"T"}=$f{"X"}=qq|$f{"H"}:$f{"M"}:$f{"S"}|;
  $f{"V"}=qq|$m$d$f{"H"}$f{"M"}$f{"y"}|;
  $f{"F"}=qq|$f{"A"}, $f{"B"} $f{"e"}, $f{"Y"}|;
  # %l is a special case.  Since it requires the use of the calculator
  # which requires this routine, an infinite recursion results.  To get
  # around this, %l is NOT determined every time this is called so the
  # recursion breaks.

  # other formats
  $f{"n"}="\n";
  $f{"t"}="\t";
  $f{"%"}="%";
  $f{"+"}="+";

  foreach $format (@format) {
    $format=reverse($format);
    $out="";
    while ($format) {
      $c=chop($format);
      if ($c eq "%") {
        $c=chop($format);
        if ($c eq "l") {
          $date1=&DateCalc("now","-6:0:0:0:0");
          $date2=&DateCalc("now","+6:0:0:0:0");
          if ($date gt $date1  and  $date lt $date2) {
            $f{"l"}=qq|$f{"b"} $f{"e"} $f{"H"}:$f{"M"}|;
          } else {
            $f{"l"}=qq|$f{"b"} $f{"e"}  $f{"Y"}|;
          }
          $out .= $f{"$c"};
        } elsif (exists $f{"$c"}) {
          $out .= $f{"$c"};
        } else {
          $out .= $c;
        }
      } else {
        $out .= $c;
      }
    }
    push(@out,$out);
  }
  if ($scalar) {
    return $out[0];
  } else {
    return (@out);
  }
}

sub ParseDate {
  my($args,@args,@a,$ref,$date)=();
  @a=@_;
  my($y,$m,$d,$h,$mn,$s,$ampm,$i,$which,$dofw,$wk,$tmp,$ampm)=();

  # @a : is the list of args to ParseDate.  Currently, only one argument
  #      is allowed and it must be a scalar (or a reference to a scalar)
  #      or a reference to an array.

  if ($#a!=0) {
    print "ERROR:  Invalid number of arguments to ParseDate.\n";
    return "";
  }
  $args=$a[0];
  $ref=ref $args;
  if (! $ref) {
    @args=($args);
  } elsif ($ref eq "ARRAY") {
    @args=@$args;
  } elsif ($ref eq "SCALAR") {
    @args=($$args);
  } else {
    print "ERROR:  Invalid arguments to ParseDate.\n";
    return "";
  }
  @a=@args;

  # @args : a list containing all the arguments (dereferenced if appropriate)
  # @a    : a list containing all the arguments currently being examined
  # $ref  : nil, "SCALAR", or "ARRAY" depending on whether a scalar, a
  #         reference to a scalar, or a reference to an array was passed in
  # $args : the scalar or refererence passed in

  &Date_Init();
  my($type)=$Date::Manip::DateFormat;
  my($monexp)=$Date::Manip::MonExp;
  my($now)=$Date::Manip::Now;
  my($offset)=$Date::Manip::Offset;
  my($wkexp)=$Date::Manip::WkExp;
  my(%dofw)=%Date::Manip::Week;
  my($whichexp)=$Date::Manip::WhichExp;
  my(%which)=%Date::Manip::Which;
  my($daysexp)=$Date::Manip::DayExp;
  my(%dayshash)=%Date::Manip::Day;
  my($ampm)=$Date::Manip::AmPmExp;

  # Regular expressions for part of the date
  my($Yexp) ='(\d{2}|\d{4})'; # 2 or 4 digits (year)
  my($DDexp)='(\d{2})';       # 2 digits      (month/day/hour/minute/second)
  my($Dexp) ='(\d{1,2})';     # 1 or 2 digit  (month/day/hour)
  my($Time)="(?:$DDexp:$DDexp(?::$DDexp)?(?:\\s*$ampm)?)"; # time in HH:MM:SS
  my($time)="(?:$Dexp:$DDexp(?::$DDexp)?(?:\\s*$ampm)?)";  # time in hh:MM:SS
  my($sep)='([\/ .-])';
  my($at)='(?:\s*'.$Date::Manip::At.'\s*)';
  my($in)='(?:\s*'.$Date::Manip::In.'\s*)';

  $date="";
  PARSE: while($#a>=0) {
    $_=join(" ",@a);

    if (/^\s*$whichexp\s*$wkexp$in$monexp\s*$Yexp?(?:$at$time)?\s*$/i) {
      # last friday in October 95
      ($which,$dofw,$m,$y,$h,$mn,$s,$ampm)=($1,$2,$3,$4,$5,$6,$7,$8);
      # fix $m, $y
      &Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk);
      $dofw=$dofw{lc($dofw)};
      $which=$which{lc($which)};
      # Get the first day of the month
      if ($Date::Manip::DateFormat eq "US") {
        $date=&ParseDate("$m 1 $y $h:$mn:$s");
      } else {
        $date=&ParseDate("1 $m $y $h:$mn:$s");
      }
      if ($which==-1) {
        $date=&DateCalc($date,"+1:0:0:0:0");
        $date=&Date_GetPrev($date,$dofw,0);
      } else {
        for ($i=0; $i<$which; $i++) {
          if ($i==0) {
            $date=&Date_GetNext($date,$dofw,1);
          } else {
            $date=&Date_GetNext($date,$dofw,0);
          }
          $date="err", last PARSE  if (! $date);
        }
      }
      last PARSE;
    }

    if (/$wkexp/i) {
      $wk=$1;
      s/$wkexp/ /;
    }
    s/\s+/ /g;                  # all whitespace are now a single space
    s/^\s+//;
    s/\s+$//;

    # Change 2nd, second to 2
    if (/$daysexp/i) {
      $tmp=lc($1);
      $tmp=$dayshash{"$tmp"};
      s/\s*$daysexp\s*/ $tmp /;
      s/^\s+//;
      s/\s+$//;
    }

    if (/^$Yexp$DDexp$DDexp$at?$Time?$/i) {
      # DateTime
      #    Date=YYMMDD
      ($y,$m,$d,$h,$mn,$s,$ampm)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$Dexp$sep$Dexp(?:\2$Yexp)?(?:(?:\s+|$at|\2)$time)?$/i) {
      # Date Time
      # Date%Time
      #   Date=mm%dd, mm%dd%YY
      ($m,$d,$y,$h,$mn,$s,$ampm)=($1,$3,$4,$5,$6,$7,$8);
      ($m,$d)=($d,$m)  if ($type ne "US");

    } elsif (/^$monexp$sep$Dexp(?:\2$Yexp)?(?:(?:\s+|$at|\2)$time)?$/i) {
      # Date Time
      # Date%Time
      #   Date=mmm%dd mmm%dd%YY
      ($m,$d,$y,$h,$mn,$s,$ampm)=($1,$3,$4,$5,$6,$7,$8);

    } elsif (/^$Dexp$sep*$monexp(?:\2$Yexp)?(?:(?:\2|\s+|$at)$time)?$/i) {
      # Date Time
      # Date%Time
      #   Date=dd%mmm, dd%mmm%YY
      ($d,$m,$y,$h,$mn,$s,$ampm)=($1,$3,$4,$5,$6,$7,$8);

    } elsif (/^$Dexp\s*$monexp(?:\s*$Yexp)?(?:(?:\s+|$at)$time)?$/i) {
      # Date Time
      #   Date=ddmmm, ddmmmYY, ddmmm YY, dd mmmYY
      ($d,$m,$y,$h,$mn,$s,$ampm)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$monexp$Dexp(?:\s*$Yexp)?(?:(?:\s+|$at)$time)?$/i) {
      # Date Time
      #   Date=mmmdd, mmmdd YY
      ($m,$d,$y,$h,$mn,$s,$ampm)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$monexp\s*$DDexp(?:$Yexp)?(?:(?:\s+|$at)$time)?$/i) {
      # Date Time
      #   Date=mmm DDYY, mmmDDYY
      ($m,$d,$y,$h,$mn,$s,$ampm)=($1,$2,$3,$4,$5,$6,$7);


    } elsif (/^$time$/) {
      ($h,$mn,$s,$ampm)=($1,$2,$3,$4);

    } elsif (/^$time\s*$Dexp$sep$Dexp(?:\6$Yexp)?$/) {
      # TimeDate
      # Time Date
      #   Date=mm%dd, mm%dd%YY
      ($h,$mn,$s,$ampm,$m,$d,$y)=($1,$2,$3,$4,$5,$7,$8);
      ($m,$d)=($d,$m)  if ($type ne "US");

    } elsif (/^$time$sep$Dexp\5$Dexp(?:\5$Yexp)?$/) {
      # Time%Date
      #   Date=mm%dd mm%dd%YY
      ($h,$mn,$s,$ampm,$m,$d,$y)=($1,$2,$3,$4,$6,$7,$8);
      ($m,$d)=($d,$m)  if ($type ne "US");

    } elsif (/^$time\s*$monexp$sep$Dexp(?:\6$Yexp)?$/i) {
      # TimeDate
      # Time Date
      #   Date=mmm%dd mmm%dd%YY
      ($h,$mn,$s,$ampm,$m,$d,$y)=($1,$2,$3,$4,$5,$7,$8);

    } elsif (/^$time$sep$monexp\5$Dexp(?:\5$Yexp)?$/i) {
      # Time%Date
      #   Date=mmm%dd mmm%dd%YY
      ($h,$mn,$s,$ampm,$m,$d,$y)=($1,$2,$3,$4,$6,$7,$8);

    } elsif (/^$time\s*$Dexp$sep$monexp(?:\6$Yexp)?$/i) {
      # TimeDate
      # Time Date
      #   Date=dd%mmm dd%mmm%YY
      ($h,$mn,$s,$ampm,$d,$m,$y)=($1,$2,$3,$4,$5,$7,$8);

    } elsif (/^$time$sep$Dexp\5$monexp(?:\5$Yexp)?$/i) {
      # Time%Date
      #   Date=dd%mmm dd%mmm%YY
      ($h,$mn,$s,$ampm,$d,$m,$y)=($1,$2,$3,$4,$6,$7,$8);

    } elsif (/^$time\s*$monexp\s*$Dexp(?:\s+$Yexp)?$/i) {
      # TimeDate
      # Time Date
      #   Date=mmmdd, mmmdd YY
      ($h,$mn,$s,$ampm,$m,$d,$y)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$time\s*$monexp\s*$DDexp$Yexp$/i) {
      # TimeDate
      # Time Date
      #   Date=mmmDDYY
      ($h,$mn,$s,$ampm,$m,$d,$y)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$time\s*$Dexp\s*$monexp(?:\s*$Yexp)?$/i) {
      # TimeDate
      # Time Date
      #   Date=ddmmm, ddmmm YY, ddmmmYY
      ($h,$mn,$s,$ampm,$d,$m,$y)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$now$/i) {
      # now, today
      $date=$Date::Manip::Curr;
      last PARSE;

    } elsif (/^$offset$/i) {
      # yesterday, tomorrow
      $offset=$Date::Manip::Offset{lc($1)};
      $date=&DateCalc($Date::Manip::Curr,$offset);
      last PARSE;

    } else {
      pop(@a);
      next PARSE;
    }

    if (&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk)) {
      pop(@a);
    } else {
      last PARSE;
    }
  }

  if ($date ne "err") {
    if (@a) {
      splice(@args,0,$#a+1);
      @$args=@args  if (defined $ref  and  $ref eq "ARRAY");
      return $date  if ($date);
      return "$y$m$d$h:$mn:$s";
    }
  }
  return "";
}

########################################################################
# OTHER SUBROUTINES
########################################################################

sub Date_DayOfWeek {
  my($m,$d,$y)=@_;
  my($dayofweek)=();

  $dayofweek=&Date_DaysSince999($m,$d,$y) % 7;
  return $dayofweek;
}

sub Date_SecsSince1970 {
  my($m,$d,$y,$h,$mn,$s)=@_;
  my($sec_now,$sec_70)=();
  $sec_now=(&Date_DaysSince999($m,$d,$y)-1)*24*3600 + $h*3600 + $mn*60 + $s;
  $sec_70 =(&Date_DaysSince999(1,1,1970)-1)*24*3600;
  return ($sec_now-$sec_70);
}

sub Date_DaysSince999 {
  my($m,$d,$y)=@_;
  my($Ny,$N4,$N100,$N400,$dayofyear,$days,$dec31)=();
  my($cc,$yy)=();

  $dec31=2;                     # Dec 31, 0999 was Tuesday
  $y=~ /(\d{2})(\d{2})/;
  ($cc,$yy)=($1,$2);

  # Number of full years since Dec 31, 0999
  $Ny=$y-1000;

  # Number of full 4th years (incl. 1000) since Dec 31, 0999
  $N4=int(($Ny-1)/4)+1;
  $N4=0         if ($y==1000);

  # Number of full 100th years (incl. 1000)
  $N100=$cc-9;
  $N100--       if ($yy==0);

  # Number of full 400th years
  $N400=int(($N100+1)/4);

  $dayofyear=&Date_DayOfYear($m,$d,$y);
  $days= $Ny*365 + $N4 - $N100 + $N400 + $dayofyear + $dec31;

  return $days;
}

sub Date_DayOfYear {
  my($m,$d,$y)=@_;
  my(@daysinmonth)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
  my($daynum,$i)=();
  $daysinmonth[2]=29  if (&Date_LeapYear($y));
  $daynum=0;
  for ($i=1; $i<$m; $i++) {
    $daynum += $daysinmonth[$i];
  }
  $daynum += $d;
  $daynum="0$daynum"   if ($daynum<10);
  $daynum="0$daynum"   if ($daynum<100);
  return $daynum;
}

sub Date_DaysInYear {
  my($y)=@_;
  return 366  if (&Date_LeapYear($y));
  return 365;
}

sub Date_WeekOfYear {
  my($m,$d,$y,$f)=@_;
  my($jan1)=&Date_DayOfWeek(1,1,$y); # Jan 1 is what day of week
  my($dofy)=&Date_DayOfYear($m,$d,$y);

  # Renumber the days (still 0 to 6) so that the first day of
  # the week is always 0.
  $jan1=$jan1-$f;
  $jan1+=7 if ($jan1<0);

  # Add days to the beginning of the year so that the first day
  # of this "extended" year falls on the first day of the week and
  # is numbered day 0 (rather than day 1).
  $dofy+=$jan1-1;

  return (int($dofy/7)+1);
}

sub Date_LeapYear {
  my($y)=@_;
  return 0 unless $y % 4 == 0;
  return 1 unless $y % 100 == 0;
  return 0 unless $y % 400 == 0;
  return 1;
}

sub Date_DaySuffix {
  my($d)=@_;
  return $Date::Manip::DayInv{$d};
}

sub Date_TimeZone {
  my($null,$tz)=();

  SWITCH: {

#    $tz=POSIX::tzname();
#    $tz=~ s/\s*//;
#    last SWITCH  if (defined $tz  and  $tz);

    if (exists $ENV{"TZ"}) {
      $tz=$ENV{"TZ"};
      $tz=~ s/\s*//;
      last SWITCH  if (defined $tz  and  $tz);
    }

    if (defined $main::TZ) {
      $tz=$main::TZ;
      $tz=~ s/\s*//;
      last SWITCH  if (defined $tz  and  $tz);
    }

    if (-e "/etc/TIMEZONE") {
      ($null,$tz) = split (/\=/,`grep ^TZ /etc/TIMEZONE`);
      chop($tz);
      $tz=~ s/\s*//;
      last SWITCH  if (defined $tz  and  $tz);
    }

    $tz="GMT";
  }

  # parse timezone (to 3 character date format)
  # *** NOT DONE YET ***

  return $tz;
}

sub Date_Init {
  my($language,$format)=@_;
  if (defined $language) {
    $Date::Manip::Init=0;
    $Date::Manip::Lang=$language;
    $Date::Manip::DateFormat=$format;
  } elsif (! $Date::Manip::Lang) {
    $Date::Manip::Lang=$Date::Manip::DefLang;
    $Date::Manip::DateFormat=$Date::Manip::DefDateFormat;
    $Date::Manip::Init=0;
  }

  my($i,$j,@tmp,@tmp2,@tmp3,$a,$b,$now,$offset,$last,$in,$at,
     $mon,$month,@mon,@month,
     $w,$wk,$week,@w,@wk,@week,
     $days,@days,$am,$pm,
     $years,$months,$days,$hours,$minutes,$seconds,$replace)=();
  my($lang)=$Date::Manip::Lang;

  if (! $Date::Manip::Init) {
    $Date::Manip::Init=1;

    # Set the following variables based on the language (they should all
    # be capitalized correctly):
    #  $month   : space separated string containing months spelled out
    #  $mon     : space separated string containing months abbreviated
    #  $week    : space separated string containing weekdays spelled out
    #  $wk      : space separated string containing weekdays abbreviated
    #  $w       : space separated string containing weekdays very abbreviated
    #  $am,$pm  : different ways of expressing AM (separated by "|"), the
    #             first one in each list is the one that will be used when
    #             printing out an AM or PM string
    #  @days    : different ways that numbers can appear as days (first, 1st,
    #             etc.  Each element of @days has a space separated string
    #             with up to 31 values).  The first one should contain the
    #             nubers in the 1st, 2nd, etc. format.
    #  $last    : strings containing synonyms for last
    #  $years   : string containing abbreviations for the word year
    #  $months  : string containing abbreviations for the word month
    #  $days    : string containing abbreviations for the word day
    #  $hours   : string containing abbreviations for the word hour
    #  $minutes : string containing abbreviations for the word minute
    #  $seconds : string containing abbreviations for the word second
    #  $now     : string containing words referring to now
    #  $in      : strings fitting "1st sunday in June"
    #  $at      : strings fitting "at 12:00"
    #
    # One important variable is $replace.  In English (and probably
    # other languages), one of the abbreviations for the word month that
    # would be nice is "m".  The problem is that "m" matches the "m" in
    # "minute" which causes the string to be improperly matched in some
    # cases.  Hence, the list of abbreviations for month is given as:
    #   "mon month months"
    # In order to allow you to enter "m", replacements can be done.
    # $replace is a list of pairs of words which are matched and replaced
    # AS ENTIRE WORDS".  Having $replace equal to "m month" means that
    # the entire word "m" will be replaced with "month".  This allows the
    # desired abbreviation to be used.  Make sure that $replace contains
    # an even number of words (i.e. all must be pairs).
    #
    # One other variable to set is $offset.  This contains a space separated
    # set of dates which are defined as offsets from the current time.

    if ($lang eq "English") {
      $month="January February March April May June ".
        "July August September October November December";
      $mon="Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec";

      $week="Sunday Monday Tuesday Wednesday Thursday Friday Saturday";
      $wk="Sun Mon Tue Wed Thu Fri Sat";
      $w="S M T W Th F Sa";

      $days[0]="1st 2nd 3rd 4th 5th 6th 7th 8th 9th 10th 11th 12th 13th 14th ".
        "15th 16th 17th 18th 19th 20th 21st 22nd 23rd 24th 25th 26th 27th ".
        "28th 29th 30th 31st";
      $days[1]="first second third fourth fifth sixth seventh eighth ninth ".
        "tenth eleventh twelfth thirteenth fourteenth fifteenth sixteenth ".
        "seventeenth eighteenth nineteenth twentieth twenty-first ".
        "twenty-second twenty-third twenty-fourth twenty-fifth twenty-sixth ".
        "twenty-seventh twenty-eighth twenty-ninth thirtieth thirty-first";

      $last="last";
      $in="in of";
      $at="at";

      $am="AM";
      $pm="PM";

      $years  ="y yr year yrs years";
      $months ="mon month months";
      $days   ="d day days";
      $hours  ="h hr hrs hour hours";
      $minutes="mn min minute minutes";
      $seconds="s sec second seconds";
      $replace="m month";

      $now="today now";
      $offset="yesterday -1:0:0:0 tomorrow +1:0:0:0";

    } elsif ($lang eq "French") {
      $month="janvier fevrier mars avril mai juin juillet aout ".
        "septembre octobre novembre decembre";
      # NOTE: I am not sure what the abbreviation for juin and juillet are.
      $mon="jan fev mar avr mai juin juil aou sep oct nov dec";

      $week="dimanche lundi mardi mercredi jeudi vendredi samedi";
      $wk="dim lun mar mer jeu ven sam";
      $w="d l ma me j v s";

      @tmp=map { ($_."e"); } (1...31);
      $tmp[0] = "1er";
      $days[0]=join " ",@tmp;   # 1er 2e 3e ...
      $days[1]="1re";           # 1re
      $days[2]="premier deux trois quatre cinq six sept huit neuf dix onze ".
        "douze treize quatorze quinze size dix-sept dix-huit dix-neuf vingt ".
        "vingt-et-un vingt-deux vingt-trois vingt-quatre vingt-cinq ".
        "vingt-six vingt-sept vingt-huit vingt-neuf trente trente-et-un";

      $last="dernier";
      $in="en de";
      $at="a";

      $am="du matin";
      $pm="du soir";

      $years  ="an annee ans annees";
      $months ="mois";
      $days   ="j jour jours";
      $hours  ="h heure heures";
      $minutes="mn min minute minutes";
      $seconds="s sec seconde secondes";
      $replace="m mois";

      $now="aujourd'hui maintenant";
      $offset="hier -1:0:0:0 demain +1:0:0:0";

    } elsif ($lang eq "Spanish") {
      $month="enero febrero marzo abril mayo junio julio agosto ".
        "septiembre octubre noviembre diciembre";
      $mon="ene feb mar abr may jun jul ago sep oct nov dic";

      $week="domingo lunes martes miercoles jueves viernes sabado";
      $wk="dom lun mar mier jue vie sab";
      $w="d l ma mi j v s";

    # } elsif ($lang eq "Italian") {
    # } elsif ($lang eq "Portugese") {
    # } elsif ($lang eq "German") {
    # } elsif ($lang eq "Russian") {

    } else {
      die "ERROR: Unknown language in Date::Manip.\n";
    }

    # Date::Manip:: variables for months
    #   $Mon      : "jan feb ... "
    #   $Month    : "january february ... "
    #   $MonExp   : "(jan|january|feb|february ... )"
    #   %Mon      : ("jan",1,"january",1, ...)
    #   %MonInv   : (1,"Jan",2,"Feb",...)
    #   %MonthInv : (1,"January",2,"February", ...)
    #   %Month    : ("january","jan","jan","jan", ...)
    $Date::Manip::Mon = lc($mon);
    $Date::Manip::Month = lc($month);
    @mon=split(/\s+/,$mon);
    @month=split(/\s+/,$month);
    $mon=join "|",@mon;
    $month=join "|",@month;
    $Date::Manip::MonExp = "(".lc($mon)."|".lc($month).")";
    for ($i=0; $i<12; $i++) {
      $mon=$mon[$i];
      $month=$month[$i];
      $Date::Manip::Mon{lc($mon)}=$i+1;
      $Date::Manip::Mon{lc($month)}=$i+1;
      $Date::Manip::MonInv{$i+1}=$mon;
      $Date::Manip::MonthInv{$i+1}=$month;
      $Date::Manip::Month{lc($month)}=lc($mon);
      $Date::Manip::Month{lc($mon)}=lc($mon);
    }

    # Date::Manip:: variables for day of week
    #   $W      : "s m t w th f sa"
    #   $Wk     : "sun mon ... "
    #   $Week   : "sunday monday ... "
    #   $WkExp  : "(sun|sunday|mon|monday ... )"
    #   %Wk     : ("sun",0,"sunday",0,...)
    #   %WInv   : ("S",0,...)
    #   %WkInv  : (0,"Sun",1,"Mon",...)
    #   %WeekInv: (0,"Sunday",1,"Monday",...)
    #   %Week   : ("sunday","sun","sun","sun",...)
    $Date::Manip::W = lc($w);
    $Date::Manip::Wk = lc($wk);
    $Date::Manip::Week = lc($week);
    @w=split(/\s+/,$w);
    @wk=split(/\s+/,$wk);
    @week=split(/\s+/,$week);
    $wk=join "|",@wk;
    $week=join "|",@week;
    $Date::Manip::WkExp = "(".lc($wk)."|".lc($week).")";
    for ($i=0; $i<7; $i++) {
      $w=$w[$i];
      $wk=$wk[$i];
      $week=$week[$i];
      $Date::Manip::Wk{lc($wk)}=$i;
      $Date::Manip::Wk{lc($week)}=$i;
      $Date::Manip::WInv{$i}=$w;
      $Date::Manip::WkInv{$i}=$wk;
      $Date::Manip::WeekInv{$i}=$week;
      $Date::Manip::Week{lc($wk)}=lc($wk);
      $Date::Manip::Week{lc($week)}=lc($wk);
    }

    # Date::Manip:: variables for day of week
    #   $DayExp   : "(1st|first|2nd|second ... )"
    #   %Day      : ("1st",1,"first",1, ... )"
    #   %DayInv   : (1,"1st",...);
    # Date::Manip:: variables for week of month
    #   $WhichExp : "(1st|first|2nd|second ... fifth|last)"
    #   %Which    : ("1st",1,"first",1, ... "fifth",5,"last",-1)"
    @tmp2=();
    @tmp3=();
    $j=1;
    foreach $days (@days) {
      $days=lc($days);
      @tmp=split(/\s+/,$days);
      push(@tmp2,@tmp);
      push(@tmp3,@tmp[0..4]);
      $i=1;
      foreach (@tmp) {
        $Date::Manip::Day{$_}=$i;
        $Date::Manip::Which{$_}=$i  if ($i<6);
        $Date::Manip::DayInv{$i}=$_ if ($j==1);
        s/-/ /g;
        $Date::Manip::Day{$_}=$i;
        $Date::Manip::Which{$_}=$i  if ($i<6);
        $i++;
      }
      $j=0;
    }
    push(@tmp3,split(/\s+/,$last));
    # sort the strings by length, longest to shortest so they get matched
    # correctly ("first" doesn't match "twenty-first")
    @tmp2=sort { -(length($Date::Manip::a)<=>length($Date::Manip::b)) } @tmp2;
    $Date::Manip::DayExp="(".join("|",@tmp2).")";
    @tmp3=sort { -(length($Date::Manip::a)<=>length($Date::Manip::b)) } @tmp3;
    $Date::Manip::WhichExp="(".join("|",@tmp3).")";
    foreach (split(/\s+/,lc($last))) {
      $Date::Manip::Which{$_}=-1;
    }

    # Date::Manip:: variables for AM or PM
    #   $AmExp   : "(am)"
    #   $PmExp   : "(pm)"
    #   $AmPmExp : "(am|pm)"
    #   %AmPm    : (am,1,pm,2)
    #   $Am      : "AM"
    #   $Pm      : "PM"
    $Date::Manip::AmPmExp="(".lc($am)."|".lc($pm).")";
    %Date::Manip::AmPm= ((map { ($_,1); } split(/\|/,lc($am))) ,
                         (map { ($_,2); } split(/\|/,lc($pm))));
    $Date::Manip::Am=(split(/\|/,$am))[0];
    $Date::Manip::Pm=(split(/\|/,$pm))[0];
    $i='\s+';
    $am=~ s/ /$i/g;
    $pm=~ s/ /$i/g;
    $Date::Manip::AmExp="(".lc($am).")";
    $Date::Manip::PmExp="(".lc($pm).")";

    # Date::Manip:: variables for expressions used in parsing deltas
    #    $YExp   : "(?:y|yr|year|years)"
    #    $MExp   : similar for months
    #    $DExp   : similar for days
    #    $HExp   : similar for hours
    #    $MnExp  : similar for minutes
    #    $SExp   : similar for seconds
    #    %Replace: a list of replacements
    $Date::Manip::YExp ="(?:". join("|",split(/\s+/,lc($years))) .")";
    $Date::Manip::MExp ="(?:". join("|",split(/\s+/,lc($months))) .")";
    $Date::Manip::DExp ="(?:". join("|",split(/\s+/,lc($days))) .")";
    $Date::Manip::HExp ="(?:". join("|",split(/\s+/,lc($hours))) .")";
    $Date::Manip::MnExp="(?:". join("|",split(/\s+/,lc($minutes))) .")";
    $Date::Manip::SExp ="(?:". join("|",split(/\s+/,lc($seconds))) .")";
    %Date::Manip::Replace=split(/\s+/,lc($replace));

    # Date::Manip:: variables for special dates that are offsets from now
    #    $Now    : "(now|today)"
    #    $Offset : "(yesterday|tomorrow)"
    #    %Offset : ("yesterday","-1:0:0:0",...)
    $Date::Manip::Now="(". join("|",split(/\s+/,lc($now))) .")";
    %Date::Manip::Offset=split(/\s+/,lc($offset));
    $Date::Manip::Offset="(". join("|",keys %Date::Manip::Offset) .")";

    # Date::Manip:: misc. variables
    #    $At     : "(?:at)"
    #    $In     : "(?:in|of)"
    $Date::Manip::At="(?:". join("|",split(/\s+/,lc($at))) .")";
    $Date::Manip::In="(?:". join("|",split(/\s+/,lc($in))) .")";

  }

  # current time
  my($s,$mn,$h,$d,$m,$y,$wday,$yday,$isdst)=localtime(time);
  $y+=1900;
  my($ampm,$wk)=();
  $m++;
  &Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk);
  $Date::Manip::CurrY=$y;
  $Date::Manip::CurrM=$m;
  $Date::Manip::CurrD=$d;
  $Date::Manip::CurrH=$h;
  $Date::Manip::CurrMn=$mn;
  $Date::Manip::CurrS=$s;
  $Date::Manip::CurrAmPm=$ampm;
  $Date::Manip::Curr="$y$m$d$h:$mn:$s";
}

########################################################################
# NOT FOR EXPORT
########################################################################

# $flag=&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk);
#   Returns 1 if any of the fields are bad.  All fields are optional, and
#   all possible checks are done on the data.  If a field is not passed in,
#   it is set to default values.  If data is missing, appropriate defaults
#   are supplied.
sub Date_ErrorCheck {
  my($y,$m,$d,$h,$mn,$s,$ampm,$wk)=@_;
  my($tmp1,$tmp2,$tmp3)=();

  my(@d_in_m)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
  my(@mon)=split(/\s+/,$Date::Manip::Mon);
  my(@month)=split(/\s+/,$Date::Manip::Month);
  my($curr_y)=$Date::Manip::CurrY;
  my($curr_m)=$Date::Manip::CurrM;
  my($curr_d)=$Date::Manip::CurrD;
  my(@dofwk)=split(/\s+/,$Date::Manip::Wk);
  my(@dofweek)=split(/\s+/,$Date::Manip::Week);
  $$y=""     if (! defined $$y);
  $$m=""     if (! defined $$m);
  $$d=""     if (! defined $$d);
  $$h=""     if (! defined $$h);
  $$mn=""    if (! defined $$mn);
  $$s=""     if (! defined $$s);
  $$ampm=""  if (! defined $$ampm);
  $$ampm=uc($$ampm)  if ($$ampm);
  $$wk=""    if (! defined $$wk);

  # Check year.
  $$y=$curr_y    if ($$y eq "");
  if (length($$y)==2) {
    $tmp1=$curr_y-89;
    $$y="19$$y";
    while ($$y<$tmp1) {
      $$y+=100;
    }
  }
  return 1       if (! &IsInt($$y,1,9999));
  $d_in_m[2]=29  if (&Date_LeapYear($$y));

  # Check month
  $$m=$curr_m     if ($$m eq "");
  $tmp1=&SinLindex(\@mon,$$m,0,1)+1;
  $tmp2=&SinLindex(\@month,$$m,0,1)+1;
  $$m=$tmp1       if ($tmp1>0);
  $$m=$tmp2       if ($tmp2>0);
  $$m="0$$m"      if (length($$m)==1);
  return 1        if (! &IsInt($$m,1,12));

  # Check day
  $$d=$curr_d     if ($$d eq "");
  $$d="0$$d"      if (length($$d)==1);
  return 1        if (! &IsInt($$d,1,$d_in_m[$$m]));
  if ($$wk) {
    $tmp1=&Date_DayOfWeek($$m,$$d,$$y);
    $tmp2=$dofwk[$tmp1];
    $tmp3=$dofweek[$tmp1];
    return 1      if ($$wk !~ /^$tmp2$/i  and
                      $$wk !~ /^$tmp3$/i);
  }

  # Check hour
  $tmp1=$Date::Manip::AmPmExp;
  if ($$ampm =~ /^$tmp1$/i) {
    $tmp3=$Date::Manip::AmExp;
    $tmp2="AM"  if ($$ampm =~ /^$tmp3$/i);
    $tmp3=$Date::Manip::PmExp;
    $tmp2="PM"  if ($$ampm =~ /^$tmp3$/i);
  } elsif ($$ampm) {
    return 1;
  }
  if ($tmp2 eq "AM" || $tmp2 eq "PM") {
    $$h="0$$h"    if (length($$h)==1);
    return 1      if ($$h<1 || $$h>12);
    $$h="00"      if ($tmp2 eq "AM"  and  $$h==12);
    $$h += 12     if ($tmp2 eq "PM"  and  $$h!=12);
  } else {
    $$h="00"      if ($$h eq "");
    $$h="0$$h"    if (length($$h)==1);
    return 1      if (! &IsInt($$h,0,23));
    $tmp2="AM"    if ($$h<12);
    $tmp2="PM"    if ($$h>=12);
  }
  $$ampm=$Date::Manip::Am;
  $$ampm=$Date::Manip::Pm  if ($tmp2 eq "PM");

  # Check minutes
  $$mn="00"       if ($$mn eq "");
  $$mn="0$$mn"    if (length($$mn)==1);
  return 1        if (! &IsInt($$mn,0,59));

  # Check seconds
  $$s="00"        if ($$s eq "");
  $$s="0$$s"      if (length($$s)==1);
  return 1        if (! &IsInt($$s,0,59));

  return 0;
}

sub IsInt {
  my($N,$low,$high)=@_;
  return 0 if ($N eq "");
  my($sign)='^\s* [-+]? \s*';
  my($int) ='\d+ \s* $ ';
  if ($N =~ /$sign $int/x) {
    if (defined $low  and  defined $high) {
      return 1  if ($N>=$low  and  $N<=$high);
      return 0;
    }
    return 1;
  }
  return 0;
}
sub SinLindex {
  my($listref,$Str,$Offset,$Insensitive)=@_;
  my($i,$len,$tmp)=();
  $len=$#$listref;
  return -2  if ($len<0 or ! $Str);
  return -1  if (&Index_First(\$Offset,$len));
  $Str=uc($Str)  if ($Insensitive);
  for ($i=$Offset; $i<=$len; $i++) {
    $tmp=$$listref[$i];
    $tmp=uc($tmp)  if ($Insensitive);
    return $i  if ($tmp eq $Str);
  }
  return -1;
}
sub Index_First {
  my($Offsetref,$max)=@_;
  $$Offsetref=0  if (! $$Offsetref);
  if ($$Offsetref < 0) {
    $$Offsetref += $max + 1;
    $$Offsetref=0  if ($$Offsetref < 0);
  }
  return -1 if ($$Offsetref > $max);
  return 0;
}

1;

# Local Variables: #
# mode: perl #
# End: #
