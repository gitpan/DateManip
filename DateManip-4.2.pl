#!/usr/local/bin/perl -w

# This is a set of routines to work with the Gregorian calendar (the one
# currently in use).  The Julian calendar defined leap years as every 4th
# year.  The Gregorian calendar improved this by making every 100th year
# NOT a leap year, unless it was also the 400th year.  The Gregorian
# calendar has been extrapolated back to the year 1000 AD and forward to
# the year 9999 AD.  Note that in historical context, the Julian calendar
# was in use until 1582 when the Gregorian calendar was adopted by the
# Catholic church.  Protestant countries did not accept it until later;
# Germany and Netherlands in 1698, British Empire in 1752, Russia in 1918.
#
# Note that the Gregorian calendar is itself imperfect.  Each year is on
# average 26 seconds too long, which means that every 3,323 years, a day
# should be removed from the calendar.  No attempt is made to correct for
# that.

# Copyright (c) 1995 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
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

########################################################################
# TODO
########################################################################

# ParseDate:
#     am/pm format
#     day of week (ignored)
#     noon, midnight
# UnixDate:
#     time zone
# ParseDateDelta:
#     add weeks
#     add "next/last Friday", "next/last week"
#
# Add full timezone and daylight saving time handling.

########################################################################
########################################################################

require 5.000;
use POSIX qw(tzname);
use strict 'vars';

# $d=&DateCalc($d1,$d2,$errref,$del);
#   This takes two dates/deltas in the formats given by &ParseDate and
#   &ParseDateDelta respectively.  Two deltas add together to form a
#   third delta.  A date and a delta returns a 2nd date.  Two dates
#   return a delta (the difference between the two dates).
#
#   Note that in some cases, it is somewhat ambiguous what the delta
#   actually refers to.  Although it is ALWAYS known how many months
#   in a year, hours in a day, etc., it is NOT known how many days form
#   a month.  As a result, the part of the delta containing month/year
#   and the part with sec/min/hr/day must be treated separately.  For
#   example, "Mar 31, 12:00:00" plus a delta of 1month 2day would yield
#   "May 2 12:00:00".  The year/month is first handled while keeping the
#   same date.  Mar 31 plus one month is Apr 31 (but since Apr only has
#   30 days, it becomes Apr 30).  Apr 30 + 2 days is May 2.
#
#   In the case where two dates are entered, the resulting delta can take
#   on two different forms.  By default, an absolutely correct delta
#   (ignoring daylight savings time) is returned in days, hours, minutes,
#   and seconds.  If $del is non-nil, a delta is returned using years and
#   months as well.  The year and month part is calculated first followed
#   by the rest.  For example, the two dates "Mar 12 1995" and "Apr 10 1995"
#   would have an absolutely correct delta of "29 days" but if $del
#   is non-nil, it would be returned as "1 month - 2 days".  Also, "Mar 31"
#   and "Apr 30" would have deltas of "30 days" or "1 month" (since Apr 31
#   doesn't exist, it drops down to Apr 30).
#
#   $err is set to:
#      1 is returned if $d1 is not a delta or date
#      2 is returned if $d2 is not a delta or date
#      3 is returned if the date is outside the years 1000 to 9999
#
#   Nothing is returned if an error occurs.
#
#   If $del is non-nil, both $d1 and $d2 must be dates.  In this case,
#   a delta if formed from the two dates.

# @date=&UnixDate($date,@format);
# $date=&UnixDate($date,@format);
#   This takes a date and a list of strings containing formats roughly
#   identical to the format strings used by the UNIX date(1) command.
#   Each format is parsed and an array of strings corresponding to each
#   format is returned.
#
#   $date must be of the form produced by &ParseDate.
#
#   The format options are:
#
#     Year
#         %y     year                     - 00 to 99
#         %Y     year                     - 0001 to 9999
#     Month, Week
#         %m     month of year            - 01 to 12
#         %f     month of year            - " 1" to "12"
#         %b,%h  month abbreviation       - Jan to Dec
#         %B     month name               - January to December
#         %U     week of year, Sunday
#                as first day of week     - 00 to 53
#         %W     week of year, Monday
#                as first day of week     - 00 to 53
#     Day
#         %j     day of the year          - 001 to 366
#         %d     day of month             - 01 to 31
#         %e     day of month             - " 1" to "31"
#         %v     weekday abbreviation     - " S"," M"," T"," W","Th"," F","Sa"
#         %a     weekday abbreviation     - Sun to Sat
#         %A     weekday name             - Sunday to Saturday
#         %w     day of week              - 0 (Sunday) to 6
#         %E     day of month with suffix - 1st, 2nd, 3rd...
#     Hour
#         %H     hour                     - 00 to 23
#         %k     hour                     - " 0" to "23"
#         %i     hour                     - " 1" to "12"
#         %I     hour                     - 01 to 12
#         %p     AM or PM
#     Minute, Second, Timezone
#         %M     minute                   - 00 to 59
#         %S     second                   - 00 to 59
#         %s     seconds from Jan 1, 1970 : negative if before 1/1/1970
#         %z,%Z  timezone (3 characters)  : "EDT"
#     Date, Time
#         %c     %a %b %e %H:%M:%S %Y     : Fri Apr 28 17:23:15 1995
#         %C,%u  %a %b %e %H:%M:%S %z %Y  : Fri Apr 28 17:25:57 EDT 1995
#         %D,%x  %m/%d/%y                 : 04/28/95
#         %l     date in ls(1) format
#                  %b %e $H:$M            : Apr 28 17:23  (if within 6 months)
#                  %b %e  %Y              : Apr 28  1993  (otherwise)
#         %r     %I:%M:%S %p              : 05:39:55 PM
#         %R     %H:%M                    : 17:40
#         %T,%X  %H:%M:%S                 : 17:40:58
#         %V     %m%d%H%M%y               : 0428174095
#     Other formats
#         %n     insert a newline character
#         %t     insert a tab character
#         %%     insert a `%' character
#         %+     insert a `+' character
#     All other formats insert the character following the %.  If a lone
#     percent is the final character in a format, it is ignored.
#
#   Note that the ls format applies to date within the past OR future 6
#   months!
#
#   The following formats are currently unused but may be used in the future:
#     goq FGJKLNOPQ 1234567890 !@#$^&*()_|-=\`[];',./~{}:<>?
#
#   This routine is loosely based on date.pl (version 3.2) by Terry McGonigal.

# $date=&ParseDate(\@args);
# $date=&ParseDate($string);
# $date=&ParseDate(\$string);
#   This takes an array (usually arguments to a program) and shifts a valid
#   date from it.  The date may be entered in a number of different formats.
#   It can be entered as one or several elements in the array, depending on
#   the format used.  When a part of the date is not given, defaults are
#   used:  year defaults to current year; hours, minutes, seconds to 00.
#   If a string is entered rather than an array, that string is tested for
#   a valid date.  The string is unmodified, even if passed in by reference.
#
#   The date may be split as two or more elements in the array.  The largest
#   possible set of elements from @args which can correctly be interpreted
#   as a valid date is used.
#
#   Valid formats are:
#     YYMMDD
#     YYMMDDHH:MN
#     YYMMDDHH:MN:SS
#     mm%dd
#     mm%dd%YY
#     mm%dd     hh:MN
#     mm%dd%YY  hh:MN
#     mm%dd     hh:MN:SS
#     mm%dd%YY  hh:MN:SS
#     hh:MN
#     hh:MN:SS
#     hh:MN     mm%dd
#     hh:MN:SS  mm%dd
#     hh:MN     mm%dd%YY
#     hh:MN:SS  mm%dd%YY
#     mmm  dd                  all spaces around mmm are optional
#     mmm  dd  hh:MN
#     mmm  dd  hh:MN:SS
#     mmm  dd  YY
#     mmm  dd  YY  hh:MN
#     mmm  dd  YY  hh:MN:SS
#     hh:MN     mmm  dd
#     hh:MN:SS  mmm  dd
#     hh:MN     mmm  dd  YY
#     hh:MN:SS  mmm  dd  YY
#     dd  mmm
#     dd  mmm  hh:MN
#     dd  mmm  hh:MN:SS
#     dd  mmm  YY
#     dd  mmm  YY  hh:MN
#     dd  mmm  YY  hh:MN:SS
#     hh:MN     dd  mmm
#     hh:MN:SS  dd  mmm
#     hh:MN     dd  mmm  YY
#     hh:MN:SS  dd  mmm  YY
#   In addition, the following strings are recognized:
#     today
#     now
#     yesterday (exactly 24 hours before now)
#     tomorrow  (exactly 24 hours from now)
#
#   %     One of the valid date separators: - / or whitespace (the same
#         character must be used for all occurences of a single date)
#   YY    year in 2 or 4 digit format
#   MM    two digit month (01 to 12)
#   mm    one or two digit month (1 to 12 or 01 to 12)
#   mmm   month name or 3 character abbreviation
#   DD    two digit day (01 to 31)
#   dd    one or two digit day (1 to 31 or 01 to 31)
#   HH    two digit hour in 24 hour mode (00 to 23)
#   hh    one or two digit hour in 24 hour mode (0 to 23 or 00 to 23)
#   MN    two digit minutes (00 to 59)
#   SS    two digit seconds (00 to 59)
#
#   When entered as a single element, the different parts of the date may
#   be separated by any number of whitespaces (but at least one) including
#   spaces and tabs.
#
#   The date returned is YYYYMMDDHH:MM:SS.  The advantage of this time
#   format is that two times can be compared using simple string
#   comparisons to find out which is later.
#
#   Dates are checked to make sure they are valid.
#
#   The elements containing a valid date are removed from the array!  If no
#   valid date is found, the array is unmodified and nothing returned.

# $delta=&ParseDateDelta(\@args)
# $delta=&ParseDateDelta($string)
# $delta=&ParseDateDelta(\$string)
#   This takes an array and shifts a valid delta date (an amount of time)
#   from the array.  Recognized deltas are of the form:
#     +Yy +Mm +Dd +Hh +MNmn +Ss
#     +Y:+M:+D:+H:+MN:+S
#   A field in the format +Yy is a sign, a number, and a string specifying
#   the type of field.  The sign is "+", "-", or absent (defaults to the
#   last sign given).  The valid strings specifying the field type
#   are:
#      y:  y, yr, year, years
#      m:  m, mon, month, months
#      d:  d, day, days
#      h:  h, hr, hour, hours
#      mn: mn, min, minute, minutes
#      s:  s, sec, second, seconds
#   Also, the "s" string may be omitted.  The sign, number, and string may
#   all be separated from each other by any number of whitespaces.
#
#   In the date, all fields must be given in the order: y m d h mn s.  Any
#   number of them may be omitted provided the rest remain in the correct
#   order.  In the 2nd (colon) format, from 2 to 6 of the fields may be
#   given.  For example +D:+H:+MN:+S may be given to specify only four of
#   the fields.  In any case, both the MN and S field may be present.  No
#   spaces may be present in the colon format.
#
#   Deltas may also be given as a combination of the two formats.  For
#   example, the following is valid: +Yy +D:+H:+MN:+S.  Again, all fields
#   must be given in the correct order.
#
#   The word in may be prepended to the delta ("in 5 years") and the word
#   ago may be appended ("6 months ago").  The "in" is completely ignored.
#   The "ago" has the affect of reversing all signs that appear in front
#   of the components of the delta.  I.e. "-12 yr 6 mon ago" is identical
#   to "+12yr +6mon" (don't forget that there is an impled minus sign
#   in front of the 6 because when no sign is explicitely given, it carries
#   the previously entered sign).

# $date=&Date_SetTime($date,$hr,$min,$sec)
# $date=&Date_SetTime($date,$time)
#   This takes a date sets the time in that date.  For example, to get
#   the time for 7:30 tomorrow, use the lines:
#      $date=&ParseDate("tomorrow")
#      $date=&Date_SetTime($date,"7:30")

# $date=&Date_GetPrev($date,$dow,$today,$hr,$min,$sec)
# $date=&Date_GetPrev($date,$dow,$today,$time)
#   This takes a date and returns the date of the previous $day.  For
#   example, if $day is "Fri", it returns the date of the previous Friday.
#   If $date is Friday, it will return either $date (if $today is non-zero)
#   or the Friday a week before (if $today is 0).  The time is also set
#   according to the optional $hr,$min,$sec.

# $date=&Date_GetNext($date,$dow,$today,$hr,$min,$sec)
# $date=&Date_GetNext($date,$dow,$today,$time)
#   Similar to Date_GetPrev.

########################################################################
########################################################################

sub Date_SetTime {
  my($date,$hr,$min,$sec)=@_;
  my(@date)=();
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
  return ""  if (! &IsInt($hr) || $hr<0 || $hr>23  or
                 ! &IsInt($min) || $min<0 || $min>59  or
                 ! &IsInt($sec) || $sec<0 || $sec>59);
  @date=(&UnixDate($date,"%m %d %Y"),"$hr:$min:$sec");
  $date=&ParseDate(\@date);
  return $date;
}

sub Date_GetPrev {
  my($date,$day,$today,$hr,$min,$sec)=@_;
  my($day_w)=();
  my($date_w)=&UnixDate($date,"%w");
  my(%days)=("sun",0,"mon",1,"tue",2,"wed",3,"thu",4,"fri",5,"sat",6);
  return ""  if (! exists $days{lc($day)});
  $day_w=$days{lc($day)};
  if ($day_w == $date_w) {
    if (! $today) {
      $date=&DateCalc($date,"7 days ago");
    }
  } else {
    $day_w -= 7  if ($day_w>$date_w); # make sure previous day is less
    $day = $date_w - $day_w;
    $date=&DateCalc($date,"$day days ago");
  }
  $date=&Date_SetTime($date,$hr,$min,$sec);
  return $date;
}

sub Date_GetNext {
  my($date,$day,$today,$hr,$min,$sec)=@_;
  my($day_w)=();
  my($date_w)=&UnixDate($date,"%w");
  my(%days)=("sun",0,"mon",1,"tue",2,"wed",3,"thu",4,"fri",5,"sat",6);
  return ""  if (! exists $days{lc($day)});
  $day_w=$days{lc($day)};
  if ($day_w == $date_w) {
    if (! $today) {
      $date=&DateCalc($date,"in 7 days");
    }
  } else {
    $date_w -= 7  if ($date_w>$day_w); # make sure next date is greater
    $day = $day_w - $date_w;
    $date=&DateCalc($date,"in $day days");
  }
  $date=&Date_SetTime($date,$hr,$min,$sec);
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
  my($yexp) ="(?: $exp1 (?:y|yr|year|yrs|years) \s* )?";
  my($mexp) ="(?: $exp1 (?:mon|month|months) \s* )?";
  my($dexp) ="(?: $exp1 (?:d|day|days) \s* )?";
  my($hexp) ="(?: $exp1 (?:h|hr|hrs|hour|hours) \s* )?";
  my($mnexp)="(?: $exp1 (?:mn|min|minute|minutes) \s* )?";
  my($sexp) ="(?: $exp1 (?:s|sec|second|seconds)? \s* )?";

  $delta="";
  PARSE: while (@a) {
    $_ = join(" ",@a);
    s/\s*$//;

    # I wanted $mexp to be "m|mon|month|months", but if the month is entered
    # it sometimes conflicts with minutes.  To fix this, switch a lone "m" to
    # "mon".
    s/([^a-zA-Z])m$/$1mon/i;
    s/([^a-zA-Z])m([^a-zA-Z])/$1mon$2/i;

    # in or ago
    s/^\s* in \s*//ix;
    $ago=1;
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
  my($format,%f,$out,@out,$c,@mon,@month,@w,@wk,@week,$date1,$date2)=();
  my($scalar)=();
  $date =~ /^(\d{2}(\d{2}))(\d{2})(\d{2})(\d{2}):(\d{2}):(\d{2})$/;
  ($f{"Y"},$f{"y"},$f{"m"},$f{"d"},$f{"H"},$f{"M"},$f{"S"})=
    ($1,$2,$3,$4,$5,$6,$7);
  my($m,$d,$y)=($f{"m"},$f{"d"},$f{"Y"});
  &Date_Init;
  @mon=split(/\|/,$DateManip::Date{"mon"});
  @month=split(/\|/,$DateManip::Date{"month"});
  @w=split(/\|/,$DateManip::Date{"w"});
  @wk=split(/\|/,$DateManip::Date{"wk"});
  @week=split(/\|/,$DateManip::Date{"week"});

  if (! wantarray) {
    $format=join(" ",@format);
    @format=($format);
    $scalar=1;
  }

  # month, week
  $_=$m;
  s/^0/ /;
  $f{"f"}=$_;
  $f{"b"}=$f{"h"}=$mon[$m-1];
  $f{"B"}=$month[$m-1];
  $f{"U"}=&Date_WeekOfYear($m,$d,$y,0);
  $f{"W"}=&Date_WeekOfYear($m,$d,$y,1);

  # day
  $f{"j"}=&Date_DayOfYear($m,$d,$y);
  $_=$d;
  s/^0/ /;
  $f{"e"}=$_;
  $f{"w"}=&Date_DayOfWeek($m,$d,$y);
  $f{"v"}=$w[$f{"w"}];
  $f{"a"}=$wk[$f{"w"}];
  $f{"A"}=$week[$f{"w"}];
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
  $f{"p"}="AM";
  $f{"p"}="PM"        if ($f{"k"}>11);

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
          $date1=&DateCalc("now","6 months ago");
          $date2=&DateCalc("now","in 6 months");
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
  my($y,$m,$d,$h,$mn,$s,$ampm,$i)=();

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

  &Date_Init;
  my($monexp)=$DateManip::Date{"monexp"};
  my($dateexp)=$DateManip::Date{"dateexp"};

  # Regular expressions for part of the date
  my($Yexp) ='(\d{2}|\d{4})'; # 2 or 4 digits (year)
  my($DDexp)='(\d{2})';       # 2 digits      (month/day/hour/minute/second)
  my($Dexp) ='(\d{1,2})';     # 1 or 2 digit  (month/day/hour)
  my($Time)="(?:$DDexp:$DDexp(?::$DDexp)?(?:\\s*(am|pm))?)"; # time in HH:MM:SS
  my($time)="(?:$Dexp:$DDexp(?::$DDexp)?(?:\\s*(am|pm))?)";  # time in hh:MM:SS
  my($sep)='([\/ -])';

  PARSE: while($#a>=0) {
    $_=join(" ",@a);
    s/\s+/ /g;

    if (/^$Yexp$DDexp$DDexp$Time?$/i) {
      # YYMMDD
      # YYMMDDHH:MN
      # YYMMDDHH:MN:SS
      ($y,$m,$d,$h,$mn,$s,$ampm)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$Dexp$sep$Dexp(?:\2$Yexp)?(?:\s+$time)?$/i) {
      # mm%dd
      # mm%dd%YY
      # mm%dd    hh:MN
      # mm%dd    hh:MN:SS
      # mm%dd%YY hh:MN
      # mm%dd%YY hh:MN:SS
      ($m,$d,$y,$h,$mn,$s,$ampm)=($1,$3,$4,$5,$6,$7,$8);

    } elsif (/^$time(?:\s+$Dexp$sep$Dexp(?:\6$Yexp)?)?$/) {
      # hh:MN
      # hh:MN:SS
      # hh:MN    mm%dd
      # hh:MN:SS mm%dd
      # hh:MN    mm%dd%YY
      # hh:MN:SS mm%dd%YY
      ($h,$mn,$s,$ampm,$m,$d,$y)=($1,$2,$3,$4,$5,$7,$8);

    } elsif (/^$monexp\s*$Dexp(?:\s+$Yexp)?(?:\s+$time)?$/i) {
      # mmm dd
      # mmm dd YY
      # mmm dd hh:MN
      # mmm dd hh:MN:SS
      # mmm dd YY hh:MN
      # mmm dd YY hh:MN:SS
      ($m,$d,$y,$h,$mn,$s,$ampm)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$time\s*$monexp\s*$Dexp(?:\s+$Yexp)?$/i) {
      # hh:MN    mmm dd
      # hh:MN:SS mmm dd
      # hh:MN    mmm dd YY
      # hh:MN:SS mmm dd YY
      ($h,$mn,$s,$ampm,$m,$d,$y)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$Dexp\s*$monexp\s*(?:$Yexp|$time)?$/i) {
      # dd mmm
      # dd mmm YY
      # dd mmm hh:MN
      # dd mmm hh:MN:SS
      ($d,$m,$y,$h,$mn,$s,$ampm)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$time\s+$Dexp\s*$monexp(?:$Yexp)?$/i) {
      # hh:MN    dd mmm
      # hh:MN:SS dd mmm
      # hh:MN    dd mmm YY
      # hh:MN:SS dd mmm YY
      ($h,$mn,$s,$ampm,$d,$m,$y)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$Dexp\s*$monexp\s*$Yexp\s+$time$/i) {
      # dd mmm YY hh:MN
      # dd mmm YY hh:MN:SS
      ($d,$m,$y,$h,$mn,$s,$ampm)=($1,$2,$3,$4,$5,$6,$7);

    } elsif (/^$dateexp$/i) {
      # today, now, yesterday, tomorrow
      if (/today/i || /now/i) {
        $date=$DateManip::Date{"now"};
        last PARSE;
      } elsif (/yesterday/i) {
        $date=&DateCalc("today","-1day");
        last PARSE;
      } elsif (/tomorrow/i) {
        $date=&DateCalc("today","+1day");
        last PARSE;
      }

    } else {
      pop(@a);
      next PARSE;
    }

    if (&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm)) {
      pop(@a);
    } else {
      last PARSE;
    }
  }

  if (@a) {
    splice(@args,0,$#a+1);
    @$args=@args  if (defined $ref  and  $ref eq "ARRAY");
    return $date  if (defined $date);
    return "$y$m$d$h:$mn:$s";
  }
  return "";
}

########################################################################
# SUBROUTINES
########################################################################

# $day=&Date_DayOfWeek($m,$d,$y);
#   Returns the day of the week (0 for Sunday, 6 for Saturday).
#   Dec 31, 0999 was Tuesday.
sub Date_DayOfWeek {
  my($m,$d,$y)=@_;
  my($dayofweek)=();

  $dayofweek=&Date_DaysSince999($m,$d,$y) % 7;
  return $dayofweek;
}

# $secs=&Date_SecsSince1970($m,$,$y,$h,$mn,$s)
#   Returns the number of days since Jan 1, 1970 (negative if date is
#   earlier).
sub Date_SecsSince1970 {
  my($m,$d,$y,$h,$mn,$s)=@_;
  my($sec_now,$sec_70)=();
  $sec_now=(&Date_DaysSince999($m,$d,$y)-1)*24*3600 + $h*3600 + $mn*60 + $s;
  $sec_70 =(&Date_DaysSince999(1,1,1970)-1)*24*3600;
  return ($sec_now-$sec_70);
}

# $days=&Date_DaysSince999($m,$d,$y)
#   Returns the number of days since Dec 31, 0999.
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

# $day=&Date_DayOfYear($m,$d,$y);
#   Returns the day of the year (001 to 366)
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

# $days=&Date_DaysInYear($y);
#   Returns the number of days in the year (365 or 366)
sub Date_DaysInYear {
  my($y)=@_;
  return 366  if (&Date_LeapYear($y));
  return 365;
}

# $wkno=&Date_WeekOfYear($m,$d,$y,$first);
#   Figure out week number.  $first is the first day of the
#   week which is usually 0 (Sunday) or 1 (Monday), but could
#   be any number between 0 and 6 in practice.
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

# $flag=&Date_LeapYear($y);
#   Returns 1 if the argument is a leap year
#   Written by David Muir Sharnoff <muir@idiom.com>
sub Date_LeapYear {
  my($y)=@_;
  return 0 unless $y % 4 == 0;
  return 1 unless $y % 100 == 0;
  return 0 unless $y % 400 == 0;
  return 1;
}

# $day=&Date_DaySuffix($d);
#    Add `st', `nd', `rd', `th' to a date (ie 1st, 22nd, 29th).
#    Written by David Muir Sharnoff <muir@idiom.com>.
sub Date_DaySuffix {
  my($d)=@_;
  return ($d.'st') if ($d =~ /1$/);
  return ($d.'nd') if ($d =~ /2$/);
  return ($d.'rd') if ($d =~ /3$/);
  return ($d.'th');
}

# &Date_Init
#   Initializes all the date functions, strings, and regular expressions.
sub Date_Init {
  if ($DateManip::Date{"init"}) {
    return();
  }
  $DateManip::Date{"init"}=1;

  # lists and regular expressions separated by "|" (for reg exp)
  $DateManip::Date{"mon"} =
    "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec";
  $DateManip::Date{"month"} =
    "January|February|March|April|May|June|".
    "July|August|September|October|November|December";
  $DateManip::Date{"monexp"} =
    "(".$DateManip::Date{"mon"} ."|". $DateManip::Date{"month"}.")";
  $DateManip::Date{"dateexp"} ="(now|today|yesterday|tomorrow)";
  $DateManip::Date{"w"}       =" S| M| T| W|Th| F|Sa";
  $DateManip::Date{"wk"}      ="Sun|Mon|Tue|Wed|Thu|Fri|Sat";
  $DateManip::Date{"week"} =
    "Sunday|Monday|Tuesday|Wednesday|Thursday|Fridat|Saturday";

  # current time
  my($s,$mn,$h,$d,$m,$y,$wday,$yday,$isdst)=localtime(time);
  my($ampm)=();
  $m++;
  &Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm);
  $DateManip::Date{"y"}=$y;
  $DateManip::Date{"m"}=$m;
  $DateManip::Date{"d"}=$d;
  $DateManip::Date{"h"}=$h;
  $DateManip::Date{"mn"}=$mn;
  $DateManip::Date{"s"}=$s;
  $DateManip::Date{"ampm"}=$ampm;
  $DateManip::Date{"now"}="$y$m$d$h:$mn:$s";
}

# $flag=&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm);
#   Returns 1 if any of the fields are bad.  All fields are optional, and
#   all possible checks are done on the data.  If a field is not passed in,
#   it is set to default values.  If data is missing, appropriate defaults
#   are supplied.
sub Date_ErrorCheck {
  my($y,$m,$d,$h,$mn,$s,$ampm)=@_;
  my($tmp1,$tmp2)=();

  my(@d_in_m)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
  my(@mon)=split(/\|/,$DateManip::Date{"mon"});
  my(@month)=split(/\|/,$DateManip::Date{"month"});
  my($curr_y)=$DateManip::Date{"y"};
  my($curr_m)=$DateManip::Date{"m"};
  my($curr_d)=$DateManip::Date{"d"};
  $$ampm=""  if (! defined $$ampm);
  $$ampm=uc($$ampm)  if ($$ampm);

  # Check year.
  $$y=$curr_y    if ($$y eq "");
  $$y="19$$y"    if (length($$y)==2);
  return 1       if (! &IsInt($$y)  or  $$y<1  or  $$y>9999);
  $d_in_m[2]=29  if (&Date_LeapYear($$y));

  # Check month
  $$m=$curr_m     if ($$m eq "");
  $tmp1=&SinLindex(\@mon,$$m,0,1)+1;
  $tmp2=&SinLindex(\@month,$$m,0,1)+1;
  $$m=$tmp1       if ($tmp1>0);
  $$m=$tmp2       if ($tmp2>0);
  $$m="0$$m"      if (length($$m)==1);
  return 1        if (! &IsInt($$m)  or  $$m<1  or  $$m>12);

  # Check day
  $$d=$curr_d     if ($$d eq "");
  $$d="0$$d"      if (length($$d)==1);
  return 1        if (! &IsInt($$d)  or  $$d<1  or  $$d>$d_in_m[$$m]);

  # Check hour
  if ($$ampm eq "AM" || $$ampm eq "PM") {
    $$h="0$$h"    if (length($$h)==1);
    return 1      if ($$h<1 || $$h>12);
    $$h="00"      if ($$ampm eq "AM"  and  $$h==12);
    $$h += 12     if ($$ampm eq "PM");
  } else {
    $$h="00"      if ($$h eq "");
    $$h="0$$h"    if (length($$h)==1);
    return 1      if (! &IsInt($$h)  or  $$h<0  or  $$h>23);
    $$ampm="AM"   if ($$h<12);
    $$ampm="PM"   if ($$h>=12);
  }

  # Check minutes
  $$mn="00"       if ($$mn eq "");
  $$mn="0$$mn"    if (length($$mn)==1);
  return 1        if (! &IsInt($$mn)  or  $$mn<0  or  $$mn>59);

  # Check seconds
  $$s="00"        if ($$s eq "");
  $$s="0$$s"      if (length($$s)==1);
  return 1        if (! &IsInt($$s)  or  $$s<0  or  $$s>59);

  return 0;
}

# This returns a timezone.  It looks in the following places for a
# timezone in the following order:
#    POSIX::tzname
#    $ENV{TZ}
#    $main::TZ
#    /etc/TIMEZONE
# else
#    GMT is returned
# Obviously, this does not guarantee the correct timezone.
sub Date_TimeZone {
  my($null,$tz)=();

  SWITCH: {

    $tz=POSIX::tzname();
    $tz=~ s/\s*//;
    last SWITCH  if (defined $tz  and  $tz);

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

sub IsInt {
  my($N)=shift;
  return 0 if ($N eq "");
  my($sign)='^\s* [-+]? \s*';
  my($int) ='\d+ \s* $ ';
  return 1 if ($N =~ /$sign $int/x);
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

