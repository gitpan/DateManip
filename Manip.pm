package Date::Manip;

# Copyright (c) 1995-1998 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###########################################################################
# CUSTOMIZATION
###########################################################################
#
# See the section of the POD documentation section CUSTOMIZING DATE::MANIP
# below for a complete description of each of these variables.

# Location of a the global config file.  Tilde (~) expansions are allowed.
$Date::Manip::GlobalCnf="";
$Date::Manip::IgnoreGlobalCnf="";

### Date::Manip variables set in the global config file

# Name of a personal config file and the path to search for it.  Tilde (~)
# expansions are allowed.
$Date::Manip::PersonalCnf=".DateManip.cnf";
$Date::Manip::PersonalCnfPath=".:~";

### Date::Manip variables set in the global or personal config file

# Which language to use when parsing dates.
$Date::Manip::Language="English";

# 12/10 = Dec 10 (US) or Oct 12 (anything else)
$Date::Manip::DateFormat="US";

# Local timezone
$Date::Manip::TZ="";

# Timezone to work in (""=local, "IGNORE", or a timezone)
$Date::Manip::ConvTZ="";

# Date::Manip internal format (0=YYYYMMDDHH:MN:SS, 1=YYYYHHMMDDHHMNSS)
$Date::Manip::Internal=0;

# First day of the week (1=monday, 7=sunday).  ISO 8601 says monday.
$Date::Manip::FirstDay=1;

# First and last day of the work week  (1=monday, 7=sunday)
$Date::Manip::WorkWeekBeg=1;
$Date::Manip::WorkWeekEnd=5;

# If non-nil, a work day is treated as 24 hours long (WorkDayBeg/WorkDayEnd
# ignored)
$Date::Manip::WorkDay24Hr=0;

# Start and end time of the work day (any time format allowed, seconds ignored)
$Date::Manip::WorkDayBeg="08:00";
$Date::Manip::WorkDayEnd="17:00";

# If "today" is a holiday, we look either to "tomorrow" or "yesterday" for
# the nearest business day.  By default, we'll always look "tomorrow" first.
$Date::Manip::TomorrowFirst=1;

# Erase the old holidays
$Date::Manip::EraseHolidays="";

# Set this to non-zero to be produce completely backwards compatible deltas
$Date::Manip::DeltaSigns=0;

# If this is 0, use the ISO 8601 standard that Jan 4 is in week 1.  If 1,
# make week 1 contain Jan 1.
$Date::Manip::Jan1Week1=0;

# 2 digit years fall into the 100 year period given by [ CURR-N, CURR+(99-N) ]
# where N is 0-99.  Default behavior is 89, but other useful numbers might
# be 0 (forced to be this year or later) and 99 (forced to be this year or
# earlier).  It can also be set to "c" (current century) or "cNN" (i.e.
# c18 forces the year to bet 1800-1899).
$Date::Manip::YYtoYYYY=89;

# Set this to 1 if you want a long-running script to always update the
# timezone.  This will slow Date::Manip down.  Read the POD documentation.
$Date::Manip::UpdateCurrTZ=0;

# Use an international character set.
$Date::Manip::IntCharSet=0;

# Use this to force the current date to be set to this:
$Date::Manip::ForceDate="";

###########################################################################

require 5.000;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
   DateManipVersion
   Date_Init
   ParseDateString
   ParseDate
   ParseRecur
   DateCalc
   ParseDateDelta
   UnixDate
   Delta_Format
   Date_GetPrev
   Date_GetNext
   Date_SetTime
   Date_SetDateField

   Date_DaysInMonth
   Date_DayOfWeek
   Date_SecsSince1970
   Date_SecsSince1970GMT
   Date_DaysSince999
   Date_DayOfYear
   Date_DaysInYear
   Date_WeekOfYear
   Date_LeapYear
   Date_DaySuffix
   Date_ConvTZ
   Date_TimeZone
   Date_IsWorkDay
   Date_NextWorkDay
   Date_PrevWorkDay
   Date_NearestWorkDay
   Date_NthDayOfYear
);
use strict;
use integer;
use Carp;
use Cwd;
use IO::File;

#use POSIX qw(tzname);

$Date::Manip::VERSION="5.31";

########################################################################
########################################################################
#
# Declare variables so we don't get any warnings about variables only
# being used once.  In Date_Init, I often define a whole batch of related
# variables knowing that I only have immediate use for some of them but
# I may need others in the future.  To avoid the "Identifier XXX used only
# once: possibly typo" warnings, all are declared here.
#
# Pacakge Variables
#

$Date::Manip::Am = undef;
$Date::Manip::AmExp = undef;
$Date::Manip::AmPmExp = undef;
$Date::Manip::Approx = undef;
$Date::Manip::At = undef;
$Date::Manip::Business = undef;
$Date::Manip::Curr = undef;
$Date::Manip::CurrAmPm = undef;
$Date::Manip::CurrD = undef;
$Date::Manip::CurrH = undef;
$Date::Manip::CurrHolidayYear = 0;
$Date::Manip::CurrM = undef;
$Date::Manip::CurrMn = undef;
$Date::Manip::CurrS = undef;
$Date::Manip::CurrY = undef;
$Date::Manip::CurrZoneExp = undef;
$Date::Manip::DExp = undef;
$Date::Manip::DayExp = undef;
$Date::Manip::EachExp = undef;
$Date::Manip::Exact = undef;
$Date::Manip::Future = undef;
$Date::Manip::HExp = undef;
$Date::Manip::Init = 0;
$Date::Manip::InitDone = 0;
$Date::Manip::InitFilesRead = 0;
$Date::Manip::LastExp = undef;
$Date::Manip::MExp = undef;
$Date::Manip::MnExp = undef;
$Date::Manip::Mode = undef;
$Date::Manip::MonExp = undef;
$Date::Manip::Next = undef;
$Date::Manip::Now = undef;
$Date::Manip::Of = undef
$Date::Manip::Offset = undef;
$Date::Manip::On = undef;
$Date::Manip::Past = undef;
$Date::Manip::Pm = undef;
$Date::Manip::PmExp = undef;
$Date::Manip::Prev = undef;
$Date::Manip::ResetWorkDay = 1;
$Date::Manip::SepHM = undef;
$Date::Manip::SepMS = undef;
$Date::Manip::SepSS = undef;
$Date::Manip::SExp = undef;
$Date::Manip::TimesExp = undef;
$Date::Manip::UpdateHolidays = 0;
$Date::Manip::WDBh = undef;
$Date::Manip::WDBm = undef;
$Date::Manip::WDEh = undef;
$Date::Manip::WDEm = undef;
$Date::Manip::WDlen = undef;
$Date::Manip::WExp = undef;
$Date::Manip::WhichExp = undef;
$Date::Manip::WkExp = undef;
$Date::Manip::YExp = undef;
$Date::Manip::ZoneExp = undef;

@Date::Manip::Day = ();
@Date::Manip::Mon = ();
@Date::Manip::Month = ();
@Date::Manip::W = ();
@Date::Manip::Week = ();
@Date::Manip::Wk = ();

%Date::Manip::AmPm = ();
%Date::Manip::CurrHolidays = ();
%Date::Manip::CurrZone = ();
%Date::Manip::Day = ();
%Date::Manip::Holidays = ();
%Date::Manip::Month = ();
%Date::Manip::Offset = ();
%Date::Manip::Times = ();
%Date::Manip::Replace = ();
%Date::Manip::Week = ();
%Date::Manip::Which = ();
%Date::Manip::Zone = ();

# For debugging purposes.
$Date::Manip::Debug="";
$Date::Manip::DebugVal="";

########################################################################
########################################################################
# THESE ARE THE MAIN ROUTINES
########################################################################
########################################################################

sub DateManipVersion {
  print "DEBUG: DateManipVersion\n"  if ($Date::Manip::Debug =~ /trace/);
  return $Date::Manip::VERSION;
}

sub Date_Init {
  print "DEBUG: Date_Init\n"  if ($Date::Manip::Debug =~ /trace/);
  $Date::Manip::Debug="";

  my($language,$format,$tz,$convtz,@args)=@_;
  $Date::Manip::InitDone=1;
  local($_)=();
  my($internal,$firstday)=();
  my($var,$val,$file)=();

  #### Backwards compatibility junk
  if (defined $language  and  $language) {
    if ($language=~ /=/) {
      push(@args,$language);
    } else {
      push(@args,"Language=$language");
    }
  }
  if (defined $format  and  $format) {
    if ($format=~ /=/) {
      push(@args,$format);
    } else {
      push(@args,"DateFormat=$format");
    }
  }
  if (defined $tz  and  $tz) {
    if ($tz=~ /=/) {
      push(@args,$tz);
    } else {
      push(@args,"TZ=$tz");
    }
  }
  if (defined $convtz  and  $convtz) {
    if ($convtz=~ /=/) {
      push(@args,$convtz);
    } else {
      push(@args,"ConvTZ=$convtz");
    }
  }
  #### End backwards compatibility junk

  $Date::Manip::EraseHolidays=0;
  foreach (@args) {
    s/\s*$//;
    s/^\s*//;
    /^(\S+) \s* = \s* (.+)$/x;
    ($var,$val)=($1,$2);
    $Date::Manip::InitFilesRead--,
    $Date::Manip::PersonalCnf=$val,      next  if ($var eq "PersonalCnf");
    $Date::Manip::PersonalCnfPath=$val,  next  if ($var eq "PersonalCnfPath");
  }

  $Date::Manip::InitFilesRead=1  if ($Date::Manip::IgnoreGlobalCnf);
  if ($Date::Manip::InitFilesRead<1) {
    $Date::Manip::InitFilesRead=1;
    # Read Global Init file
    if ($Date::Manip::GlobalCnf) {
      $file=&ExpandTilde($Date::Manip::GlobalCnf);
    }
    &Date_InitFile($file)  if (defined $file  and  $file  and  -r $file  and
                               -s $file  and  -f $file);
  }
  if ($Date::Manip::InitFilesRead<2) {
    $Date::Manip::InitFilesRead=2;
    # Read Personal Init file
    if ($Date::Manip::PersonalCnf  and  $Date::Manip::PersonalCnfPath) {
      $file=&SearchPath($Date::Manip::PersonalCnf,
                        $Date::Manip::PersonalCnfPath,"r");
    }
    &Date_InitFile($file)  if (defined $file  and  $file  and  -r $file  and
                               -s $file  and  -f $file);
  }

  foreach (@args) {
    s/\s*$//;
    s/^\s*//;
    /^(\S+) \s* = \s* (.+)$/x;
    ($var,$val)=($1,$2);

    &Date_SetConfigVariable($var,$val);
  }

  confess "ERROR: Unknown FirstDay in Date::Manip.\n"
    if (! &IsInt($Date::Manip::FirstDay,1,7));
  confess "ERROR: Unknown WorkWeekBeg in Date::Manip.\n"
    if (! &IsInt($Date::Manip::WorkWeekBeg,1,7));
  confess "ERROR: Unknown WorkWeekEnd in Date::Manip.\n"
    if (! &IsInt($Date::Manip::WorkWeekEnd,1,7));
  confess "ERROR: Invalid WorkWeek in Date::Manip.\n"
    if ($Date::Manip::WorkWeekEnd <= $Date::Manip::WorkWeekBeg);

  my(%lang,
     $tmp,@tmp,%tmp,@tmp2,
     $i,$j,@tmp3,
     $am,$pm,
     $zonesrfc,@zones)=();

  if (! $Date::Manip::Init) {
    $Date::Manip::Init=1;

    # Set the following variables based on the language.  They should all
    # be capitalized correctly, and any spaces appearing in the string
    # should be replaced with an underscore (_) (they will be correctly
    # parsed as spaces).

    #  $am,$pm  : different ways of expressing AM (PM), the first one in each
    #             list is the one that will be used when printing out an AM
    #             or PM string
    #
    # If a string contains spaces, replace the space(s) with underscores.

    if ($Date::Manip::Language eq "English") {
      &Date_Init_English(\%lang);

      $am="AM";
      $pm="PM";

    } elsif ($Date::Manip::Language eq "French") {
      &Date_Init_French(\%lang);

      $am="du_matin";  # le matin
      $pm="du_soir";   # le soir

    } elsif ($Date::Manip::Language eq "Swedish") {
      &Date_Init_Swedish(\%lang);

      $am="FM";
      $pm="EM";

    } elsif ($Date::Manip::Language eq "German") {
      &Date_Init_German(\%lang);

      $am="FM";
      $pm="EM";

    # } elsif ($Date::Manip::Language eq "Danish") {
    # } elsif ($Date::Manip::Language eq "Spanish") {
    # } elsif ($Date::Manip::Language eq "Italian") {
    # } elsif ($Date::Manip::Language eq "Portugese") {
    # } elsif ($Date::Manip::Language eq "Russian") {
    # } elsif ($Date::Manip::Language eq "Japanese") {

    } else {
      confess "ERROR: Unknown language in Date::Manip.\n";
    }

    # Date::Manip:: variables for months
    #   $MonExp   : "(jan|january|feb|february ... )"
    #   @Mon      : ("Jan","Feb",...)
    #   @Month    : ("January","February", ...)
    #   %Month    : ("january",1,"jan",1, ...)
    &Date_InitLists([$lang{"month_name"},$lang{"month_abb"}],
                    \$Date::Manip::MonExp,"lc,sort,back",
                    [\@Date::Manip::Month,\@Date::Manip::Mon],
                    [\%Date::Manip::Month,1]);

    # Date::Manip:: variables for day of week
    #   $WkExp  : "(mon|monday|tue|tuesday ... )"
    #   @W      : ("M","T",...)
    #   @Wk     : ("Mon","Tue",...)
    #   @Week   : ("Monday","Tudesday",...)
    #   %Week   : ("monday",1,"mon",1,"m",1,...)
    &Date_InitLists([$lang{"day_name"},$lang{"day_abb"}],
                    \$Date::Manip::WkExp,"lc,sort,back",
                    [\@Date::Manip::Week,\@Date::Manip::Wk],
                    [\%Date::Manip::Week,1]);
    &Date_InitLists([$lang{"day_char"}],
                    "","lc",
                    [\@Date::Manip::W],
                    [\%tmp,1]);
    %Date::Manip::Week=(%Date::Manip::Week,%tmp);

    # Date::Manip:: variables for day of week
    #   $DayExp   : "(1st|first|2nd|second ... )"
    #   %Day      : ("1st",1,"first",1, ... )"
    #   @Day      : ("1st","2nd",...);
    # Date::Manip:: variables for week of month
    #   $WhichExp : "(1st|first|2nd|second ... fifth|last)"
    #   %Which    : ("1st",1,"first",1, ... "fifth",5,"last",-1)"
    #   $LastExp  : "(last)"
    #   $EachExp  : "(each|every)"
    &Date_InitLists([$lang{"num_suff"},$lang{"num_word"}],
                    \$Date::Manip::DayExp,"lc,sort,back",
                    [\@Date::Manip::Day,\@tmp],
                    [\%Date::Manip::Day,1]);
    @tmp=@{ $lang{"last"} };
    &Date_InitStrings($lang{"last"},\$Date::Manip::LastExp,"lc,sort");
    @tmp2=();
    foreach $tmp (keys %Date::Manip::Day) {
      if ($Date::Manip::Day{$tmp}<6) {
        push(@tmp2,$tmp);
        $Date::Manip::Which{$tmp}=$Date::Manip::Day{$tmp};
      }
    }
    foreach $tmp (@tmp) {
      $Date::Manip::Which{$tmp}=-1;
    }
    push(@tmp2,@tmp);
    $Date::Manip::WhichExp="(" . join("|", sort sortByLength(@tmp2)) . ")";
    &Date_InitStrings($lang{"each"},\$Date::Manip::EachExp,"lc,sort");

    # Date::Manip:: variables for AM or PM
    #   $AmExp   : "(am)"
    #   $PmExp   : "(pm)"
    #   $AmPmExp : "(am|pm)"
    #   %AmPm    : (am,1,pm,2)
    #   $Am      : "AM"
    #   $Pm      : "PM"
    $Date::Manip::AmPmExp=&Date_Regexp("$am $pm","lc,back,under");
    ($Date::Manip::AmExp,@tmp2)=&Date_Regexp("$am","lc,back,under",1);
    ($Date::Manip::PmExp,@tmp3)=&Date_Regexp("$pm","lc,back,under",1);
    @tmp=map { $_,1 } @tmp2;
    push(@tmp,map { $_,2 } @tmp3);
    %Date::Manip::AmPm=@tmp;
    ($tmp,@tmp2)=&Date_Regexp("$am","under",1);
    ($tmp,@tmp3)=&Date_Regexp("$pm","under",1);
    $Date::Manip::Am=shift(@tmp2);
    $Date::Manip::Pm=shift(@tmp3);

    # Date::Manip:: variables for expressions used in parsing deltas
    #    $YExp   : "(?:y|yr|year|years)"
    #    $MExp   : similar for months
    #    $WExp   : similar for weeks
    #    $DExp   : similar for days
    #    $HExp   : similar for hours
    #    $MnExp  : similar for minutes
    #    $SExp   : similar for seconds
    #    %Replace: a list of replacements
    &Date_InitStrings($lang{"years"}  ,\$Date::Manip::YExp,"lc,sort");
    &Date_InitStrings($lang{"months"} ,\$Date::Manip::MExp,"lc,sort");
    &Date_InitStrings($lang{"weeks"}  ,\$Date::Manip::WExp,"lc,sort");
    &Date_InitStrings($lang{"days"}   ,\$Date::Manip::DExp,"lc,sort");
    &Date_InitStrings($lang{"hours"}  ,\$Date::Manip::HExp,"lc,sort");
    &Date_InitStrings($lang{"minutes"},\$Date::Manip::MnExp,"lc,sort");
    &Date_InitStrings($lang{"seconds"},\$Date::Manip::SExp,"lc,sort");
    &Date_InitHash($lang{"replace"},undef,"lc",\%Date::Manip::Replace);

    # Date::Manip:: variables for special dates that are offsets from now
    #    $Now      : "(now|today)"
    #    $Offset   : "(yesterday|tomorrow)"
    #    %Offset   : ("yesterday","-1:0:0:0",...)
    #    $TimesExp : "(noon|midnight)"
    #    %Times    : ("noon","12:00:00","midnight","00:00:00")
    &Date_InitHash($lang{"times"},\$Date::Manip::TimesExp,"lc,sort,back",
                   \%Date::Manip::Times);
    &Date_InitStrings($lang{"now"},\$Date::Manip::Now,"lc,sort");
    &Date_InitHash($lang{"offset"},\$Date::Manip::Offset,"lc,sort,back",
                   \%Date::Manip::Offset);
    $Date::Manip::SepHM=$lang{"sephm"};
    $Date::Manip::SepMS=$lang{"sepms"};
    $Date::Manip::SepSS=$lang{"sepss"};

    # Date::Manip:: variables for time zones
    #    $ZoneExp     : regular expression
    #    %Zone        : all parsable zones with their translation
    #    $Zone        : the current time zone
    #    $CurrZoneExp : "(us/eastern|us/central)"
    #    %CurrZone    : ("us/eastern","est7edt","us/central","cst6cdt")
    $zonesrfc=
      "idlw   -1200 ".  # International Date Line West
      "nt     -1100 ".  # Nome
      "hst    -1000 ".  # Hawaii Standard
      "cat    -1000 ".  # Central Alaska
      "ahst   -1000 ".  # Alaska-Hawaii Standard
      "yst    -0900 ".  # Yukon Standard
      "hdt    -0900 ".  # Hawaii Daylight
      "ydt    -0800 ".  # Yukon Daylight
      "pst    -0800 ".  # Pacific Standard
      "pdt    -0700 ".  # Pacific Daylight
      "mst    -0700 ".  # Mountain Standard
      "mdt    -0600 ".  # Mountain Daylight
      "cst    -0600 ".  # Central Standard
      "cdt    -0500 ".  # Central Daylight
      "est    -0500 ".  # Eastern Standard
      "edt    -0400 ".  # Eastern Daylight
      "ast    -0400 ".  # Atlantic Standard
      #"nst   -0330 ".  # Newfoundland Standard      nst=North Sumatra    +0630
      "nft    -0330 ".  # Newfoundland
      #"gst   -0300 ".  # Greenland Standard         gst=Guam Standard    +1000
      "bst    -0300 ".  # Brazil Standard            bst=British Summer   +0100
      "adt    -0300 ".  # Atlantic Daylight
      "ndt    -0230 ".  # Newfoundland Daylight
      "at     -0200 ".  # Azores
      "wat    -0100 ".  # West Africa
      "gmt    +0000 ".  # Greenwich Mean
      "ut     +0000 ".  # Universal (Coordinated)
      "utc    +0000 ".  # Universal (Coordinated)
      "wet    +0000 ".  # Western European
      "cet    +0100 ".  # Central European
      "fwt    +0100 ".  # French Winter
      "met    +0100 ".  # Middle European
      "mewt   +0100 ".  # Middle European Winter
      "swt    +0100 ".  # Swedish Winter
      #"bst   +0100 ".  # British Summer             bst=Brazil standard  -0300
      "eet    +0200 ".  # Eastern Europe, USSR Zone 1
      "cest   +0200 ".  # Central European Summer
      "fst    +0200 ".  # French Summer
      "mest   +0200 ".  # Middle European Summer
      "metdst +0200 ".  # An alias for mest used by HP-UX
      "sst    +0200 ".  # Swedish Summer             sst=South Sumatra    +0700
      "bt     +0300 ".  # Baghdad, USSR Zone 2
      "it     +0330 ".  # Iran
      "zp4    +0400 ".  # USSR Zone 3
      "zp5    +0500 ".  # USSR Zone 4
      "ist    +0530 ".  # Indian Standard
      "zp6    +0600 ".  # USSR Zone 5
      "nst    +0630 ".  # North Sumatra              nst=Newfoundland Std -0330
      #"sst   +0700 ".  # South Sumatra, USSR Zone 6 sst=Swedish Summer   +0200
      "jt     +0730 ".  # Java (3pm in Cronusland!)
      "cct    +0800 ".  # China Coast, USSR Zone 7
      "awst   +0800 ".  # West Australian Standard
      "wst    +0800 ".  # West Australian Standard
      "jst    +0900 ".  # Japan Standard, USSR Zone 8
      "rok    +0900 ".  # Republic of Korea
      "cast   +0930 ".  # Central Australian Standard
      "east   +1000 ".  # Eastern Australian Standard
      "gst    +1000 ".  # Guam Standard, USSR Zone 9 gst=Greenland Std    -0300
      "cadt   +1030 ".  # Central Australian Daylight
      "eadt   +1100 ".  # Eastern Australian Daylight
      "idle   +1200 ".  # International Date Line East
      "nzst   +1200 ".  # New Zealand Standard
      "nzt    +1200 ".  # New Zealand
      "nzdt   +1300 ".  # New Zealand Daylight
      "z +0000 ".
      "a -0100 b -0200 c -0300 d -0400 e -0500 f -0600 g -0700 h -0800 ".
      "i -0900 k -1000 l -1100 m -1200 ".
      "n +0100 o +0200 p +0300 q +0400 r +0500 s +0600 t +0700 u +0800 ".
      "v +0900 w +1000 x +1100 y +1200";
    ($Date::Manip::ZoneExp,%Date::Manip::Zone)=
      &Date_Regexp($zonesrfc,"sort,lc,under,back",
                   "keys");
    $tmp=
      "US/Pacific  PST8PDT ".
      "US/Mountain MST7MDT ".
      "US/Central  CST6CDT ".
      "US/Eastern  EST5EDT";
    ($Date::Manip::CurrZoneExp,%Date::Manip::CurrZone)=
      &Date_Regexp($tmp,"lc,under,back","keys");
    $Date::Manip::TZ=&Date_TimeZone;

    # Date::Manip:: misc. variables
    #    $At     : "(?:at)"
    #    $Of     : "(?:in|of)"
    #    $On     : "(?:on)"
    #    $Future : "(?:in)"
    #    $Past   : "(?:ago)"
    #    $Next   : "(?:next)"
    #    $Prev   : "(?:last|previous)"
    &Date_InitStrings($lang{"at"},\$Date::Manip::At,"lc,sort");
    &Date_InitStrings($lang{"on"},\$Date::Manip::On,"lc,sort");
    &Date_InitStrings($lang{"future"},\$Date::Manip::Future,"lc,sort");
    &Date_InitStrings($lang{"past"},\$Date::Manip::Past,"lc,sort");
    &Date_InitStrings($lang{"next"},\$Date::Manip::Next,"lc,sort");
    &Date_InitStrings($lang{"prev"},\$Date::Manip::Prev,"lc,sort");
    &Date_InitStrings($lang{"of"},\$Date::Manip::Of,"lc,sort");

    # Date::Manip:: calc mode variables
    #    $Approx  : "(?:approximately)"
    #    $Exact   : "(?:exactly)"
    #    $Business: "(?:business)"
    &Date_InitStrings($lang{"exact"},\$Date::Manip::Exact,"lc,sort");
    &Date_InitStrings($lang{"approx"},\$Date::Manip::Approx,"lc,sort");
    &Date_InitStrings($lang{"business"},\$Date::Manip::Business,"lc,sort");

    ############### END OF LANGUAGE INITIALIZATION
  }

  if ($Date::Manip::ResetWorkDay) {
    my($h1,$m1,$h2,$m2)=();
    if ($Date::Manip::WorkDay24Hr) {
      ($Date::Manip::WDBh,$Date::Manip::WDBm)=(0,0);
      ($Date::Manip::WDEh,$Date::Manip::WDEm)=(24,0);
      $Date::Manip::WDlen=24*60;
      $Date::Manip::WorkDayBeg="00:00";
      $Date::Manip::WorkDayEnd="23:59";

    } else {
      confess "ERROR: Invalid WorkDayBeg in Date::Manip.\n"
        if (! (($h1,$m1)=&CheckTime($Date::Manip::WorkDayBeg)));
      confess "ERROR: Invalid WorkDayEnd in Date::Manip.\n"
        if (! (($h2,$m2)=&CheckTime($Date::Manip::WorkDayEnd)));

      ($Date::Manip::WDBh,$Date::Manip::WDBm)=($h1,$m1);
      ($Date::Manip::WDEh,$Date::Manip::WDEm)=($h2,$m2);

      # Work day length = h1:m1  or  0:len (len minutes)
      $h1=$h2-$h1;
      $m1=$m2-$m1;
      if ($m1<0) {
        $h1--;
        $m1+=60;
      }
      $Date::Manip::WDlen=$h1*60+$m1;
    }
    $Date::Manip::ResetWorkDay=0;
  }

  # current time
  my($s,$mn,$h,$d,$m,$y,$wday,$yday,$isdst,$ampm,$wk)=();
  if ($Date::Manip::ForceDate=~
      /^(\d{4})-(\d{2})-(\d{2})-(\d{2}):(\d{2}):(\d{2})$/) {
       ($y,$m,$d,$h,$mn,$s)=($1,$2,$3,$4,$5,$6);
  } else {
    ($s,$mn,$h,$d,$m,$y,$wday,$yday,$isdst)=localtime(time);
    $y+=1900;
    $m++;
  }
  &Date_DateCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk);
  $Date::Manip::CurrY=$y;
  $Date::Manip::CurrM=$m;
  $Date::Manip::CurrD=$d;
  $Date::Manip::CurrH=$h;
  $Date::Manip::CurrMn=$mn;
  $Date::Manip::CurrS=$s;
  $Date::Manip::CurrAmPm=$ampm;
  $Date::Manip::Curr=&Date_Join($y,$m,$d,$h,$mn,$s);

  $Date::Manip::Debug=$Date::Manip::DebugVal;
}

sub ParseDateString {
  print "DEBUG: ParseDateString\n"  if ($Date::Manip::Debug =~ /trace/);
  local($_)=@_;
  my($y,$m,$d,$h,$mn,$s,$i,$which,$dofw,$wk,$tmp,$z,$num,$err,$iso,$ampm)=();
  my($date)=();

  # We only need to reinitialize if we have to determine what NOW is.
  &Date_Init()  if (! $Date::Manip::InitDone  or  $Date::Manip::UpdateCurrTZ);

  my($type)=$Date::Manip::DateFormat;

  # Mode is set in DateCalc.  ParseDate only overrides it if the string
  # contains a mode.
  if      ($Date::Manip::Exact and s/$Date::Manip::Exact//) {
    $Date::Manip::Mode=0;
  } elsif ($Date::Manip::Approx and s/$Date::Manip::Approx//) {
    $Date::Manip::Mode=1;
  } elsif ($Date::Manip::Business and s/$Date::Manip::Business//) {
    $Date::Manip::Mode=2;
  } elsif (! defined $Date::Manip::Mode) {
    $Date::Manip::Mode=0;
  }

  # Put parse in a simple loop for an easy exit.
 PARSE: {
    my(@tmp)=&Date_Split($_);
    if (@tmp) {
      ($y,$m,$d,$h,$mn,$s)=@tmp;
      last PARSE;
    }

    # Fundamental regular expressions

    my($mmm)=$Date::Manip::MonExp;          # (jan|january|...)
    my($wkexp)=$Date::Manip::WkExp;         # (mon|monday|...)
    my(%mmm)=%Date::Manip::Month;           # { jan=>1, ... }
    my(%dofw)=%Date::Manip::Week;           # { mon=>1, monday=>1, ... }
    my($whichexp)=$Date::Manip::WhichExp;   # (1st|...|fifth|last)
    my(%which)=%Date::Manip::Which;         # { 1st=>1,... fifth=>5,last=>-1 }
    my($daysexp)=$Date::Manip::DayExp;      # (1st|first|...31st)
    my(%dayshash)=%Date::Manip::Day;        # { 1st=>1, first=>1, ... }
    my($ampmexp)=$Date::Manip::AmPmExp;     # (am|pm)
    my($timeexp)=$Date::Manip::TimesExp;    # (noon|midnight)
    my($now)=$Date::Manip::Now;             # (now|today)
    my($offset)=$Date::Manip::Offset;       # (yesterday|tomorrow)
    my($zone)=$Date::Manip::ZoneExp.
      '(?:\s+|$)';                          # (edt|est|...)\s+
    my($day)='\s*'.$Date::Manip::DExp;      # \s*(?:d|day|days)
    my($month)='\s*'.$Date::Manip::MExp;    # \s*(?:mon|month|months)
    my($week)='\s*'.$Date::Manip::WExp;     # \s*(?:w|wk|week|weeks)
    my($next)='\s*'.$Date::Manip::Next;     # \s*(?:next)
    my($prev)='\s*'.$Date::Manip::Prev;     # \s*(?:last|previous)
    my($past)='\s*'.$Date::Manip::Past;     # \s*(?:ago)
    my($future)='\s*'.$Date::Manip::Future; # \s*(?:in)
    my($at)=$Date::Manip::At;               # (?:at)
    my($of)='\s*'.$Date::Manip::Of;         # \s*(?:in|of)
    my($on)='(?:\s*'.$Date::Manip::On.'\s*|\s+)';
                                            # \s*(?:on)\s*    or  \s+
    my($last)='\s*'.$Date::Manip::LastExp;  # \s*(?:last)
    my($hm)=$Date::Manip::SepHM;            # :
    my($ms)=$Date::Manip::SepMS;            # :
    my($ss)=$Date::Manip::SepSS;            # .

    # Other regular expressions

    my($D4)='(\d{4})';            # 4 digits      (yr)
    my($YY)='(\d{4}|\d{2})';      # 2 or 4 digits (yr)
    my($DD)='(\d{2})';            # 2 digits      (mon/day/hr/min/sec)
    my($D) ='(\d{1,2})';          # 1 or 2 digit  (mon/day/hr)
    my($FS)="(?:$ss\\d+)?";       # fractional secs
    my($sep)='[\/.-]';            # non-ISO8601 m/d/yy separators
    my($zone2)='\s*([+-](?:\d{4}|\d{2}:\d{2}|\d{2}))';  # absolute time zone

    # A regular expression for the time EXCEPT for the hour part

    my($mnsec)="$hm$DD(?:$ms$DD$FS)?(?:\\s*$ampmexp)?";
    my($time)="";

    $ampm="";
    $date="";

    # Substitute all special time expressions.
    if (/(^|[^a-z])$timeexp($|[^a-z])/i) {
      $tmp=$2;
      $tmp=$Date::Manip::Times{$tmp};
      s/(^|[^a-z])$timeexp($|[^a-z])/$1 $tmp $3/i;
    }

    # Remove some punctuation
    s/[,]/ /g;

    # Make sure that ...7EST works (i.e. a timezone immediately following
    # a digit.
    s/(\d)$zone(\s+|$|[0-9])/$1 $2$3/i;
    $zone = '\s+'.$zone;

    # Remove the time
    $iso=1;
    if (/$D$mnsec/i || /$ampmexp/i) {
      $iso=0;
      $tmp=0;
      $tmp=1  if (/$mnsec$zone2?\s*$/i);
      $tmp=0  if (/$ampmexp/i);
      if (s/(^|[^a-z])$at\s*$D$mnsec$zone/$1 /i  ||
          s/(^|[^a-z])$at\s*$D$mnsec$zone2?/$1 /i  ||
          s/(^|[^0-9])(\d)$mnsec$zone/$1 /i ||
          s/(^|[^0-9])(\d)$mnsec$zone2?/$1 /i ||
          (s/()$DD$mnsec$zone/ /i and (($iso=$tmp) || 1)) ||
          (s/()$DD$mnsec$zone2?/ /i and (($iso=$tmp) || 1))  ||
          s/(^|$at\s*|\s+)$D()()\s*$ampmexp$zone/ /i  ||
          s/(^|$at\s*|\s+)$D()()\s*$ampmexp$zone2?/ /i  ||
          0
         ) {
        ($h,$mn,$s,$ampm,$z)=($2,$3,$4,$5,$6);
        if (defined ($z)) {
          if ($z =~ /^[+-]\d{2}:\d{2}$/) {
            $z=~ s/://;
          } elsif ($z =~ /^[+-]\d{2}$/) {
            $z .= "00";
          }
        }
        $time=1;
        &Date_TimeCheck(\$h,\$mn,\$s,\$ampm);
        $y=$m=$d="";
        # We're going to be calling TimeCheck again below (when we check the
        # final date), so get rid of $ampm so that we don't have an error
        # due to "15:30:00 PM".  It'll get reset below.
        $ampm="";
        last PARSE  if (/^\s*$/);
      }
    }
    $time=0  if ($time ne "1");
    s/\s+$//;
    s/^\s+//;

    # Parse ISO 8601 dates now (which may still have a zone stuck to it).
    if ( ($iso && /^[0-9-]+(W[0-9-]+)?$zone?$/i)  ||
         ($iso && /^[0-9-]+(W[0-9-]+)?$zone2?$/i)  ||
         0) {
      # ISO 8601 dates
      s,-, ,g;            # Change all ISO8601 seps to spaces
      s/^\s+//;
      s/\s+$//;

      if (/^$D4\s*$DD\s*$DD\s*$DD(?:$DD(?:$DD\d*)?)?$zone2?$/  ||
          /^$D4\s*$DD\s*$DD\s*$DD(?:$DD(?:$DD\d*)?)?$zone?$/i  ||
          /^$DD\s+$DD\s*$DD\s*$DD(?:$DD(?:$DD\d*)?)?$zone2?$/  ||
          /^$DD\s+$DD\s*$DD\s*$DD(?:$DD(?:$DD\d*)?)?$zone?$/i  ||
          0
         ) {
        # ISO 8601 Dates with times
        #    YYYYMMDDHHMNSSFFFF
        #    YYYYMMDDHHMNSS
        #    YYYYMMDDHHMN
        #    YYYYMMDDHH
        #    YY MMDDHHMNSSFFFF
        #    YY MMDDHHMNSS
        #    YY MMDDHHMN
        #    YY MMDDHH
        ($y,$m,$d,$h,$mn,$s,$tmp)=($1,$2,$3,$4,$5,$6,$7);
        $z=""    if (! defined $h  ||  ! $h);
        return ""  if (defined $tmp  and  $tmp  and  $z);
        $z=$tmp  if (defined $tmp  and  $tmp);
        return ""  if ($time);
        last PARSE;

      } elsif (/^$D4(?:\s*$DD(?:\s*$DD)?)?$/  ||
               /^$DD(?:\s+$DD(?:\s*$DD)?)?$/) {
        # ISO 8601 Dates
        #    YYYYMMDD
        #    YYYYMM
        #    YYYY
        #    YY MMDD
        #    YY MM
        #    YY
        ($y,$m,$d)=($1,$2,$3);
        last PARSE;

      } elsif (/^$YY\s+$D\s+$D/) {
        # YY-M-D
        ($y,$m,$d)=($1,$2,$3);
        last PARSE;

      } elsif (/^$YY\s*W$DD\s*(\d)?$/i) {
        # YY-W##-D
        ($y,$which,$dofw)=($1,$2,$3);
        ($y,$m,$d)=&Date_NthWeekOfYear($y,$which,$dofw);
        last PARSE;

      } elsif (/^$D4\s*(\d{3})$/ ||
               /^$DD\s*(\d{3})$/) {
        # YYDOY
        ($y,$which)=($1,$2);
        ($y,$m,$d)=&Date_NthDayOfYear($y,$which);
        last PARSE;

      } else {
        return "";
      }
    }

    # Check for some special types of dates (next, prev)
    if (/$whichexp/i  ||  /$future/i  ||  /$past/i  ||  /$next/i  ||
        /$prev/i  ||  /^$wkexp$/i  ||  /$week/i) {
      $tmp=0;

      if (/^$whichexp\s*$wkexp$of\s*$mmm\s*$YY?$/i) {
        # last friday in October 95
        ($which,$dofw,$m,$y)=($1,$2,$3,$4);
        # fix $m, $y
        return ""  if (&Date_DateCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
        $dofw=$dofw{lc($dofw)};
        $which=$which{lc($which)};
        # Get the first day of the month
        $date=&Date_Join($y,$m,1,$h,$mn,$s);
        if ($which==-1) {
          $date=&DateCalc_DateDelta($date,"+0:1:0:0:0:0:0",\$err,0);
          $date=&Date_GetPrev($date,$dofw,0);
        } else {
          for ($i=0; $i<$which; $i++) {
            if ($i==0) {
              $date=&Date_GetNext($date,$dofw,1);
            } else {
              $date=&Date_GetNext($date,$dofw,0);
            }
          }
        }
        last PARSE;

      } elsif (/^$last$day$of\s*$mmm(?:$of?\s*$YY)?/i) {
        # last day in month
        ($m,$y)=($1,$2);
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $y=&Date_FixYear($y)  if (length($y)<4);
        $m=$mmm{lc($m)};
        $d=&Date_DaysInMonth($m,$y);
        last PARSE;

      } elsif (/^$next?\s*$wkexp$/i) {
        # next friday
        # friday
        ($dofw)=($1);
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&Date_GetNext($Date::Manip::Curr,$dofw,0,$h,$mn,$s);
        last PARSE;

      } elsif (/^$prev\s*$wkexp$/i) {
        # last friday
        ($dofw)=($1);
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&Date_GetPrev($Date::Manip::Curr,$dofw,0,$h,$mn,$s);
        last PARSE;

      } elsif (/^$next$week$/i) {
        # next week
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,"+0:0:1:0:0:0:0",\$err,0);
        $date=&Date_SetTime($date,$h,$mn,$s)  if (defined $h);
        last PARSE;
      } elsif (/^$prev$week$/i) {
        # last week
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,"-0:0:1:0:0:0:0",\$err,0);
        $date=&Date_SetTime($date,$h,$mn,$s)  if (defined $h);
        last PARSE;

      } elsif (/^$next$month$/i) {
        # next month
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,"+0:1:0:0:0:0:0",\$err,0);
        $date=&Date_SetTime($date,$h,$mn,$s)  if (defined $h);
        last PARSE;
      } elsif (/^$prev$month$/i) {
        # last month
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,"-0:1:0:0:0:0:0",\$err,0);
        $date=&Date_SetTime($date,$h,$mn,$s)  if (defined $h);
        last PARSE;

      } elsif (/^$future\s*(\d+)$week$/i) {
        # in 2 weeks
        ($num)=($1);
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,"+0:0:$num:0:0:0:0",
                                  \$err,0);
        $date=&Date_SetTime($date,$h,$mn,$s)  if (defined $h);
        last PARSE;
      } elsif (/^(\d+)$week$past$/i) {
        # 2 weeks ago
        ($num)=($1);
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,"-0:0:$num:0:0:0:0",
                                 \$err,0);
        $date=&Date_SetTime($date,$h,$mn,$s)  if (defined $h);
        last PARSE;

      } elsif (/^$future\s*(\d+)$month$/i) {
        # in 2 months
        ($num)=($1);
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,"+0:$num:0:0:0:0:0",
                                  \$err,0);
        $date=&Date_SetTime($date,$h,$mn,$s)  if (defined $h);
        last PARSE;
      } elsif (/^(\d+)$month$past$/i) {
        # 2 months ago
        ($num)=($1);
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,"-0:$num:0:0:0:0:0",
                                  \$err,0);
        $date=&Date_SetTime($date,$h,$mn,$s)  if (defined $h);
        last PARSE;

      } elsif (/^$wkexp$future\s*(\d+)$week$/i) {
        # friday in 2 weeks
        ($dofw,$num)=($1,$2);
        $tmp="+";
      } elsif (/^$wkexp\s*(\d+)$week$past$/i) {
        # friday 2 weeks ago
        ($dofw,$num)=($1,$2);
        $tmp="-";
      } elsif (/^$future\s*(\d+)$week$on$wkexp$/i) {
        # in 2 weeks on friday
        ($num,$dofw)=($1,$2);
        $tmp="+"
      } elsif (/^(\d+)$week$past$on$wkexp$/i) {
        # 2 weeks ago on friday
        ($num,$dofw)=($1,$2);
        $tmp="-";
      } elsif (/^$wkexp\s*$week$/i) {
        # monday week    (British date: in 1 week on monday)
        $dofw=$1;
        $num=1;
        $tmp="+";
      } elsif (/^$now\s*$week$/i) {
        # today week     (British date: 1 week from today)
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,"+0:0:1:0:0:0:0",\$err,0);
        $date=&Date_SetTime($date,$h,$mn,$s)  if (defined $h);
        last PARSE;
      } elsif (/^$offset\s*$week$/i) {
        # tomorrow week  (British date: 1 week from tomorrow)
        ($offset)=($1);
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $offset=$Date::Manip::Offset{lc($offset)};
        $date=&DateCalc_DateDelta($Date::Manip::Curr,$offset,\$err,0);
        $date=&DateCalc_DateDelta($date,"+0:0:1:0:0:0:0",\$err,0);
        if ($time) {
          return ""
            if (&Date_DateCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
          $date=&Date_SetTime($date,$h,$mn,$s);
        }
        last PARSE;
      }

      if ($tmp) {
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=&DateCalc_DateDelta($Date::Manip::Curr,
                                  $tmp . "0:0:$num:0:0:0:0",\$err,0);
        $date=&Date_GetPrev($date,$Date::Manip::FirstDay,1);
        $date=&Date_GetNext($date,$dofw,1,$h,$mn,$s);
        last PARSE;
      }
    }

    # Change 2nd, second to 2
    $tmp=0;
    if (/(^|[^a-z])$daysexp($|[^a-z])/i) {
      if (/^\s*$daysexp\s*$/) {
        ($d)=($1);
        $d=$dayshash{lc($d)};
        $m=$Date::Manip::CurrM;
        last PARSE;
      }
      $tmp=lc($2);
      $tmp=$dayshash{"$tmp"};
      s/(^|[^a-z])$daysexp($|[^a-z])/$1 $tmp $3/i;
      s/^\s+//;
      s/\s+$//;
    }

    # Another set of special dates (Nth week)
    if (/^$D\s*$wkexp(?:$of?\s*$YY)?$/i) {
      # 22nd sunday in 1996
      ($which,$dofw,$y)=($1,$2,$3);
      ($y,$m,$d)=&Date_NthWeekOfYear($y,$which,$dofw);
      last PARSE;
    } elsif (/^$wkexp$week\s*$D(?:$of?\s*$YY)?$/i  ||
             /^$wkexp\s*$D$week(?:$of?\s*$YY)?$/i) {
      # sunday week 22 in 1996
      # sunday 22nd week in 1996
      ($dofw,$which,$y)=($1,$2,$3);
      ($y,$m,$d)=&Date_NthWeekOfYear($y,$which,$dofw);
      last PARSE;
    }

    # Get rid of day of week
    if (/(^|[^a-z])$wkexp($|[^a-z])/i) {
      $wk=$2;
      (s/(^|[^a-z])$wkexp,/$1 /i) ||
        s/(^|[^a-z])$wkexp($|[^a-z])/$1 $3/i;
      s/^\s+//;
      s/\s+$//;
    }

    {
      # Non-ISO8601 dates
      s,\s*$sep\s*, ,g;     # change all non-ISO8601 seps to spaces
      s,^\s*,,;             # remove leading/trailing space
      s,\s*$,,;

      if (/^$D\s+$D(?:\s+$YY)?$/) {
        # MM DD YY (DD MM YY non-US)
        ($m,$d,$y)=($1,$2,$3);
        ($m,$d)=($d,$m)  if ($type ne "US");
        last PARSE;

      } elsif (/^$D4\s*$D\s*$D$/) {
        # YYYY MM DD
        ($y,$m,$d)=($1,$2,$3);
        last PARSE;

      } elsif (s/(^|[^a-z])$mmm($|[^a-z])/$1 $3/i) {
        ($m)=($2);

        if (/^\s*$D(?:\s*$YY)?\s*$/) {
          # mmm DD YY
          # DD mmm YY
          # DD YY mmm
          ($d,$y)=($1,$2);
          last PARSE;

        } elsif (/^\s*$D4\s+$D\s*$/) {
          # mmm YYYY DD
          # YYYY mmm DD
          # YYYY DD mmm
          ($y,$d)=($1,$2);
          last PARSE;

        } else {
          return "";
        }

      } elsif (/^epoch\s*(\d+)$/) {
        $s=$1;
        $date=&DateCalc("Jan 1 1970 00:00 GMT",$s);

      } elsif (/^$now$/i) {
        # now, today
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=$Date::Manip::Curr;
        if ($time) {
          return ""
            if (&Date_DateCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
          $date=&Date_SetTime($date,$h,$mn,$s);
        }
        last PARSE;

      } elsif (/^$offset$/i) {
        # yesterday, tomorrow
        ($offset)=($1);
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $offset=$Date::Manip::Offset{lc($offset)};
        $date=&DateCalc_DateDelta($Date::Manip::Curr,$offset,\$err,0);
        if ($time) {
          return ""
            if (&Date_DateCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
          $date=&Date_SetTime($date,$h,$mn,$s);
        }
        last PARSE;

      } else {
        return "";
      }
    }
  }

  if (! $date) {
    return ""  if (&Date_DateCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
    $date=&Date_Join($y,$m,$d,$h,$mn,$s);
  }
  $date=&Date_ConvTZ($date,$z);
  return $date;
}

sub ParseDate {
  print "DEBUG: ParseDate\n"  if ($Date::Manip::Debug =~ /trace/);
  &Date_Init()  if (! $Date::Manip::InitDone);
  my($args,@args,@a,$ref,$date)=();
  @a=@_;

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
    return $args  if (&Date_Split($args));
    @args=($args);
  } elsif ($ref eq "ARRAY") {
    @args=@$args;
  } elsif ($ref eq "SCALAR") {
    return $$args  if (&Date_Split($$args));
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

 PARSE: while($#a>=0) {
    $date=join(" ",@a);
    $date=&ParseDateString($date);
    last  if ($date);
    pop(@a);
  } # PARSE

  $date;
}

# **NOTE**
# The calc routines all call parse routines, so it is never necessary to
# call Date_Init in the calc routines.
sub DateCalc {
  print "DEBUG: DateCalc\n"  if ($Date::Manip::Debug =~ /trace/);
  my($D1,$D2,@arg)=@_;
  my($ref,$err,$errref,$mode)=();

  $errref=shift(@arg);
  $ref=0;
  if (defined $errref) {
    if (ref $errref) {
      $mode=shift(@arg);
      $ref=1;
    } else {
      $mode=$errref;
      $errref="";
    }
  }

  my(@date,@delta,$ret,$tmp)=();

  if (defined $mode  and  $mode>=0  and  $mode<=2) {
    $Date::Manip::Mode=$mode;
  } else {
    $Date::Manip::Mode=0;
  }

  if ($tmp=&ParseDateString($D1)) {
    push(@date,$tmp);
  } elsif ($tmp=&ParseDateDelta($D1)) {
    push(@delta,$tmp);
  } else {
    $$errref=1  if ($ref);
    return;
  }

  if ($tmp=&ParseDateString($D2)) {
    push(@date,$tmp);
  } elsif ($tmp=&ParseDateDelta($D2)) {
    push(@delta,$tmp);
  } else {
    $$errref=2  if ($ref);
    return;
  }
  $mode=$Date::Manip::Mode;

  if ($#date==1) {
    $ret=&DateCalc_DateDate(@date,$mode);
  } elsif ($#date==0) {
    $ret=&DateCalc_DateDelta(@date,@delta,\$err,$mode);
    $$errref=$err  if ($ref);
  } else {
    $ret=&DateCalc_DeltaDelta(@delta,$mode);
  }
  $ret;
}

sub ParseDateDelta {
  print "DEBUG: ParseDateDelta\n"  if ($Date::Manip::Debug =~ /trace/);
  my($args,@args,@a,$ref)=();
  local($_)=();
  @a=@_;

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

  my(@colon,@delta,$delta,$dir,$colon,$sign,$val)=();
  my($from,$to)=();
  my($workweek)=$Date::Manip::WorkWeekEnd-$Date::Manip::WorkWeekBeg+1;

  &Date_Init()  if (! $Date::Manip::InitDone);
  my($signexp)='([+-]?)';
  my($numexp)='(\d+)';
  my($exp1)="(?: \\s* $signexp \\s* $numexp \\s*)";
  my($yexp,$mexp,$wexp,$dexp,$hexp,$mnexp,$sexp,$i)=();
  $yexp=$mexp=$wexp=$dexp=$hexp=$mnexp=$sexp="()()";
  $yexp ="(?: $exp1 $Date::Manip::YExp)?";
  $mexp ="(?: $exp1 $Date::Manip::MExp)?";
  $wexp ="(?: $exp1 $Date::Manip::WExp)?";
  $dexp ="(?: $exp1 $Date::Manip::DExp)?";
  $hexp ="(?: $exp1 $Date::Manip::HExp)?";
  $mnexp="(?: $exp1 $Date::Manip::MnExp)?";
  $sexp ="(?: $exp1 $Date::Manip::SExp?)?";
  my($future)=$Date::Manip::Future;
  my($past)=$Date::Manip::Past;

  $delta="";
  PARSE: while (@a) {
    $_ = join(" ",@a);
    s/\s*$//;

    # Mode is set in DateCalc.  ParseDateDelta only overrides it if the
    # string contains a mode.
    if      (s/$Date::Manip::Exact//) {
      $Date::Manip::Mode=0;
    } elsif (s/$Date::Manip::Approx//) {
      $Date::Manip::Mode=1;
    } elsif (s/$Date::Manip::Business//) {
      $Date::Manip::Mode=2;
    } elsif (! defined $Date::Manip::Mode) {
      $Date::Manip::Mode=0;
    }
    $workweek=7  if ($Date::Manip::Mode != 2);

    foreach $from (keys %Date::Manip::Replace) {
      $to=$Date::Manip::Replace{$from};
      s/(^|[^a-z])$from($|[^a-z])/$1$to$2/i;
    }

    # in or ago
    s/(^|[^a-z])$future($|[^a-z])/$1 $2/i;
    $dir=1;
    $dir=-1  if (s/(^|[^a-z])$past($|[^a-z])/$1 $2/i);
    s/\s*$//;

    # the colon part of the delta
    $colon="";
    if (s/($signexp?$numexp?(:($signexp?$numexp)?){1,6})$//) {
      $colon=$1;
      s/\s*$//;
    }
    @colon=split(/:/,$colon);

    # the non-colon part of the delta
    $sign="+";
    @delta=();
    $i=6;
    foreach $exp1 ($yexp,$mexp,$wexp,$dexp,$hexp,$mnexp,$sexp) {
      last  if ($#colon>=$i--);
      $val=0;
      s/^$exp1//ix;
      $val=$2  if (defined $2  &&  $2);
      $sign=$1  if (defined $1  &&  $1);
      push(@delta,"$sign$val");
    }
    if (! /^\s*$/) {
      pop(@a);
      next PARSE;
    }

    # make sure that the colon part has a sign
    for ($i=0; $i<=$#colon; $i++) {
      $val=0;
      $colon[$i] =~ /^$signexp$numexp?/;
      $val=$2  if (defined $2  &&  $2);
      $sign=$1  if (defined  $1 &&  $1);
      $colon[$i] = "$sign$val";
    }

    # combine the two
    push(@delta,@colon);
    if ($dir<0) {
      for ($i=0; $i<=$#delta; $i++) {
        $delta[$i] =~ tr/-+/+-/;
      }
    }

    # form the delta and shift off the valid part
    $delta=join(":",@delta);
    splice(@args,0,$#a+1);
    @$args=@args  if (defined $ref  and  $ref eq "ARRAY");
    last PARSE;
  }

  $delta=&Delta_Normalize($delta,$Date::Manip::Mode);
  return $delta;
}

sub UnixDate {
  print "DEBUG: UnixDate\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,@format)=@_;
  local($_)=();
  my($format,%f,$out,@out,$c,$date1,$date2,$tmp)=();
  my($scalar)=();
  $date=&ParseDateString($date);
  return  if (! $date);

  my($y,$m,$d,$h,$mn,$s)=($f{"Y"},$f{"m"},$f{"d"},$f{"H"},$f{"M"},$f{"S"})=
    &Date_Split($date);
  $f{"y"}=substr $f{"Y"},2;
  &Date_Init()  if (! $Date::Manip::InitDone);

  if (! wantarray) {
    $format=join(" ",@format);
    @format=($format);
    $scalar=1;
  }

  # month, week
  $_=$m;
  s/^0//;
  $f{"b"}=$f{"h"}=$Date::Manip::Mon[$_-1];
  $f{"B"}=$Date::Manip::Month[$_-1];
  $_=$m;
  s/^0/ /;
  $f{"f"}=$_;
  $f{"U"}=&Date_WeekOfYear($m,$d,$y,7);
  $f{"W"}=&Date_WeekOfYear($m,$d,$y,1);

  # check week 52,53 and 0
  $f{"G"}=$f{"L"}=$y;
  if ($f{"W"}>=52 || $f{"U"}>=52) {
    my($dd,$mm,$yy)=($d,$m,$y);
    $dd+=7;
    if ($dd>31) {
      $dd-=31;
      $mm=1;
      $yy++;
      if (&Date_WeekOfYear($mm,$dd,$yy,1)==2) {
        $f{"G"}=$yy;
        $f{"W"}=1;
      }
      if (&Date_WeekOfYear($mm,$dd,$yy,7)==2) {
        $f{"L"}=$yy;
        $f{"W"}=1;
      }
    }
  }
  if ($f{"W"}==0) {
    my($dd,$mm,$yy)=($d,$m,$y);
    $dd-=7;
    $dd+=31  if ($dd<1);
    $yy--;
    $mm=12;
    $f{"G"}=$yy;
    $f{"W"}=&Date_WeekOfYear($mm,$dd,$yy,1)+1;
  }
  if ($f{"U"}==0) {
    my($dd,$mm,$yy)=($d,$m,$y);
    $dd-=7;
    $dd+=31  if ($dd<1);
    $yy--;
    $mm=12;
    $f{"L"}=$yy;
    $f{"U"}=&Date_WeekOfYear($mm,$dd,$yy,7)+1;
  }

  $f{"U"}="0".$f{"U"}  if (length $f{"U"} < 2);
  $f{"W"}="0".$f{"W"}  if (length $f{"W"} < 2);

  # day
  $f{"j"}=&Date_DayOfYear($m,$d,$y);
  $f{"j"} = "0" . $f{"j"}   while (length($f{"j"})<3);
  $_=$d;
  s/^0/ /;
  $f{"e"}=$_;
  $f{"w"}=&Date_DayOfWeek($m,$d,$y);
  $f{"v"}=$Date::Manip::W[$f{"w"}-1];
  $f{"v"}=" ".$f{"v"}  if (length $f{"v"} < 2);
  $f{"a"}=$Date::Manip::Wk[$f{"w"}-1];
  $f{"A"}=$Date::Manip::Week[$f{"w"}-1];
  $f{"E"}=&Date_DaySuffix($f{"e"});

  # hour
  $_=$h;
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
  $f{"o"}=&Date_SecsSince1970($m,$d,$y,$h,$mn,$s);
  $f{"s"}=&Date_SecsSince1970GMT($m,$d,$y,$h,$mn,$s);
  $f{"z"}=$f{"Z"}=
    ($Date::Manip::ConvTZ eq "IGNORE" or $Date::Manip::ConvTZ eq "" ?
     $Date::Manip::TZ : $Date::Manip::ConvTZ);

  # date, time
  $f{"c"}=qq|$f{"a"} $f{"b"} $f{"e"} $h:$mn:$s $y|;
  $f{"C"}=$f{"u"}=
    qq|$f{"a"} $f{"b"} $f{"e"} $h:$mn:$s $f{"z"} $y|;
  $f{"g"}=qq|$f{"a"}, $d $f{"b"} $y $h:$mn:$s $f{"z"}|;
  $f{"D"}=$f{"x"}=qq|$m/$d/$f{"y"}|;
  $f{"r"}=qq|$f{"I"}:$mn:$s $f{"p"}|;
  $f{"R"}=qq|$h:$mn|;
  $f{"T"}=$f{"X"}=qq|$h:$mn:$s|;
  $f{"V"}=qq|$m$d$h$mn$f{"y"}|;
  $f{"Q"}="$y$m$d";
  $f{"q"}=qq|$y$m$d$h$mn$s|;
  $f{"P"}=qq|$y$m$d$h:$mn:$s|;
  $f{"F"}=qq|$f{"A"}, $f{"B"} $f{"e"}, $f{"Y"}|;
  if ($f{"W"}==0) {
    $y--;
    $tmp=&Date_WeekOfYear(12,31,$y,1);
    $tmp="0$tmp"  if (length($tmp) < 2);
    $f{"J"}=qq|$y-W$tmp-$f{"w"}|;
  } else {
    $f{"J"}=qq|$f{"G"}-W$f{"W"}-$f{"w"}|;
  }
  $f{"K"}=qq|$y-$f{"j"}|;
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
    while ($format ne "") {
      $c=chop($format);
      if ($c eq "%") {
        $c=chop($format);
        if ($c eq "l") {
          &Date_Init();
          $date1=&DateCalc_DateDelta($Date::Manip::Curr,"-0:6:0:0:0:0:0");
          $date2=&DateCalc_DateDelta($Date::Manip::Curr,"+0:6:0:0:0:0:0");
          if ($date gt $date1  and  $date lt $date2) {
            $f{"l"}=qq|$f{"b"} $f{"e"} $h:$mn|;
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

# Can't be in "use integer" because we're doing decimal arithmatic
no integer;
sub Delta_Format {
  print "DEBUG: Delta_Format\n"  if ($Date::Manip::Debug =~ /trace/);
  my($delta,$dec,@format)=@_;
  $delta=&ParseDateDelta($delta);
  return ""  if (! $delta);
  my(@out,%f,$out,$c1,$c2,$scalar,$format)=();
  local($_)=$delta;
  my($y,$M,$w,$d,$h,$m,$s)=&Delta_Split($delta);
  # Get rid of positive signs.
  ($y,$M,$w,$d,$h,$m,$s)=map { 1*$_; }($y,$M,$w,$d,$h,$m,$s);

  if (defined $dec  &&  $dec>0) {
    $dec="%." . ($dec*1) . "f";
  } else {
    $dec="%f";
  }

  if (! wantarray) {
    $format=join(" ",@format);
    @format=($format);
    $scalar=1;
  }

  # Length of each unit in seconds
  my($sl,$ml,$hl,$dl,$wl)=();
  $sl = 1;
  $ml = $sl*60;
  $hl = $ml*60;
  $dl = $hl*24;
  $wl = $dl*7;

  # The decimal amount of each unit contained in all smaller units
  my($sd,$md,$hd,$dd,$wd)=();
  $wd = ($d*$dl + $h*$hl + $m*$ml + $s*$sl)/$wl;
  $dd =          ($h*$hl + $m*$ml + $s*$sl)/$dl;
  $hd =                   ($m*$ml + $s*$sl)/$hl;
  $md =                            ($s*$sl)/$ml;
  $sd = 0;

  # The amount of each unit contained in higher units.
  my($sh,$mh,$hh,$dh,$wh)=();
  $wh = 0;
  $dh = ($wh+$w)*7;
  $hh = ($dh+$d)*24;
  $mh = ($hh+$h)*60;
  $sh = ($mh+$m)*60;

  # Set up the formats

  $f{"wv"} = $w;
  $f{"dv"} = $d;
  $f{"hv"} = $h;
  $f{"mv"} = $m;
  $f{"sv"} = $s;

  $f{"wh"} = $w+$wh;
  $f{"dh"} = $d+$dh;
  $f{"hh"} = $h+$hh;
  $f{"mh"} = $m+$mh;
  $f{"sh"} = $s+$sh;

  $f{"wd"} = sprintf($dec,$w+$wd);
  $f{"dd"} = sprintf($dec,$d+$dd);
  $f{"hd"} = sprintf($dec,$h+$hd);
  $f{"md"} = sprintf($dec,$m+$md);
  $f{"sd"} = sprintf($dec,$s+$sd);

  $f{"wt"} = sprintf($dec,$wh+$w+$wd);
  $f{"dt"} = sprintf($dec,$dh+$d+$dd);
  $f{"ht"} = sprintf($dec,$hh+$h+$hd);
  $f{"mt"} = sprintf($dec,$mh+$m+$md);
  $f{"st"} = sprintf($dec,$sh+$s+$sd);

  $f{"%"}  = "%";

  foreach $format (@format) {
    $format=reverse($format);
    $out="";
  PARSE: while ($format) {
      $c1=chop($format);
      if ($c1 eq "%") {
        $c1=chop($format);
        if (exists($f{$c1})) {
          $out .= $f{$c1};
          next PARSE;
        }
        $c2=chop($format);
        if (exists($f{"$c1$c2"})) {
          $out .= $f{"$c1$c2"};
          next PARSE;
        }
        $out .= $c1;
        $format .= $c2;
      } else {
        $out .= $c1;
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
use integer;

# Known flags:
#   ----- any number of the following may be chosen executed in the order given
#   PDn   means the previous day n (n=1-7) not counting today
#   PTn   means the previous day n (n=1-7) counting today
#   PWD   previous work day not counting today
#   PWT   previous work day counting today
#
#   NDn   similar to PDn but next day
#   NTn   similar to PTn but next day
#   NWD   next work day not counting today
#   NWT   next work day counting today
#
#   CWN   closest work day (counting tomorrow first)
#   CWP   closest work day (counting yesterday first)
#   CWD   closest work day (using TommorowFirst variable)
#   ----- any number of the following may be added
#   MDx   If you set a day-of-month to 31, but the month has only 30 days,
#         there are two possibilities:  discard this date, or set the day
#         as 30.  MDK will keep them (setting the date to 30).  MDD discards.
#         Default is MDD.
#   MWn   This defines what the first week of a month is.  n can be any
#         day of the week (1-7).  The first week of the month is the week
#         that contains this day.  1 (Mon) the first full work week, 3 (Wed)
#         the first week with the majority of work days, 4 (Thu) the first
#         week with a majority of days, 5 (Fri) the first week with any
#         workdays, 7 (Sun) the first week with any days.  Default is MW7.
#         Note that weeks can be numbered 1-6.
#   BUS   Use business mode for all calculations.

sub ParseRecur {
  print "DEBUG: ParseRecur\n"  if ($Date::Manip::Debug =~ /trace/);
  &Date_Init()  if (! $Date::Manip::InitDone);

  my($recur,$dateb,$date0,$date1,$flag)=@_;
  local($_)=$recur;
  my($date_b,$date_0,$date_1,$flag_t,$recur_0,$recur_1,@recur0,@recur1)=();
  my(@tmp,$tmp,$each,$mode,$num,$y,$m,$d,$w,$h,$mn,$s,$delta,$y0,$y1,$yb)=();
  my($yy,$n,$dd,@d,@tmp2,$date,@date,@w,@tmp2,@tmp3,@m,@y)=();

  $date0=""  if (! defined $date0);
  $date1=""  if (! defined $date1);
  $dateb=""  if (! defined $dateb);
  $flag =""  if (! defined $flag);

  if ($dateb) {
    $dateb=&ParseDateString($dateb);
    return ""  if (! $dateb);
  }
  if ($date0) {
    $date0=&ParseDateString($date0);
    return ""  if (! $date0);
  }
  if ($date1) {
    $date1=&ParseDateString($date1);
    return ""  if (! $date1);
  }

  # Flags
  my($FDn) = 7;

  my($R1) = '([0-9:]+)';
  my($R2) = '(?:\*([-,0-9:]*))';
  my($F)  = '(?:\*([^*]*))';

  if (/^$R1?$R2?$F?$F?$F?$F?$/) {
    ($recur_0,$recur_1,$flag_t,$date_b,$date_0,$date_1)=($1,$2,$3,$4,$5,$6);
    $recur_0 = ""  if (! defined $recur_0);
    $recur_1 = ""  if (! defined $recur_1);
    $flag_t  = ""  if (! defined $flag_t);
    $date_b  = ""  if (! defined $date_b);
    $date_0  = ""  if (! defined $date_0);
    $date_1  = ""  if (! defined $date_1);

    @recur0 = split(/:/,$recur_0);
    @recur1 = split(/:/,$recur_1);
    return ""  if ($#recur0 + $#recur1 + 2 != 7);

    if ($date_b) {
      $date_b=&ParseDateString($date_b);
      return ""  if (! $date_b);
    }
    if ($date_0) {
      $date_0=&ParseDateString($date_0);
      return ""  if (! $date_0);
    }
    if ($date_1) {
      $date_1=&ParseDateString($date_1);
      return ""  if (! $date_1);
    }

  } else {

    my($mmm)='\s*'.$Date::Manip::MonExp;    # \s*(jan|january|...)
    my(%mmm)=%Date::Manip::Month;           # { jan=>1, ... }
    my($wkexp)='\s*'.$Date::Manip::WkExp;   # \s*(mon|monday|...)
    my(%week)=%Date::Manip::Week;           # { monday=>1, ... }
    my($day)='\s*'.$Date::Manip::DExp;      # \s*(?:d|day|days)
    my($month)='\s*'.$Date::Manip::MExp;    # \s*(?:mon|month|months)
    my($week)='\s*'.$Date::Manip::WExp;     # \s*(?:w|wk|week|weeks)
    my($daysexp)=$Date::Manip::DayExp;      # (1st|first|...31st)
    my(%dayshash)=%Date::Manip::Day;        # { 1st=>1, first=>1, ... }
    my($of)='\s*'.$Date::Manip::Of;         # \s*(?:in|of)
    my($lastexp)=$Date::Manip::LastExp;     # (?:last)
    my($each)=$Date::Manip::EachExp;        # (?:each|every)

    my($D)='\s*(\d+)';
    my($Y)='\s*(\d{4}|\d{2})';

    # Change 1st to 1
    if (/(^|[^a-z])$daysexp($|[^a-z])/i) {
      $tmp=lc($2);
      $tmp=$dayshash{"$tmp"};
      s/(^|[^a-z])$daysexp($|[^a-z])/$1 $tmp $3/i;
    }
    s/\s*$//;

    # Get rid of "each"
    if (/(^|[^a-z])$each($|[^a-z])/i) {
      s/(^|[^a-z])$each($|[^a-z])/ /i;
      $each=1;
    } else {
      $each=0;
    }

    # Find out if it's business mode.
    $mode=0;
#   $mode=2  if (s/$Date::Manip::Business//);

    if ($each) {

      if (/^$D?$day(?:$of$mmm?$Y)?$/i ||
          /^$D?$day(?:$of$mmm())?$/i) {
        # every [2nd] day in [june] 1997
        # every [2nd] day [in june]
        ($num,$m,$y)=($1,$2,$3);
        $num=1 if (! defined $num);
        $m=""  if (! defined $m);
        $y=""  if (! defined $y);

        $y=$Date::Manip::CurrY  if (! $y);
        if ($m) {
          $m=$mmm{lc($m)};
          $date_0=&Date_Join($y,$m,1,0,0,0);
          $date_1=&DateCalc_DateDelta($date_0,"+0:1:0:0:0:0:0",$mode);
        } else {
          $date_0=&Date_Join($y,1,1,0,0,0);
          $date_1=&Date_Join($y+1,1,1,0,0,0);
        }
        $date_b=$date_0;
        @recur0=(0,0,0,$num,0,0,0);
        @recur1=();

      } elsif (/^$D$day?$of$month(?:$of?$Y)?$/) {
        # 2nd [day] of every month [in 1997]
        ($num,$y)=($1,$2);
        $y=$Date::Manip::CurrY  if (! defined $y  or  ! $y);

        $date_0=&Date_Join($y,1,1,0,0,0);
        $date_1=&Date_Join($y+1,1,1,0,0,0);
        $date_b=$date_0;

        @recur0=(0,1,0);
        @recur1=($num,0,0,0);

      } elsif (/^$D$wkexp$of$month(?:$of?$Y)?$/ ||
               /^($lastexp)$wkexp$of$month(?:$of?$Y)?$/) {
        # 2nd tuesday of every month [in 1997]
        # last tuesday of every month [in 1997]
        ($num,$d,$y)=($1,$2,$3);
        $y=$Date::Manip::CurrY  if (! defined $y  or  ! $y);
        $d=$week{lc($d)};
        $num=-1  if ($num !~ /^$D$/);

        $date_0=&Date_Join($y,1,1,0,0,0);
        $date_1=&Date_Join($y+1,1,1,0,0,0);
        $date_b=$date_0;

        @recur0=(0,1);
        @recur1=($num,$d,0,0,0);

      } elsif (/^$D$wkexp(?:$of$mmm?$Y)?$/i ||
               /^$D$wkexp(?:$of$mmm())?$/i) {
        # every 2nd tuesday in june 1997
        ($num,$d,$m,$y)=($1,$2,$3,$4);
        $y=$Date::Manip::CurrY  if (! defined $y  or  ! $y);
        $num=1 if (! defined $num);
        $m=""  if (! defined $m);
        $d=$week{lc($d)};

        if ($m) {
          $m=$mmm{lc($m)};
          $date_0=&Date_Join($y,$m,1,0,0,0);
          $date_1=&DateCalc_DateDelta($date_0,"+0:1:0:0:0:0:0",$mode);
        } else {
          $date_0=&Date_Join($y,1,1,0,0,0);
          $date_1=&Date_Join($y+1,1,1,0,0,0);
        }
        $date_b=$date_0;

        @recur0=(0,0,$num);
        @recur1=($d,0,0,0);

      } else {
        return "";
      }
    } else {
      return "";
    }
  }

  $date0=$date_0  if (! $date0);
  $date1=$date_1  if (! $date1);
  $dateb=$date_b  if (! $dateb);
  $flag =$flag_t  if (! $flag);

  if (! wantarray) {
    $tmp  = join(":",@recur0);
    $tmp .= "*" . join(":",@recur1)  if (@recur1);
    $tmp .= "*$flag*$dateb*$date0*$date1";
    return $tmp;
  }
  if (@recur0) {
    return ()  if (! $date0  ||  ! $date1); # dateb is NOT required in all case
  }
  ($y,$m,$w,$d,$h,$mn,$s)=(@recur0,@recur1);

  @y=@m=@w=@d=();

  if ($#recur0==-1) {
    # * Y-M-W-D-H-MN-S
    if ($y eq "0") {
      push(@recur0,0);

    } else {
      @y=&ReturnList($y);
      foreach $y (@y) {
        $y=&FixYear($y)  if (length($y)==2);
        return ()  if (length($y)!=4  ||  ! &IsInt($y));
      }
      @y=sort { $a<=>$b } @y;

      $date0=&ParseDate("1000-01-01");
      $date1=&ParseDate("9999-12-31 23:59:59");

      if ($m eq "0"  and  $w eq "0") {
        # * Y-0-0-0-H-MN-S
        # * Y-0-0-DOY-H-MN-S
        if ($d eq "0") {
          @d=(1);
        } else {
          @d=&ReturnList($d);
          return ()  if (! @d);
          foreach $d (@d) {
            return ()  if (! &IsInt($d,1,366));
          }
          @d=sort { $a<=>$b } (@d);
        }

        @tmp=();
        foreach $yy (@y) {
          foreach $d (@d) {
            ($y,$m,$dd)=&Date_NthDayOfYear($yy,$d);
            push(@tmp, &Date_Join($y,$m,$dd,0,0,0));
          }
        }
        @date=&Date_RecurSetTime($date0,$date1,\@tmp,$h,$mn,$s);

      } elsif ($w eq "0") {
        # * Y-M-0-0-H-MN-S
        # * Y-M-0-DOM-H-MN-S

        @m=&ReturnList($m);
        return ()  if (! @m);
        foreach $m (@m) {
          return ()  if (! &IsInt($m,1,12));
        }
        @m=sort { $a<=>$b } (@m);

        if ($d eq "0") {
          @d=(1);
        } else {
          @d=&ReturnList($d);
          return ()  if (! @d);
          foreach $d (@d) {
            return ()  if (! &IsInt($d,1,31));
          }
          @d=sort { $a<=>$b } (@d);
        }

        @tmp=();
        foreach $y (@y) {
          foreach $m (@m) {
            foreach $d (@d) {
              $date=&Date_Join($y,$m,$d,0,0,0);
              push(@tmp,$date)  if ($d<29 || &Date_Split($date));
            }
          }
        }
        @date=&Date_RecurSetTime($date0,$date1,\@tmp,$h,$mn,$s);

      } elsif ($m eq "0") {
        # * Y-0-WOY-DOW-H-MN-S
        # * Y-0-WOY-0-H-MN-S
        @w=&ReturnList($w);
        return ()  if (! @w);
        foreach $w (@w) {
          return ()  if (! &IsInt($w,1,53));
        }

        if ($d eq "0") {
          @d=($Date::Manip::FirstDay);
        } else {
          @d=&ReturnList($d);
          return ()  if (! @d);
          foreach $d (@d) {
            return ()  if (! &IsInt($d,1,7));
          }
          @d=sort { $a<=>$b } (@d);
        }

        @tmp=();
        foreach $y (@y) {
          foreach $w (@w) {
            $w="0$w"  if (length($w)==1);
            foreach $d (@d) {
              $date=&ParseDateString("$y-W$w-$d");
              push(@tmp,$date);
            }
          }
        }
        @date=&Date_RecurSetTime($date0,$date1,\@tmp,$h,$mn,$s);

      } else {
        # * Y-M-WOM-DOW-H-MN-S
        # * Y-M-WOM-0-H-MN-S

        @m=&ReturnList($m);
        return ()  if (! @m);
        foreach $m (@m) {
          return ()  if (! &IsInt($m,1,12));
        }
        @m=sort { $a<=>$b } (@m);

        @w=&ReturnList($w);

        if ($d eq "0") {
          @d=();
        } else {
          @d=&ReturnList($d);
        }

        @tmp=@tmp2=();
        foreach $y (@y) {
          foreach $m (@m) {
            push(@tmp,$y);
            push(@tmp2,$m);
          }
        }
        @y=@tmp;
        @m=@tmp2;

        @date=&Date_Recur_WoM(\@y,\@m,\@w,\@d,$FDn);
        @date=&Date_RecurSetTime($date0,$date1,\@date,$h,$mn,$s);
      }
    }
  }

  if ($#recur0==0) {
    # Y * M-W-D-H-MN-S
    $n=$y;
    $n=1  if ($n==0);

    @m=&ReturnList($m);
    return ()  if (! @m);
    foreach $m (@m) {
      return ()  if (! &IsInt($m,1,12));
    }
    @m=sort { $a<=>$b } (@m);

    if ($m eq "0") {
      # Y * 0-W-D-H-MN-S   (equiv to Y-0 * W-D-H-MN-S)
      push(@recur0,0);

    } elsif ($w eq "0") {
      # Y * M-0-DOM-H-MN-S
      $d=1  if ($d eq "0");

      @d=&ReturnList($d);
      return ()  if (! @d);
      foreach $d (@d) {
        return ()  if (! &IsInt($d,1,31));
      }
      @d=sort { $a<=>$b } (@d);

      # We need to find years that are a multiple of $n from $y(base)
      ($y0)=( &Date_Split($date0) )[0];
      ($y1)=( &Date_Split($date1) )[0];
      ($yb)=( &Date_Split($dateb) )[0];
      @tmp=();
      for ($yy=$y0; $yy<=$y1; $yy++) {
        if (($yy-$yb)%$n == 0) {
          foreach $m (@m) {
            foreach $d (@d) {
              $date=&Date_Join($yy,$m,$d,0,0,0);
              push(@tmp,$date)  if ($d<29 || &Date_Split($date));
            }
          }
        }
      }
      @date=&Date_RecurSetTime($date0,$date1,\@tmp,$h,$mn,$s);

    } else {
      # Y * M-WOM-DOW-H-MN-S
      # Y * M-WOM-0-H-MN-S
      @m=&ReturnList($m);
      @w=&ReturnList($w);
      if ($d eq "0") {
        @d=();
      } else {
        @d=&ReturnList($d);
      }

      ($y0)=( &Date_Split($date0) )[0];
      ($y1)=( &Date_Split($date1) )[0];
      ($yb)=( &Date_Split($dateb) )[0];
      @y=();
      for ($yy=$y0; $yy<=$y1; $yy++) {
        if (($yy-$yb)%$n == 0) {
          push(@y,$yy);
        }
      }

      @date=&Date_Recur_WoM(\@y,\@m,\@w,\@d,$FDn);
      @date=&Date_RecurSetTime($date0,$date1,\@date,$h,$mn,$s);
    }
  }

  if ($#recur0==1) {
    # Y-M * W-D-H-MN-S

    if ($w eq "0") {
      # Y-M * 0-D-H-MN-S   (equiv to Y-M-0 * D-H-MN-S)
      push(@recur0,0);

    } elsif ($m==0) {
      # Y-0 * WOY-0-H-MN-S
      # Y-0 * WOY-DOW-H-MN-S
      $n=$y;
      $n=1  if ($n==0);

      @w=&ReturnList($w);
      return ()  if (! @w);
      foreach $w (@w) {
        return ()  if (! &IsInt($w,1,53));
      }

      if ($d eq "0") {
        @d=($Date::Manip::FirstDay);
      } else {
        @d=&ReturnList($d);
        return ()  if (! @d);
        foreach $d (@d) {
          return ()  if (! &IsInt($d,1,7));
        }
        @d=sort { $a<=>$b } (@d);
      }

      # We need to find years that are a multiple of $n from $y(base)
      ($y0)=( &Date_Split($date0) )[0];
      ($y1)=( &Date_Split($date1) )[0];
      ($yb)=( &Date_Split($dateb) )[0];
      @tmp=();
      for ($yy=$y0; $yy<=$y1; $yy++) {
        if (($yy-$yb)%$n == 0) {
          foreach $w (@w) {
            $w="0$w"  if (length($w)==1);
            foreach $tmp (@d) {
              $date=&ParseDateString("$yy-W$w-$tmp");
              push(@tmp,$date);
            }
          }
        }
      }
      @date=&Date_RecurSetTime($date0,$date1,\@tmp,$h,$mn,$s);

    } else {
      # Y-M * WOM-0-H-MN-S
      # Y-M * WOM-DOW-H-MN-S
      @tmp=(@recur0);
      push(@tmp,0)  while ($#tmp<6);
      $delta=join(":",@tmp);
      return ()  if (! $dateb);
      @tmp=&Date_Recur($date0,$date1,$dateb,$delta);

      @w=&ReturnList($w);
      @m=();
      if ($d eq "0") {
        @d=();
      } else {
        @d=&ReturnList($d);
      }

      @date=&Date_Recur_WoM(\@tmp,\@m,\@w,\@d,$FDn);
      @date=&Date_RecurSetTime($date0,$date1,\@date,$h,$mn,$s);
    }
  }

  if ($#recur0==2) {
    # Y-M-W * D-H-MN-S

    if ($d eq "0") {
      # Y-M-W * 0-H-MN-S
      $y=1  if ($y==0 && $m==0 && $w==0);
      $delta="$y:$m:$w:0:0:0:0";
      return ()  if (! $dateb);
      @tmp=&Date_Recur($date0,$date1,$dateb,$delta);
      @date=&Date_RecurSetTime($date0,$date1,\@tmp,$h,$mn,$s);

    } elsif ($m==0 && $w==0) {
      # Y-0-0 * DOY-H-MN-S
      $y=1  if ($y==0);
      $n=$y;
      return ()  if (! $dateb  &&  $y!=1);

      @d=&ReturnList($d);
      return ()  if (! @d);
      foreach $d (@d) {
        return ()  if (! &IsInt($d,1,366));
      }
      @d=sort { $a<=>$b } (@d);

      # We need to find years that are a multiple of $n from $y(base)
      ($y0)=( &Date_Split($date0) )[0];
      ($y1)=( &Date_Split($date1) )[0];
      ($yb)=( &Date_Split($dateb) )[0];
      @tmp=();
      for ($yy=$y0; $yy<=$y1; $yy++) {
        if (($yy-$yb)%$n == 0) {
          foreach $d (@d) {
            ($y,$m,$dd)=&Date_NthDayOfYear($yy,$d);
            push(@tmp, &Date_Join($y,$m,$dd,0,0,0));
          }
        }
      }
      @date=&Date_RecurSetTime($date0,$date1,\@tmp,$h,$mn,$s);

    } elsif ($w>0) {
      # Y-M-W * DOW-H-MN-S
      @tmp=(@recur0);
      push(@tmp,0)  while ($#tmp<6);
      $delta=join(":",@tmp);
      return ()  if (! $dateb);

      @d=&ReturnList($d);
      return ()  if (! @d);
      foreach $d (@d) {
        return ()  if (! &IsInt($d,1,7));
      }

      # Find out what DofW the basedate is.
      @tmp2=&Date_Split($dateb);
      $tmp=&Date_DayOfWeek($tmp2[1],$tmp2[2],$tmp2[0]);

      @tmp=();
      foreach $d (@d) {
        $date_b=$dateb;
        # Move basedate to DOW
        if ($d != $tmp) {
          if (($tmp>=$Date::Manip::FirstDay && $d<$Date::Manip::FirstDay) ||
              ($tmp>=$Date::Manip::FirstDay && $d>$tmp) ||
              ($tmp<$d && $d<$Date::Manip::FirstDay)) {
            $date_b=&Date_GetNext($date_b,$d);
          } else {
            $date_b=&Date_GetPrev($date_b,$d);
          }
        }
        push(@tmp,&Date_Recur($date0,$date1,$date_b,$delta));
      }
      @tmp=sort(@tmp);
      @date=&Date_RecurSetTime($date0,$date1,\@tmp,$h,$mn,$s);

    } elsif ($m>0) {
      # Y-M-0 * DOM-H-MN-S
      @tmp=(@recur0);
      push(@tmp,0)  while ($#tmp<6);
      $delta=join(":",@tmp);
      return ()  if (! $dateb);

      @d=&ReturnList($d);
      return ()  if (! @d);
      foreach $d (@d) {
        return ()  if (! &IsInt($d,1,31));
      }
      @d=sort { $a<=>$b } (@d);

      @tmp2=&Date_Recur($date0,$date1,$dateb,$delta);
      @tmp=();
      foreach $date (@tmp2) {
        ($y,$m)=( &Date_Split($date) )[0..1];
        foreach $d (@d) {
          $tmp=&Date_Join($y,$m,$d,0,0,0);
          push(@tmp,$tmp)  if ($d<29  ||  &Date_Split($tmp));
        }
      }
      @date=&Date_RecurSetTime($date0,$date1,\@tmp,$h,$mn,$s);

    } else {
      return ();
    }
  }

  if ($#recur0>2) {
    # Y-M-W-D * H-MN-S
    # Y-M-W-D-H * MN-S
    # Y-M-W-D-H-MN * S
    # Y-M-W-D-H-S
    @tmp=(@recur0);
    push(@tmp,0)  while ($#tmp<6);
    $delta=join(":",@tmp);
    return ()  if ($delta !~ /[1-9]/);    # return if "0:0:0:0:0:0:0"
    return ()  if (! $dateb);
    @date=&Date_Recur($date0,$date1,$dateb,$delta);
    if (@recur1) {
      unshift(@recur1,-1)  while ($#recur1<2);
      @date=&Date_RecurSetTime($date0,$date1,\@date,@recur1);
    } else {
      shift(@date);
      pop(@date);
    }
  }

  @date;
}

sub Date_GetPrev {
  print "DEBUG: Date_GetPrev\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$dow,$today,$hr,$min,$sec)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  my($y,$m,$d,$h,$mn,$s,$err,$curr_dow,%dow,$num,$delta,$th,$tm,$ts)=();

  if (! &Date_Split($date)) {
    $date=&ParseDateString($date);
    return ""  if (! $date);
  }
  ($y,$m,$d)=( &Date_Split($date) )[0..2];

  if (defined $dow and $dow ne "") {
    $curr_dow=&Date_DayOfWeek($m,$d,$y);
    %dow=%Date::Manip::Week;
    if (&IsInt($dow)) {
      return ""  if ($dow<1  ||  $dow>7);
    } else {
      return ""  if (! exists $dow{lc($dow)});
      $dow=$dow{lc($dow)};
    }
    if ($dow == $curr_dow) {
      $date=&DateCalc_DateDelta($date,"-0:0:1:0:0:0:0",\$err,0)  if (! $today);
    } else {
      $dow -= 7  if ($dow>$curr_dow); # make sure previous day is less
      $num = $curr_dow - $dow;
      $date=&DateCalc_DateDelta($date,"-0:0:0:$num:0:0:0",\$err,0);
    }
    $date=&Date_SetTime($date,$hr,$min,$sec)  if (defined $hr);

  } else {
    ($h,$mn,$s)=( &Date_Split($date) )[3..5];
    ($th,$tm,$ts)=&Date_ParseTime($hr,$min,$sec);
    if (defined $hr and $hr ne "") {
      ($hr,$min,$sec)=($th,$tm,$ts);
      $delta="-0:0:0:1:0:0:0";
    } elsif (defined $min and $min ne "") {
      ($hr,$min,$sec)=($h,$tm,$ts);
      $delta="-0:0:0:0:1:0:0";
    } elsif (defined $sec and $sec ne "") {
      ($hr,$min,$sec)=($h,$mn,$ts);
      $delta="-0:0:0:0:0:1:0";
    } else {
      confess "ERROR: invalid arguments in Date_GetPrev.\n";
    }

    $d=&Date_SetTime($date,$hr,$min,$sec);
    if ($today) {
      $d=&DateCalc_DateDelta($d,$delta,\$err,0)  if ($d gt $date);
    } else {
      $d=&DateCalc_DateDelta($d,$delta,\$err,0)  if ($d ge $date);
    }
    $date=$d;
  }
  return $date;
}

sub Date_GetNext {
  print "DEBUG: Date_GetNext\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$dow,$today,$hr,$min,$sec)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  my($y,$m,$d,$h,$mn,$s,$err,$curr_dow,%dow,$num,$delta,$th,$tm,$ts)=();

  if (! &Date_Split($date)) {
    $date=&ParseDateString($date);
    return ""  if (! $date);
  }
  ($y,$m,$d)=( &Date_Split($date) )[0..2];

  if (defined $dow and $dow ne "") {
    $curr_dow=&Date_DayOfWeek($m,$d,$y);
    %dow=%Date::Manip::Week;
    if (&IsInt($dow)) {
      return ""  if ($dow<1  ||  $dow>7);
    } else {
      return ""  if (! exists $dow{lc($dow)});
      $dow=$dow{lc($dow)};
    }
    if ($dow == $curr_dow) {
      $date=&DateCalc_DateDelta($date,"+0:0:1:0:0:0:0",\$err,0)  if (! $today);
    } else {
      $curr_dow -= 7  if ($curr_dow>$dow); # make sure next date is greater
      $num = $dow - $curr_dow;
      $date=&DateCalc_DateDelta($date,"+0:0:0:$num:0:0:0",\$err,0);
    }
    $date=&Date_SetTime($date,$hr,$min,$sec)  if (defined $hr);

  } else {
    ($h,$mn,$s)=( &Date_Split($date) )[3..5];
    ($th,$tm,$ts)=&Date_ParseTime($hr,$min,$sec);
    if (defined $hr and $hr ne "") {
      ($hr,$min,$sec)=($th,$tm,$ts);
      $delta="+0:0:0:1:0:0:0";
    } elsif (defined $min and $min ne "") {
      ($hr,$min,$sec)=($h,$tm,$ts);
      $delta="+0:0:0:0:1:0:0";
    } elsif (defined $sec and $sec ne "") {
      ($hr,$min,$sec)=($h,$mn,$ts);
      $delta="+0:0:0:0:0:1:0";
    } else {
      confess "ERROR: invalid arguments in Date_GetNext.\n";
    }

    $d=&Date_SetTime($date,$hr,$min,$sec);
    if ($today) {
      $d=&DateCalc_DateDelta($d,$delta,\$err,0)  if ($d lt $date);
    } else {
      $d=&DateCalc_DateDelta($d,$delta,\$err,0)  if ($d le $date);
    }
    $date=$d;
  }

  return $date;
}

###
# NOTE: The following routines may be called in the routines below with very
#       little time penalty.
###
sub Date_SetTime {
  print "DEBUG: Date_SetTime\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$h,$mn,$s)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  my($y,$m,$d)=();

  if (! &Date_Split($date)) {
    $date=&ParseDateString($date);
    return ""  if (! $date);
  }

  ($y,$m,$d)=( &Date_Split($date) )[0..2];
  ($h,$mn,$s)=&Date_ParseTime($h,$mn,$s);

  my($ampm,$wk);
  return ""  if (&Date_DateCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
  &Date_Join($y,$m,$d,$h,$mn,$s);
}

sub Date_SetDateField {
  print "DEBUG: Date_SetDateField\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$field,$val,$nocheck)=@_;
  my($y,$m,$d,$h,$mn,$s)=();
  $nocheck=0  if (! defined $nocheck);

  ($y,$m,$d,$h,$mn,$s)=&Date_Split($date);

  if (! $y) {
    $date=&ParseDateString($date);
    return "" if (! $date);
    ($y,$m,$d,$h,$mn,$s)=&Date_Split($date);
  }

  if      (lc($field) eq "y") {
    $y=$val;
  } elsif (lc($field) eq "m") {
    $m=$val;
  } elsif (lc($field) eq "d") {
    $d=$val;
  } elsif (lc($field) eq "h") {
    $h=$val;
  } elsif (lc($field) eq "mn") {
    $mn=$val;
  } elsif (lc($field) eq "s") {
    $s=$val;
  } else {
    confess "ERROR: Date_SetDateField: invalid field: $field\n";
  }

  $date=&Date_Join($y,$m,$d,$h,$mn,$s);
  return $date  if ($nocheck  ||  &Date_Split($date));
  return "";
}

########################################################################
# OTHER SUBROUTINES
########################################################################
# NOTE: These routines should not call any of the routines above as
#       there will be a severe time penalty (and the possibility of
#       infinite recursion).  The last couple routines above are
#       exceptions.
# NOTE: Date_Init is a special case.  It should be called (conditionally)
#       in every routine that uses any variable from the Date::Manip
#       namespace.
########################################################################

sub Date_DaysInMonth {
  print "DEBUG: Date_DaysInMonth\n"  if ($Date::Manip::Debug =~ /trace/);
  my($m,$y)=@_;
  $y=&Date_FixYear($y)  if (length($y)!=4);
  my(@d_in_m)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
  $d_in_m[2]=29  if (&Date_LeapYear($y));
  return $d_in_m[$m];
}

sub Date_DayOfWeek {
  print "DEBUG: Date_DayOfWeek\n"  if ($Date::Manip::Debug =~ /trace/);
  my($m,$d,$y)=@_;
  $y=&Date_FixYear($y)  if (length($y)!=4);
  my($dayofweek,$dec31)=();

  $dec31=2;                     # Dec 31, 0999 was Tuesday
  $dayofweek=(&Date_DaysSince999($m,$d,$y)+$dec31) % 7;
  $dayofweek=7  if ($dayofweek==0);
  return $dayofweek;
}

# Can't be in "use integer" because the numbers are two big.
no integer;
sub Date_SecsSince1970 {
  print "DEBUG: Date_SecsSince1970\n"  if ($Date::Manip::Debug =~ /trace/);
  my($m,$d,$y,$h,$mn,$s)=@_;
  $y=&Date_FixYear($y)  if (length($y)!=4);
  my($sec_now,$sec_70)=();
  $sec_now=(&Date_DaysSince999($m,$d,$y)-1)*24*3600 + $h*3600 + $mn*60 + $s;
# $sec_70 =(&Date_DaysSince999(1,1,1970)-1)*24*3600;
  $sec_70 =30610224000;
  return ($sec_now-$sec_70);
}

sub Date_SecsSince1970GMT {
  print "DEBUG: Date_SecsSince1970GMT\n"  if ($Date::Manip::Debug =~ /trace/);
  my($m,$d,$y,$h,$mn,$s)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  $y=&Date_FixYear($y)  if (length($y)!=4);

  my($sec)=&Date_SecsSince1970($m,$d,$y,$h,$mn,$s);
  return $sec   if ($Date::Manip::ConvTZ eq "IGNORE");

  my($tz)=$Date::Manip::ConvTZ;
  $tz=$Date::Manip::TZ  if (! $tz);
  $tz=$Date::Manip::Zone{lc($tz)}  if ($tz !~ /^[+-]\d{4}$/);

  my($tzs)=1;
  $tzs=-1 if ($tz<0);
  $tz=~/.(..)(..)/;
  my($tzh,$tzm)=($1,$2);
  $sec - $tzs*($tzh*3600+$tzm*60);
}
use integer;

sub Date_DaysSince999 {
  print "DEBUG: Date_DaysSince999\n"  if ($Date::Manip::Debug =~ /trace/);
  my($m,$d,$y)=@_;
  $y=&Date_FixYear($y)  if (length($y)!=4);
  my($Ny,$N4,$N100,$N400,$dayofyear,$days)=();
  my($cc,$yy)=();

  $y=~ /(\d{2})(\d{2})/;
  ($cc,$yy)=($1,$2);

  # Number of full years since Dec 31, 0999
  $Ny=$y-1000;

  # Number of full 4th years (incl. 1000) since Dec 31, 0999
  $N4=($Ny-1)/4 + 1;
  $N4=0         if ($y==1000);

  # Number of full 100th years (incl. 1000)
  $N100=$cc-9;
  $N100--       if ($yy==0);

  # Number of full 400th years
  $N400=($N100+1)/4;

  $dayofyear=&Date_DayOfYear($m,$d,$y);
  $days= $Ny*365 + $N4 - $N100 + $N400 + $dayofyear;

  return $days;
}

sub Date_DayOfYear {
  print "DEBUG: Date_DayOfYear\n"  if ($Date::Manip::Debug =~ /trace/);
  my($m,$d,$y)=@_;
  $y=&Date_FixYear($y)  if (length($y)!=4);
  # DinM    = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  my(@days) = ( 0, 31, 59, 90,120,151,181,212,243,273,304,334,365);
  my($ly)=0;
  $ly=1  if ($m>2 && &Date_LeapYear($y));
  return ($days[$m-1]+$d+$ly);
}

sub Date_DaysInYear {
  print "DEBUG: Date_DaysInYear\n"  if ($Date::Manip::Debug =~ /trace/);
  my($y)=@_;
  $y=&Date_FixYear($y)  if (length($y)!=4);
  return 366  if (&Date_LeapYear($y));
  return 365;
}

sub Date_WeekOfYear {
  print "DEBUG: Date_WeekOfYear\n"  if ($Date::Manip::Debug =~ /trace/);
  my($m,$d,$y,$f)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  $y=&Date_FixYear($y)  if (length($y)!=4);

  my($day,$dow,$doy)=();
  $doy=&Date_DayOfYear($m,$d,$y);

  # The current DayOfYear and DayOfWeek
  if ($Date::Manip::Jan1Week1) {
    $day=1;
  } else {
    $day=4;
  }
  $dow=&Date_DayOfWeek(1,$day,$y);

  # Move back to the first day of week 1.
  $f-=7  if ($f>$dow);
  $day-= ($dow-$f);

  return 0  if ($day>$doy);      # Day is in last week of previous year
  return (($doy-$day)/7 + 1);
}

sub Date_LeapYear {
  print "DEBUG: Date_LeapYear\n"  if ($Date::Manip::Debug =~ /trace/);
  my($y)=@_;
  $y=&Date_FixYear($y)  if (length($y)!=4);
  return 0 unless $y % 4 == 0;
  return 1 unless $y % 100 == 0;
  return 0 unless $y % 400 == 0;
  return 1;
}

sub Date_DaySuffix {
  print "DEBUG: Date_DaySuffix\n"  if ($Date::Manip::Debug =~ /trace/);
  my($d)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  return $Date::Manip::Day[$d-1];
}

sub Date_ConvTZ {
  print "DEBUG: Date_ConvTZ\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$from,$to)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  my($gmt)=();

  if (! defined $from  or  ! $from) {

    if (! defined $to  or  ! $to) {
      # TZ -> ConvTZ
      return $date
        if ($Date::Manip::ConvTZ eq "IGNORE" or ! $Date::Manip::ConvTZ);
      $from=$Date::Manip::TZ;
      $to=$Date::Manip::ConvTZ;

    } else {
      # ConvTZ,TZ -> $to
      $from=$Date::Manip::ConvTZ;
      $from=$Date::Manip::TZ  if (! $from);
    }

  } else {

    if (! defined $to  or  ! $to) {
      # $from -> ConvTZ,TZ
      return $date
        if ($Date::Manip::ConvTZ eq "IGNORE");
      $to=$Date::Manip::ConvTZ;
      $to=$Date::Manip::TZ  if (! $to);

    } else {
      # $from -> $to
    }
  }

  $to=$Date::Manip::Zone{lc($to)}
    if (exists $Date::Manip::Zone{lc($to)});
  $from=$Date::Manip::Zone{lc($from)}
    if (exists $Date::Manip::Zone{lc($from)});
  $gmt=$Date::Manip::Zone{gmt};

  return $date  if ($from !~ /^[+-]\d{4}$/ or $to !~ /^[+-]\d{4}$/);
  return $date  if ($from eq $to);

  my($s1,$h1,$m1,$s2,$h2,$m2,$d,$h,$m,$sign,$delta,$err,$yr,$mon,$sec)=();
  # We're going to try to do the calculation without calling DateCalc.
  ($yr,$mon,$d,$h,$m,$sec)=&Date_Split($date);

  # Convert $date from $from to GMT
  $from=~/([+-])(\d{2})(\d{2})/;
  ($s1,$h1,$m1)=($1,$2,$3);
  $s1= ($s1 eq "-" ? "+" : "-");   # switch sign
  $sign=$s1 . "1";     # + or - 1

  # and from GMT to $to
  $to=~/([+-])(\d{2})(\d{2})/;
  ($s2,$h2,$m2)=($1,$2,$3);

  if ($s1 eq $s2) {
    # Both the same sign
    $m+= $sign*($m1+$m2);
    $h+= $sign*($h1+$h2);
  } else {
    $sign=($s2 eq "-" ? +1 : -1)  if ($h1<$h2  ||  ($h1==$h2 && $m1<$m2));
    $m+= $sign*($m1-$m2);
    $h+= $sign*($h1-$h2);
  }

  if ($m>59) {
    $h+= $m/60;
    $m-= ($m/60)*60;
  } elsif ($m<0) {
    $h+= ($m/60 - 1);
    $m-= ($m/60 - 1)*60;
  }

  if ($h>23) {
    $delta=$h/24;
    $h -= $delta*24;
    if (($d + $delta) > 28) {
      $date=&Date_Join($yr,$mon,$d,$h,$m,$sec);
      return &DateCalc_DateDelta($date,"+0:0:0:$delta:0:0:0",\$err,0);
    }
    $d+= $delta;
  } elsif ($h<0) {
    $delta=-$h/24 + 1;
    $h += $delta*24;
    if (($d - $delta) < 1) {
      $date=&Date_Join($yr,$mon,$d,$h,$m,$sec);
      return &DateCalc_DateDelta($date,"-0:0:0:$delta:0:0:0",\$err,0);
    }
    $d-= $delta;
  }
  return &Date_Join($yr,$mon,$d,$h,$m,$sec);
}

sub Date_TimeZone {
  print "DEBUG: Date_TimeZone\n"  if ($Date::Manip::Debug =~ /trace/);
  my($null,$tz,@tz,$std,$dst,$time,$isdst,$tmp,$in)=();
  &Date_Init()  if (! $Date::Manip::InitDone);

  # Get timezones from all of the relevant places

  push(@tz,$Date::Manip::TZ)  if (defined $Date::Manip::TZ);  # TZ config var
  push(@tz,$ENV{"TZ"})        if (exists $ENV{"TZ"});         # TZ environ var
  # Microsoft operating systems don't have a date command built in.  Try
  # to trap all the various ways of knowing we are on one of these systems:
  unless (($^X =~ /perl\.exe$/i) or
          (defined $^O and
           $^O =~ /MSWin32/i ||
           $^O =~ /Windows_95/i ||
           $^O =~ /Windows_NT/i) or
          (defined $ENV{OS} and
           $ENV{OS} =~ /MSWin32/i ||
           $ENV{OS} =~ /Windows_95/i ||
           $ENV{OS} =~ /Windows_NT/i)) {
    $tz = `date`;
    chomp($tz);
    $tz=(split(/\s+/,$tz))[4];
    push(@tz,$tz);
  }
  push(@tz,$main::TZ)         if (defined $main::TZ);         # $main::TZ
  if (-s "/etc/TIMEZONE") {                                   # /etc/TIMEZONE
    $in=new IO::File;
    $in->open("/etc/TIMEZONE","r");
    while (! eof($in)) {
      $tmp=<$in>;
      if ($tmp =~ /^TZ\s*=\s*(.*?)\s*$/) {
        push(@tz,$1);
        last;
      }
    }
    $in->close;
  }

  # Now parse each one to find the first valid one.
  foreach $tz (@tz) {
    return uc($tz)
      if (defined $Date::Manip::Zone{lc($tz)} or $tz=~/^[+-]\d{4}/);

    # Handle US/Eastern format
    if ($tz =~ /^$Date::Manip::CurrZoneExp$/i) {
      $tmp=lc $1;
      $tz=$Date::Manip::CurrZone{$tmp};
    }

    # Handle STD#DST# format
    if ($tz =~ /^([a-z]+)\d([a-z]+)\d?$/i) {
      ($std,$dst)=($1,$2);
      next  if (! defined $Date::Manip::Zone{lc($std)} or
                ! defined $Date::Manip::Zone{lc($dst)});
      $time = time();
      ($null,$null,$null,$null,$null,$null,$null,$null,$isdst) =
        localtime($time);
      return uc($dst)  if ($isdst);
      return uc($std);
    }
  }

  confess "ERROR: Date::Manip unable to determine TimeZone.\n";
}

# Returns 1 if $date is a work day.  If $time is non-zero, the time is
# also checked to see if it falls within work hours.
sub Date_IsWorkDay {
  print "DEBUG: Date_IsWorkDay\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$time)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  $date=&ParseDateString($date);
  my($d)=$date;
  $d=&Date_SetTime($date,$Date::Manip::WorkDayBeg)
    if (! defined $time  or  ! $time);

  my($y,$mon,$day,$tmp,$h,$m,$dow)=();
  ($y,$mon,$day,$h,$m,$tmp)=&Date_Split($d);
  $dow=&Date_DayOfWeek($mon,$day,$y);

  return 0  if ($dow<$Date::Manip::WorkWeekBeg or
                $dow>$Date::Manip::WorkWeekEnd or
                "$h:$m" lt $Date::Manip::WorkDayBeg or
                "$h:$m" gt $Date::Manip::WorkDayEnd);
  if ($y!=$Date::Manip::CurrHolidayYear) {
    $Date::Manip::CurrHolidayYear=$y;
    &Date_UpdateHolidays;
  }
  $d=&Date_SetTime($date,"00:00:00");
  return 0  if (exists $Date::Manip::CurrHolidays{$d});
  1;
}

# Finds the day $off work days from now.  If $time is passed in, we must
# also take into account the time of day.
#
# If $time is not passed in, day 0 is today (if today is a workday) or the
# next work day if it isn't.  In any case, the time of day is unaffected.
#
# If $time is passed in, day 0 is now (if now is part of a workday) or the
# start of the very next work day.
sub Date_NextWorkDay {
  print "DEBUG: Date_NextWorkDay\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$off,$time)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  $date=&ParseDateString($date);
  my($err)=();

  if (! &Date_IsWorkDay($date,$time)) {
    if (defined $time and $time) {
      while (1) {
        $date=&Date_GetNext($date,undef,0,$Date::Manip::WorkDayBeg);
        last  if (&Date_IsWorkDay($date,$time));
      }
    } else {
      while (1) {
        $date=&DateCalc_DateDelta($date,"+0:0:0:1:0:0:0",\$err,0);
        last  if (&Date_IsWorkDay($date,$time));
      }
    }
  }

  while ($off>0) {
    while (1) {
      $date=&DateCalc_DateDelta($date,"+0:0:0:1:0:0:0",\$err,0);
      last  if (&Date_IsWorkDay($date,$time));
    }
    $off--;
  }

  return $date;
}

# Finds the day $off work days before now.  If $time is passed in, we must
# also take into account the time of day.
#
# If $time is not passed in, day 0 is today (if today is a workday) or the
# previous work day if it isn't.  In any case, the time of day is unaffected.
#
# If $time is passed in, day 0 is now (if now is part of a workday) or the
# end of the previous work period.  Note that since the end of a work day
# will automatically be turned into the start of the next one, this time
# may actually be treated as AFTER the current time.
sub Date_PrevWorkDay {
  print "DEBUG: Date_PrevWorkDay\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$off,$time)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  $date=&ParseDateString($date);
  my($err)=();

  if (! &Date_IsWorkDay($date,$time)) {
    if (defined $time and $time) {
      while (1) {
        $date=&Date_GetPrev($date,undef,0,$Date::Manip::WorkDayEnd);
        last  if (&Date_IsWorkDay($date,$time));
      }
      while (1) {
        $date=&Date_GetNext($date,undef,0,$Date::Manip::WorkDayBeg);
        last  if (&Date_IsWorkDay($date,$time));
      }
    } else {
      while (1) {
        $date=&DateCalc_DateDelta($date,"-0:0:0:1:0:0:0",\$err,0);
        last  if (&Date_IsWorkDay($date,$time));
      }
    }
  }

  while ($off>0) {
    while (1) {
      $date=&DateCalc_DateDelta($date,"-0:0:0:1:0:0:0",\$err,0);
      last  if (&Date_IsWorkDay($date,$time));
    }
    $off--;
  }

  return $date;
}

# This finds the nearest workday to $date.  If $date is a workday, it
# is returned.
sub Date_NearestWorkDay {
  print "DEBUG: Date_NearestWorkDay\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$tomorrow)=@_;
  &Date_Init()  if (! $Date::Manip::InitDone);
  $date=&ParseDateString($date);
  my($a,$b,$dela,$delb,$err)=();
  $tomorrow=$Date::Manip::TomorrowFirst  if (! defined $tomorrow);

  return $date  if (&Date_IsWorkDay($date));

  # Find the nearest one.
  if ($tomorrow) {
    $dela="+0:0:0:1:0:0:0";
    $delb="-0:0:0:1:0:0:0";
  } else {
    $dela="-0:0:0:1:0:0:0";
    $delb="+0:0:0:1:0:0:0";
  }
  $a=$b=$date;

  while (1) {
    $a=&DateCalc_DateDelta($a,$dela,\$err);
    return $a  if (&Date_IsWorkDay($a));
    $b=&DateCalc_DateDelta($b,$delb,\$err);
    return $b  if (&Date_IsWorkDay($b));
  }
}

# &Date_NthDayOfYear($y,$n);
#   Returns a list of (YYYY,MM,DD,HH,MM,SS) for the Nth day of the year.
sub Date_NthDayOfYear {
  no integer;
  print "DEBUG: Date_NthDayOfYear\n"  if ($Date::Manip::Debug =~ /trace/);
  my($y,$n)=@_;
  $y=$Date::Manip::CurrY  if (! defined $y  or  ! $y);
  $n=1       if (! defined $n  or  $n eq "");
  $n+=0;     # to turn 023 into 23
  $y=&Date_FixYear($y)  if (length($y)<4);
  my $leap=&Date_LeapYear($y);
  return ()  if ($n<1);
  return ()  if ($n >= ($leap ? 367 : 366));

  my(@d_in_m)=(31,28,31,30,31,30,31,31,30,31,30,31);
  $d_in_m[1]=29  if ($leap);

  # Calculate the hours, minutes, and seconds into the day.
  my $remain=($n - int($n))*24;
  my $h=int($remain);
  $remain=($remain - $h)*60;
  my $mn=int($remain);
  $remain=($remain - $mn)*60;
  my $s=$remain;

  # Calculate the month and the day.
  my($m,$d)=(0,0);
  while ($n>0) {
    $m++;
    if ($n<=$d_in_m[0]) {
      $d=int($n);
      $n=0;
    } else {
      $n-= $d_in_m[0];
      shift(@d_in_m);
    }
  }

  ($y,$m,$d,$h,$mn,$s);
}

########################################################################
# NOT FOR EXPORT
########################################################################

# This is used in Date_Init to fill in a hash based on international
# data.  It takes a list of keys and values and returns both a hash
# with these values and a regular expression of keys.

sub Date_InitHash {
  print "DEBUG: Date_InitHash\n"  if ($Date::Manip::Debug =~ /trace/);
  my($data,$regexp,$opts,$hash)=@_;
  my(@data)=@$data;
  my($key,$val,@list)=();

  # Parse the options
  my($lc,$sort,$back)=(0,0,0);
  $lc=1     if ($opts =~ /lc/i);
  $sort=1   if ($opts =~ /sort/i);
  $back=1   if ($opts =~ /back/i);

  # Create the hash
  while (@data) {
    ($key,$val,@data)=@data;
    $key=lc($key)  if ($lc);
    $$hash{$key}=$val;
  }

  # Create the regular expression
  if ($regexp) {
    @list=keys(%$hash);
    @list=sort sortByLength(@list)  if ($sort);
    if ($back) {
      $$regexp="(" . join("|",@list) . ")";
    } else {
      $$regexp="(?:" . join("|",@list) . ")";
    }
  }
}

# This is used in Date_Init to fill in regular expressions, lists, and
# hashes based on international data.  It takes a list of lists which have
# to be stored as regular expressions (to find any element in the list),
# lists, and hashes (indicating the location in the lists).

sub Date_InitLists {
  print "DEBUG: Date_InitLists\n"  if ($Date::Manip::Debug =~ /trace/);
  my($data,$regexp,$opts,$lists,$hash)=@_;
  my(@data)=@$data;
  my(@lists)=@$lists;
  my($i,@ele,$ele,@list,$j,$tmp)=();

  # Parse the options
  my($lc,$sort,$back)=(0,0,0);
  $lc=1     if ($opts =~ /lc/i);
  $sort=1   if ($opts =~ /sort/i);
  $back=1   if ($opts =~ /back/i);

  # Set each of the lists
  if (@lists) {
    confess "ERROR: Date_InitLists: lists must be 1 per data\n"
      if ($#lists != $#data);
    for ($i=0; $i<=$#data; $i++) {
      @ele=@{ $data[$i] };
      if ($Date::Manip::IntCharSet && $#ele>0) {
        @{ $lists[$i] } = @{ $ele[1] };
      } else {
        @{ $lists[$i] } = @{ $ele[0] };
      }
    }
  }

  # Create the hash
  my($hashtype,$hashsave,%hash)=();
  if (@$hash) {
    ($hash,$hashtype)=@$hash;
    $hashsave=1;
  } else {
    $hashtype=0;
    $hashsave=0;
  }
  for ($i=0; $i<=$#data; $i++) {
    @ele=@{ $data[$i] };
    foreach $ele (@ele) {
      @list = @{ $ele };
      for ($j=0; $j<=$#list; $j++) {
        $tmp=$list[$j];
        next  if (! defined $tmp  or  ! $tmp);
        $tmp=lc($tmp)  if ($lc);
        $hash{$tmp}= $j+$hashtype;
      }
    }
  }
  %$hash = %hash  if ($hashsave);

  # Create the regular expression
  if ($regexp) {
    @list=keys(%hash);
    @list=sort sortByLength(@list)  if ($sort);
    if ($back) {
      $$regexp="(" . join("|",@list) . ")";
    } else {
      $$regexp="(?:" . join("|",@list) . ")";
    }
  }
}

# This is used in Date_Init to fill in regular expressions and lists based
# on international data.  This takes a list of strings and returns a regular
# expression (to find any one of them).

sub Date_InitStrings {
  print "DEBUG: Date_InitStrings\n"  if ($Date::Manip::Debug =~ /trace/);
  my($data,$regexp,$opts)=@_;
  my(@list)=@{ $data };

  # Parse the options
  my($lc,$sort,$back)=(0,0,0);
  $lc=1     if ($opts =~ /lc/i);
  $sort=1   if ($opts =~ /sort/i);
  $back=1   if ($opts =~ /back/i);

  # Create the regular expression
  @list=sort sortByLength(@list)  if ($sort);
  if ($back) {
    $$regexp="(" . join("|",@list) . ")";
  } else {
    $$regexp="(?:" . join("|",@list) . ")";
  }
  $$regexp=lc($$regexp)  if ($lc);
}

# items is passed in (either as a space separated string, or a reference to
# a list) and a regular expression which matches any one of the items is
# prepared.  The regular expression will be of one of the forms:
#   "(a|b)"       @list not empty, back option included
#   "(?:a|b)"     @list not empty
#   "()"          @list empty,     back option included
#   ""            @list empty
# $options is a string which contains any of the following strings:
#   back     : the regular expression has a backreference
#   opt      : the regular expression is optional and a "?" is appended in
#              the first two forms
#   optws    : the regular expression is optional and may be replaced by
#              whitespace
#   optWs    : the regular expression is optional, but if not present, must
#              be replaced by whitespace
#   sort     : the items in the list are sorted by length (longest first)
#   lc       : the string is lowercased
#   under    : any underscores are converted to spaces
#   pre      : it may be preceded by whitespace
#   Pre      : it must be preceded by whitespace
#   PRE      : it must be preceded by whitespace or the start
#   post     : it may be followed by whitespace
#   Post     : it must be followed by whitespace
#   POST     : it must be followed by whitespace or the end
# Spaces due to pre/post options will not be included in the back reference.
#
# If $array is included, then the elements will also be returned as a list.
# $array is a string which may contain any of the following:
#   keys     : treat the list as a hash and only the keys go into the regexp
#   key0     : treat the list as the values of a hash with keys 0 .. N-1
#   key1     : treat the list as the values of a hash with keys 1 .. N
#   val0     : treat the list as the keys of a hash with values 0 .. N-1
#   val1     : treat the list as the keys of a hash with values 1 .. N

#    &Date_InitLists([$lang{"month_name"},$lang{"month_abb"}],
#             [\$Date::Manip::MonExp,"lc,sort,back"],
#             [\@Date::Manip::Month,\@Date::Manip::Mon],
#             [\%Date::Manip::Month,1]);

# This is used in Date_Init to prepare regular expressions.  A list of
# items is passed in (either as a space separated string, or a reference to
# a list) and a regular expression which matches any one of the items is
# prepared.  The regular expression will be of one of the forms:
#   "(a|b)"       @list not empty, back option included
#   "(?:a|b)"     @list not empty
#   "()"          @list empty,     back option included
#   ""            @list empty
# $options is a string which contains any of the following strings:
#   back     : the regular expression has a backreference
#   opt      : the regular expression is optional and a "?" is appended in
#              the first two forms
#   optws    : the regular expression is optional and may be replaced by
#              whitespace
#   optWs    : the regular expression is optional, but if not present, must
#              be replaced by whitespace
#   sort     : the items in the list are sorted by length (longest first)
#   lc       : the string is lowercased
#   under    : any underscores are converted to spaces
#   pre      : it may be preceded by whitespace
#   Pre      : it must be preceded by whitespace
#   PRE      : it must be preceded by whitespace or the start
#   post     : it may be followed by whitespace
#   Post     : it must be followed by whitespace
#   POST     : it must be followed by whitespace or the end
# Spaces due to pre/post options will not be included in the back reference.
#
# If $array is included, then the elements will also be returned as a list.
# $array is a string which may contain any of the following:
#   keys     : treat the list as a hash and only the keys go into the regexp
#   key0     : treat the list as the values of a hash with keys 0 .. N-1
#   key1     : treat the list as the values of a hash with keys 1 .. N
#   val0     : treat the list as the keys of a hash with values 0 .. N-1
#   val1     : treat the list as the keys of a hash with values 1 .. N
sub Date_Regexp {
  print "DEBUG: Date_Regexp\n"  if ($Date::Manip::Debug =~ /trace/);
  my($list,$options,$array)=@_;
  my(@list,$ret,%hash,$i)=();
  local($_)=();
  $options=""  if (! defined $options);
  $array=""    if (! defined $array);

  my($sort,$lc,$under)=(0,0,0);
  $sort =1  if ($options =~ /sort/i);
  $lc   =1  if ($options =~ /lc/i);
  $under=1  if ($options =~ /under/i);
  my($back,$opt,$pre,$post,$ws)=("?:","","","","");
  $back =""          if ($options =~ /back/i);
  $opt  ="?"         if ($options =~ /opt/i);
  $pre  ='\s*'       if ($options =~ /pre/);
  $pre  ='\s+'       if ($options =~ /Pre/);
  $pre  ='(?:\s+|^)' if ($options =~ /PRE/);
  $post ='\s*'       if ($options =~ /post/);
  $post ='\s+'       if ($options =~ /Post/);
  $post ='(?:$|\s+)' if ($options =~ /POST/);
  $ws   ='\s*'       if ($options =~ /optws/);
  $ws   ='\s+'       if ($options =~ /optws/);

  my($hash,$keys,$key0,$key1,$val0,$val1)=(0,0,0,0,0,0);
  $keys =1     if ($array =~ /keys/i);
  $key0 =1     if ($array =~ /key0/i);
  $key1 =1     if ($array =~ /key1/i);
  $val0 =1     if ($array =~ /val0/i);
  $val1 =1     if ($array =~ /val1/i);
  $hash =1     if ($keys or $key0 or $key1 or $val0 or $val1);

  my($ref)=ref $list;
  if (! $ref) {
    $list =~ s/\s*$//;
    $list =~ s/^\s*//;
    $list =~ s/\s+/&&&/g;
  } elsif ($ref eq "ARRAY") {
    $list = join("&&&",@$list);
  } else {
    confess "ERROR: Date_Regexp.\n";
  }

  if (! $list) {
    if ($back eq "") {
      return "()";
    } else {
      return "";
    }
  }

  $list=lc($list)  if ($lc);
  $list=~ s/_/ /g  if ($under);
  @list=split(/&&&/,$list);
  if ($keys) {
    %hash=@list;
    @list=keys %hash;
  } elsif ($key0 or $key1 or $val0 or $val1) {
    $i=0;
    $i=1  if ($key1 or $val1);
    if ($key0 or $key1) {
      %hash= map { $_,$i++ } @list;
    } else {
      %hash= map { $i++,$_ } @list;
    }
  }
  @list=sort sortByLength(@list)  if ($sort);

  $ret="($back" . join("|",@list) . ")";
  $ret="(?:$pre$ret$post)"  if ($pre or $post);
  $ret.=$opt;
  $ret="(?:$ret|$ws)"  if ($ws);

  if ($array and $hash) {
    return ($ret,%hash);
  } elsif ($array) {
    return ($ret,@list);
  } else {
    return $ret;
  }
}

# This will produce a delta with the correct number of signs.  At most two
# signs will be in it normally (one before the year, and one in front of
# the day), but if appropriate, signs will be in front of all elements.
# Also, as many of the signs will be equivalent as possible.
sub Delta_Normalize {
  print "DEBUG: Delta_Normalize\n"  if ($Date::Manip::Debug =~ /trace/);
  my($delta,$mode)=@_;
  return "" if (! defined $delta  or  ! $delta);
  return "+0:+0:+0:+0:+0:+0:+0"
    if ($delta =~ /^([+-]?0+:){6}[+-]?0+$/ and $Date::Manip::DeltaSigns);
  return "+0:0:0:0:0:0:0" if ($delta =~ /^([+-]?0+:){6}[+-]?0+$/);

  my($tmp,$sign1,$sign2,$len)=();

  # Calculate the length of the day in minutes
  $len=24*60;
  $len=$Date::Manip::WDlen  if ($mode==2);

  # We have to get the sign of every component explicitely so that a "-0"
  # or "+0" doesn't get lost by treating it numerically (i.e. "-0:0:2" must
  # be a negative delta).

  my($y,$mon,$w,$d,$h,$m,$s)=&Delta_Split($delta);

  # We need to make sure that the signs of all parts of a delta are the
  # same.  The easiest way to do this is to convert all of the large
  # components to the smallest ones, then convert the smaller components
  # back to the larger ones.

  # Do the year/month part

  $mon += $y*12;                         # convert y to m
  $sign1="+";
  if ($mon<0) {
    $mon *= -1;
    $sign1="-";
  }

  $y    = $mon/12;                       # convert m to y
  $mon -= $y*12;

  $y=0    if ($y eq "-0");               # get around silly -0 problem
  $mon=0  if ($mon eq "-0");

  # Do the wk/day/hour/min/sec part

  {
    # Unfortunately, $s is overflowing for dates more than ~70 years
    # apart.
    no integer;

    $s += ($d+7*$w)*$len*60 + $h*3600 + $m*60; # convert w/d/h/m to s
    $sign2="+";
    if ($s<0) {
      $s*=-1;
      $sign2="-";
    }

    $m  = int($s/60);                    # convert s to m
    $s -= $m*60;
    $d  = int($m/$len);                  # convert m to d
    $m -= $d*$len;

    # The rest should be fine.
  }
  $h  = $m/60;                           # convert m to h
  $m -= $h*60;
  $w  = $d/7;                            # convert d to w
  $d -= $w*7;

  $w=0    if ($w eq "-0");               # get around silly -0 problem
  $d=0    if ($d eq "-0");
  $h=0    if ($h eq "-0");
  $m=0    if ($m eq "-0");
  $s=0    if ($s eq "-0");

  # Only include two signs if necessary
  $sign1=$sign2  if ($y==0 and $mon==0);
  $sign2=$sign1  if ($w==0 and $d==0 and $h==0 and $m==0 and $s==0);
  $sign2=""  if ($sign1 eq $sign2  and  ! $Date::Manip::DeltaSigns);

  if ($Date::Manip::DeltaSigns) {
    return "$sign1$y:$sign1$mon:$sign2$w:$sign2$d:$sign2$h:$sign2$m:$sign2$s";
  } else {
    return "$sign1$y:$mon:$sign2$w:$d:$h:$m:$s";
  }
}

# This checks a delta to make sure it is valid.  If it is, it splits
# it and returns the elements with a sign on each.  The 2nd argument
# specifies the default sign.  Blank elements are set to 0.  If the
# third element is non-nil, exactly 7 elements must be included.
sub Delta_Split {
  print "DEBUG: Delta_Split\n"  if ($Date::Manip::Debug =~ /trace/);
  my($delta,$sign,$exact)=@_;
  my(@delta)=split(/:/,$delta);
  return ()  if (defined $exact  and  $exact  and $#delta != 6);
  my($i)=();
  $sign="+"  if (! defined $sign);
  for ($i=0; $i<=$#delta; $i++) {
    $delta[$i]="0"  if (! $delta[$i]);
    return ()  if ($delta[$i] !~ /^[+-]?\d+$/);
    $sign = ($delta[$i] =~ s/^([+-])// ? $1 : $sign);
    $delta[$i] = $sign.$delta[$i];
  }
  @delta;
}

# Reads up to 3 arguments.  $h may contain the time in any international
# fomrat.  Any empty elements are set to 0.
sub Date_ParseTime {
  print "DEBUG: Date_ParseTime\n"  if ($Date::Manip::Debug =~ /trace/);
  my($h,$m,$s)=@_;
  my($t)=&CheckTime("one");

  if (defined $h  and  $h =~ /$t/) {
    $h=$1;
    $m=$2;
    $s=$3   if (defined $3);
  }
  $h="00"  if (! defined $h);
  $m="00"  if (! defined $m);
  $s="00"  if (! defined $s);

  ($h,$m,$s);
}

# Forms a date with the 6 elements passed in (all of which must be defined).
# No check as to validity is made.
sub Date_Join {
  print "DEBUG: Date_Join\n"  if ($Date::Manip::Debug =~ /trace/);
  my($y,$m,$d,$h,$mn,$s)=@_;
  my($ym,$md,$dh,$hmn,$mns)=();

  if      ($Date::Manip::Internal == 0) {
    $ym=$md=$dh="";
    $hmn=$mns=":";

  } elsif ($Date::Manip::Internal == 1) {
    $ym=$md=$dh=$hmn=$mns="";

  } elsif ($Date::Manip::Internal == 2) {
    $ym=$md="-";
    $dh=" ";
    $hmn=$mns=":";

  } else {
    confess "ERROR: Invalid internal format in Date_Join.\n";
  }
  $m="0$m"    if (length($m)==1);
  $d="0$d"    if (length($d)==1);
  $h="0$h"    if (length($h)==1);
  $mn="0$mn"  if (length($mn)==1);
  $s="0$s"    if (length($s)==1);
  "$y$ym$m$md$d$dh$h$hmn$mn$mns$s";
}

# This checks a time.  If it is valid, it splits it and returns 3 elements.
# If "one" or "two" is passed in, a regexp with 1/2 or 2 digit hours is
# returned.
sub CheckTime {
  print "DEBUG: CheckTime\n"  if ($Date::Manip::Debug =~ /trace/);
  my($time)=@_;
  my($h)='(?:0?[0-9]|1[0-9]|2[0-3])';
  my($h2)='(?:0[0-9]|1[0-9]|2[0-3])';
  my($m)='[0-5][0-9]';
  my($s)=$m;
  my($hm)="(?:$Date::Manip::SepHM|:)";
  my($ms)="(?:$Date::Manip::SepMS|:)";
  my($ss)=$Date::Manip::SepSS;
  my($t)="^($h)$hm($m)(?:$ms($s)(?:$ss\d+)?)?\$";
  if ($time eq "one") {
    return $t;
  } elsif ($time eq "two") {
    $t="^($h2)$hm($m)(?:$ms($s)(?:$ss\d+)?)?\$";
    return $t;
  }

  if ($time =~ /$t/i) {
    ($h,$m,$s)=($1,$2,$3);
    $h="0$h" if (length($h)<2);
    $m="0$m" if (length($m)<2);
    $s="00"  if (! defined $s);
    return ($h,$m,$s);
  } else {
    return ();
  }
}

# This checks a date.  If it is valid, it splits it and returns the elements.
# If no date is passed in, it returns a regular expression for the date.
sub Date_Split {
  print "DEBUG: Date_Split\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date)=@_;
  my($ym,$md,$dh,$hmn,$mns)=();
  my($y)='(\d{4})';
  my($m)='(0[1-9]|1[0-2])';
  my($d)='(0[1-9]|[1-2][0-9]|3[0-1])';
  my($h)='([0-1][0-9]|2[0-3])';
  my($mn)='([0-5][0-9])';
  my($s)=$mn;

  if      ($Date::Manip::Internal == 0) {
    $ym=$md=$dh="";
    $hmn=$mns=":";

  } elsif ($Date::Manip::Internal == 1) {
    $ym=$md=$dh=$hmn=$mns="";

  } elsif ($Date::Manip::Internal == 2) {
    $ym=$md="-";
    $dh=" ";
    $hmn=$mns=":";

  } else {
    confess "ERROR: Invalid internal format in Date_Split.\n";
  }

  my($t)="^$y$ym$m$md$d$dh$h$hmn$mn$mns$s\$";
  return $t  if ($date eq "");

  if ($date =~ /$t/) {
    ($y,$m,$d,$h,$mn,$s)=($1,$2,$3,$4,$5,$6);
    my(@d_in_m)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
    $d_in_m[2]=29  if (&Date_LeapYear($y));
    return ()  if ($d>$d_in_m[$m]);
    return ($y,$m,$d,$h,$mn,$s);
  }
  return ();
}

# This takes a list of years, months, WeekOfMonth's, and optionally
# DayOfWeek's, and returns a list of dates.  Optionally, a list of dates
# can be passed in as the 1st argument (with the 2nd argument the null list)
# and the year/month of these will be used.
sub Date_Recur_WoM {
  my($y,$m,$w,$d,$FDn)=@_;
  my(@y)=@$y;
  my(@m)=@$m;
  my(@w)=@$w;
  my(@d)=@$d;
  my($date0,$date1,@tmp,@date,$d0,$d1,@tmp2)=();

  if (@m) {
    @tmp=();
    foreach $y (@y) {
      return ()  if (length($y)==1 || length($y)==3 || ! &IsInt($y,1,9999));
      $y=&Date_FixYear($y)  if (length($y)==2);
      push(@tmp,$y);
    }
    @y=sort { $a<=>$b } (@tmp);

    return ()  if (! @m);
    foreach $m (@m) {
      return ()  if (! &IsInt($m,1,12));
    }
    @m=sort { $a<=>$b } (@m);

    @tmp=@tmp2=();
    foreach $y (@y) {
      foreach $m (@m) {
        push(@tmp,$y);
        push(@tmp2,$m);
      }
    }

    @y=@tmp;
    @m=@tmp2;

  } else {
    foreach $d0 (@y) {
      @tmp=&Date_Split($d0);
      return ()  if (! @tmp);
      push(@tmp2,$tmp[0]);
      push(@m,$tmp[1]);
    }
    @y=@tmp2;
  }

  return ()  if (! @w);
  foreach $w (@w) {
    return ()  if ($w==0  ||  ! &IsInt($w,-5,5));
  }

  if (@d) {
    foreach $d (@d) {
      return ()  if (! &IsInt($d,1,7));
    }
    @d=sort { $a<=>$b } (@d);
  }

  @date=();
  foreach $y (@y) {
    $m=shift(@m);

    # Find 1st day of this month and next month
    $date0=&Date_Join($y,$m,1,0,0,0);
    $date1=&DateCalc($date0,"+0:1:0:0:0:0:0");

    if (@d) {
      foreach $d (@d) {
        # Find 1st occurence of DOW (in both months)
        $d0=&Date_GetNext($date0,$d,1);
        $d1=&Date_GetNext($date1,$d,1);

        @tmp=();
        while ($d0 lt $d1) {
          push(@tmp,$d0);
          $d0=&DateCalc($d0,"+0:0:1:0:0:0:0");
        }

        @tmp2=();
        foreach $w (@w) {
          if ($w>0) {
            push(@tmp2,$tmp[$w-1]);
          } else {
            push(@tmp2,$tmp[$#tmp+1+$w]);
          }
        }
        @tmp2=sort(@tmp2);
        push(@date,@tmp2);
      }

    } else {
      # Find 1st day of 1st week
      $date0=&Date_GetNext($date0,$FDn,1);
      $date0=&Date_GetPrev($date0,$Date::Manip::FirstDay,1);

      # Find 1st day of 1st week of next month
      $date1=&Date_GetNext($date1,$FDn,1);
      $date1=&Date_GetPrev($date1,$Date::Manip::FirstDay,1);

      @tmp=();
      while ($date0 lt $date1) {
        push(@tmp,$date0);
        $date0=&DateCalc($date0,"+0:0:1:0:0:0:0");
      }

      @tmp2=();
      foreach $w (@w) {
        if ($w>0) {
          push(@tmp2,$tmp[$w-1]);
        } else {
          push(@tmp2,$tmp[$#tmp+1+$w]);
        }
      }
      @tmp2=sort(@tmp2);
      push(@date,@tmp2);
    }
  }

  @date;
}

# This returns a sorted list of dates formed by adding/subtracting
# $delta to $dateb in the range $date0<=$d<$dateb.  The first date int
# the list is actually the first date<$date0 and the last date in the
# list is the first date>=$date1 (because sometimes the set part will
# move the date back into the range).
sub Date_Recur {
  my($date0,$date1,$dateb,$delta)=@_;
  my(@ret,$d)=();

  while ($dateb lt $date0) {
    $dateb=&DateCalc_DateDelta($dateb,$delta);
  }
  while ($dateb ge $date1) {
    $dateb=&DateCalc_DateDelta($dateb,"-$delta");
  }

  # Add the dates $date0..$dateb
  $d=$dateb;
  while ($d ge $date0) {
    unshift(@ret,$d);
    $d=&DateCalc_DateDelta($d,"-$delta");
  }
  # Add the first date earler than the range
  unshift(@ret,$d);

  # Add the dates $dateb..$date1
  $d=&DateCalc_DateDelta($dateb,$delta);
  while ($d lt $date1) {
    push(@ret,$d);
    $d=&DateCalc_DateDelta($d,$delta);
  }
  # Add the first date later than the range
  push(@ret,$d);

  @ret;
}

# This sets the values in each date of a recurrence.
#
# $h,$m,$s can each be values or lists "1-2,4".  If any are equal to "-1",
# they are not set (and none of the larger elements are set).
sub Date_RecurSetTime {
  my($date0,$date1,$dates,$h,$m,$s)=@_;
  my(@dates)=@$dates;
  my(@h,@m,@s,$date,@tmp)=();

  $m="-1"  if ($s eq "-1");
  $h="-1"  if ($m eq "-1");

  if ($h ne "-1") {
    @h=&ReturnList($h);
    return ()  if ! (@h);
    @h=sort { $a<=>$b } (@h);

    @tmp=();
    foreach $date (@dates) {
      foreach $h (@h) {
        push(@tmp,&Date_SetDateField($date,"h",$h,1));
      }
    }
    @dates=@tmp;
  }

  if ($m ne "-1") {
    @m=&ReturnList($m);
    return ()  if ! (@m);
    @m=sort { $a<=>$b } (@m);

    @tmp=();
    foreach $date (@dates) {
      foreach $m (@m) {
        push(@tmp,&Date_SetDateField($date,"mn",$m,1));
      }
    }
    @dates=@tmp;
  }

  if ($s ne "-1") {
    @s=&ReturnList($s);
    return ()  if ! (@s);
    @s=sort { $a<=>$b } (@s);

    @tmp=();
    foreach $date (@dates) {
      foreach $s (@s) {
        push(@tmp,&Date_SetDateField($date,"s",$s,1));
      }
    }
    @dates=@tmp;
  }

  @tmp=();
  foreach $date (@dates) {
    push(@tmp,$date)  if ($date ge $date0  &&  $date lt $date1  &&
                          &Date_Split($date));
  }

  @tmp;
}

sub DateCalc_DateDate {
  print "DEBUG: DateCalc_DateDate\n"  if ($Date::Manip::Debug =~ /trace/);
  my($D1,$D2,$mode)=@_;
  my(@d_in_m)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
  $mode=0  if (! defined $mode);

  # Exact mode
  if ($mode==0) {
    my($y1,$m1,$d1,$h1,$mn1,$s1)=&Date_Split($D1);
    my($y2,$m2,$d2,$h2,$mn2,$s2)=&Date_Split($D2);
    my($i,@delta,$d,$delta,$y)=();

    # form the delta for hour/min/sec
    $delta[4]=$h2-$h1;
    $delta[5]=$mn2-$mn1;
    $delta[6]=$s2-$s1;

    # form the delta for yr/mon/day
    $delta[0]=$delta[1]=0;
    $d=0;
    if ($y2>$y1) {
      $d=&Date_DaysInYear($y1) - &Date_DayOfYear($m1,$d1,$y1);
      $d+=&Date_DayOfYear($m2,$d2,$y2);
      for ($y=$y1+1; $y<$y2; $y++) {
        $d+= &Date_DaysInYear($y);
      }
    } elsif ($y2<$y1) {
      $d=&Date_DaysInYear($y2) - &Date_DayOfYear($m2,$d2,$y2);
      $d+=&Date_DayOfYear($m1,$d1,$y1);
      for ($y=$y2+1; $y<$y1; $y++) {
        $d+= &Date_DaysInYear($y);
      }
      $d *= -1;
    } else {
      $d=&Date_DayOfYear($m2,$d2,$y2) - &Date_DayOfYear($m1,$d1,$y1);
    }
    $delta[2]=0;
    $delta[3]=$d;

    for ($i=0; $i<6; $i++) {
      $delta[$i]="+".$delta[$i]  if ($delta[$i]>=0);
    }

    $delta=join(":",@delta);
    $delta=&Delta_Normalize($delta,0);
    return $delta;
  }

  my($date1,$date2)=($D1,$D2);
  my($tmp,$sign,$err,@tmp)=();

  # make sure both are work days
  if ($mode==2) {
    $date1=&Date_NextWorkDay($date1,0,1);
    $date2=&Date_NextWorkDay($date2,0,1);
  }

  # make sure date1 comes before date2
  if ($date1 gt $date2) {
    $sign="-";
    $tmp=$date1;
    $date1=$date2;
    $date2=$tmp;
  } else {
    $sign="+";
  }
  if ($date1 eq $date2) {
    return "+0:+0:+0:+0:+0:+0:+0"  if ($Date::Manip::DeltaSigns);
    return "+0:0:0:0:0:0:0";
  }

  my($y1,$m1,$d1,$h1,$mn1,$s1)=&Date_Split($date1);
  my($y2,$m2,$d2,$h2,$mn2,$s2)=&Date_Split($date2);
  my($dy,$dm,$dw,$dd,$dh,$dmn,$ds,$ddd)=();

  # Do years
  $dy=$y2-$y1;
  $dm=0;
  if ($dy>0) {
    $tmp=&DateCalc_DateDelta($date1,"+$dy:0:0:0:0:0:0",\$err,0);
    if ($tmp gt $date2) {
      $dy--;
      $tmp=$date1;
      $tmp=&DateCalc_DateDelta($date1,"+$dy:0:0:0:0:0:0",\$err,0)  if ($dy>0);
      $dm=12;
    }
    $date1=$tmp;
  }

  # Do months
  $dm+=$m2-$m1;
  if ($dm>0) {
    $tmp=&DateCalc_DateDelta($date1,"+0:$dm:0:0:0:0:0",\$err,0);
    if ($tmp gt $date2) {
      $dm--;
      $tmp=$date1;
      $tmp=&DateCalc_DateDelta($date1,"+0:$dm:0:0:0:0:0",\$err,0)  if ($dm>0);
    }
    $date1=$tmp;
  }

  # At this point, check to see that we're on a business day again so that
  # Aug 3 (Monday) -> Sep 3 (Sunday) -> Sep 4 (Monday)  = 1 month
  if ($mode==2) {
    if (! &Date_IsWorkDay($date1,0)) {
      $date1=&Date_NextWorkDay($date1,0,1);
    }
  }

  # Do days
  if ($mode==2) {
    $dd=0;
    while (1) {
      $tmp=&Date_NextWorkDay($date1,1,1);
      if ($tmp le $date2) {
        $dd++;
        $date1=$tmp;
      } else {
        last;
      }
    }

  } else {
    ($y1,$m1,$d1)=( &Date_Split($date1) )[0..2];
    $dd=0;
    # If we're jumping across months, set $d1 to the first of the next month
    # (or possibly the 0th of next month which is equivalent to the last day
    # of this month)
    if ($m1!=$m2) {
      $d_in_m[2]=29  if (&Date_LeapYear($y1));
      $dd=$d_in_m[$m1]-$d1+1;
      $d1=1;
      $tmp=&DateCalc_DateDelta($date1,"+0:0:0:$dd:0:0:0",\$err,0);
      if ($tmp gt $date2) {
        $dd--;
        $d1--;
        $tmp=&DateCalc_DateDelta($date1,"+0:0:0:$dd:0:0:0",\$err,0);
      }
      $date1=$tmp;
    }

    $ddd=0;
    if ($d1<$d2) {
      $ddd=$d2-$d1;
      $tmp=&DateCalc_DateDelta($date1,"+0:0:0:$ddd:0:0:0",\$err,0);
      if ($tmp gt $date2) {
        $ddd--;
        $tmp=&DateCalc_DateDelta($date1,"+0:0:0:$ddd:0:0:0",\$err,0);
      }
      $date1=$tmp;
    }
    $dd+=$ddd;
  }

  # in business mode, make sure h1 comes before h2 (if not find delta between
  # now and end of day and move to start of next business day)
  $d1=( &Date_Split($date1) )[2];
  $dh=$dmn=$ds=0;
  if ($mode==2  and  $d1 != $d2) {
    $tmp=&Date_SetTime($date1,$Date::Manip::WorkDayEnd);
    $tmp=&DateCalc_DateDelta($tmp,"+0:0:0:0:0:1:0")
      if ($Date::Manip::WorkDay24Hr);
    $tmp=&DateCalc_DateDate($date1,$tmp,0);
    ($tmp,$tmp,$tmp,$tmp,$dh,$dmn,$ds)=&Delta_Split($tmp);
    $date1=&Date_NextWorkDay($date1,1,0);
    $date1=&Date_SetTime($date1,$Date::Manip::WorkDayBeg);
    $d1=( &Date_Split($date1) )[2];
    confess "ERROR: DateCalc DateDate Business.\n"  if ($d1 != $d2);
  }

  # Hours, minutes, seconds
  $tmp=&DateCalc_DateDate($date1,$date2,0);
  @tmp=&Delta_Split($tmp);
  $dh  += $tmp[4];
  $dmn += $tmp[5];
  $ds  += $tmp[6];

  $tmp="$sign$dy:$dm:0:$dd:$dh:$dmn:$ds";
  &Delta_Normalize($tmp,$mode);
}

sub DateCalc_DeltaDelta {
  print "DEBUG: DateCalc_DeltaDelta\n"  if ($Date::Manip::Debug =~ /trace/);
  my($D1,$D2,$mode)=@_;
  my(@delta1,@delta2,$i,$delta,@delta)=();
  $mode=0  if (! defined $mode);

  @delta1=&Delta_Split($D1);
  @delta2=&Delta_Split($D2);
  for ($i=0; $i<7; $i++) {
    $delta[$i]=$delta1[$i]+$delta2[$i];
    $delta[$i]="+".$delta[$i]  if ($delta[$i]>=0);
  }

  $delta=join(":",@delta);
  $delta=&Delta_Normalize($delta,$mode);
  return $delta;
}

sub DateCalc_DateDelta {
  print "DEBUG: DateCalc_DateDelta\n"  if ($Date::Manip::Debug =~ /trace/);
  my($D1,$D2,$errref,$mode)=@_;
  my($date)=();
  my(@d_in_m)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
  my($h1,$m1,$h2,$m2,$len,$hh,$mm)=();
  $mode=0  if (! defined $mode);

  if ($mode==2) {
    $h1=$Date::Manip::WDBh;
    $m1=$Date::Manip::WDBm;
    $h2=$Date::Manip::WDEh;
    $m2=$Date::Manip::WDEm;
    $hh=$h2-$h1;
    $mm=$m2-$m1;
    if ($mm<0) {
      $hh--;
      $mm+=60;
    }
  }

  # Date, delta
  my($y,$m,$d,$h,$mn,$s)=&Date_Split($D1);
  my($dy,$dm,$dw,$dd,$dh,$dmn,$ds)=&Delta_Split($D2);
  $dd += $dw*7;

  # do the month/year part
  $y+=$dy;
  &ModuloAddition(-12,$dm,\$m,\$y);   # -12 means 1-12 instead of 0-11
  $d_in_m[2]=29  if (&Date_LeapYear($y));

  # if we have gone past the last day of a month, move the date back to
  # the last day of the month
  if ($d>$d_in_m[$m]) {
    $d=$d_in_m[$m];
  }

  # in business mode, set the day to a work day at this point so the h/mn/s
  # stuff will work out
  if ($mode==2) {
    $d=$d_in_m[$m] if ($d>$d_in_m[$m]);
    $date=&Date_NextWorkDay(&Date_Join($y,$m,$d,$h,$mn,$s),0,1);
    ($y,$m,$d,$h,$mn,$s)=&Date_Split($date);
  }

  # seconds, minutes, hours
  &ModuloAddition(60,$ds,\$s,\$mn);
  if ($mode==2) {
    while (1) {
      &ModuloAddition(60,$dmn,\$mn,\$h);
      $h+= $dh;

      if ($h>$h2  or  $h==$h2 && $mn>$m2) {
        $dh=$h-$h2;
        $dmn=$mn-$m2;
        $h=$h1;
        $mn=$m1;
        $dd++;

      } elsif ($h<$h1  or  $h==$h1 && $mn<$m1) {
        $dh=$h1-$h;
        $dmn=$m1-$mn;
        $h=$h2;
        $mn=$m2;
        $dd--;

      } elsif ($h==$h2  &&  $mn==$m2) {
        $dd++;
        $dh=-$hh;
        $dmn=-$mm;

      } else {
        last;
      }
    }

  } else {
    &ModuloAddition(60,$dmn,\$mn,\$h);
    &ModuloAddition(24,$dh,\$h,\$d);
  }

  # If we have just gone past the last day of the month, we need to make
  # up for this:
  if ($d>$d_in_m[$m]) {
    $dd+= $d-$d_in_m[$m];
    $d=$d_in_m[$m];
  }

  # days
  if ($mode==2) {
    if ($dd>=0) {
      $date=&Date_NextWorkDay(&Date_Join($y,$m,$d,$h,$mn,$s),$dd,1);
    } else {
      $date=&Date_PrevWorkDay(&Date_Join($y,$m,$d,$h,$mn,$s),-$dd,1);
    }
    ($y,$m,$d,$h,$mn,$s)=&Date_Split($date);

  } else {
    $d_in_m[2]=29  if (&Date_LeapYear($y));
    $d=$d_in_m[$m]  if ($d>$d_in_m[$m]);
    $d += $dd;
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
  }

  if ($y<1000 or $y>9999) {
    $$errref=3;
    return;
  }
  &Date_Join($y,$m,$d,$h,$mn,$s);
}

sub Date_UpdateHolidays {
  print "DEBUG: Date_UpdateHolidays\n"  if ($Date::Manip::Debug =~ /trace/);
  my($date,$delta,$err)=();
  local($_)=();
  foreach (keys %Date::Manip::Holidays) {
    if (/^(.*)([+-].*)$/) {
      # Date +/- Delta
      ($date,$delta)=($1,$2);
      $Date::Manip::UpdateHolidays=1;
      $date=&ParseDateString($date);
      $Date::Manip::UpdateHolidays=0;
      $date=&DateCalc($date,$delta,\$err,0);

    } else {
      # Date
      $Date::Manip::UpdateHolidays=1;
      $date=&ParseDateString($_);
      $Date::Manip::UpdateHolidays=0;
    }
    $Date::Manip::CurrHolidays{$date}=1;
  }
}

# This sets a Date::Manip config variable.
sub Date_SetConfigVariable {
  print "DEBUG: Date_SetConfigVariable\n"  if ($Date::Manip::Debug =~ /trace/);
  my($var,$val)=@_;

  return  if ($var =~ /^PersonalCnf$/i);
  return  if ($var =~ /^PersonalCnfPath$/i);

  $Date::Manip::InitFilesRead=1,     return  if ($var =~ /^IgnoreGlobalCnf$/i);
  %Date::Manip::Holidays=(),         return  if ($var =~ /^EraseHolidays$/i);
  $Date::Manip::Init=0,
  $Date::Manip::Language=$val,       return  if ($var =~ /^Language$/i);
  $Date::Manip::DateFormat=$val,     return  if ($var =~ /^DateFormat$/i);
  $Date::Manip::TZ=$val,             return  if ($var =~ /^TZ$/i);
  $Date::Manip::ConvTZ=$val,         return  if ($var =~ /^ConvTZ$/i);
  $Date::Manip::Internal=$val,       return  if ($var =~ /^Internal$/i);
  $Date::Manip::FirstDay=$val,       return  if ($var =~ /^FirstDay$/i);
  $Date::Manip::WorkWeekBeg=$val,    return  if ($var =~ /^WorkWeekBeg$/i);
  $Date::Manip::WorkWeekEnd=$val,    return  if ($var =~ /^WorkWeekEnd$/i);
  $Date::Manip::WorkDayBeg=$val,
  $Date::Manip::ResetWorkDay=1,      return  if ($var =~ /^WorkDayBeg$/i);
  $Date::Manip::WorkDayEnd=$val,
  $Date::Manip::ResetWorkDay=1,      return  if ($var =~ /^WorkDayEnd$/i);
  $Date::Manip::WorkDay24Hr=$val,
  $Date::Manip::ResetWorkDay=1,      return  if ($var =~ /^WorkDay24Hr$/i);
  $Date::Manip::DeltaSigns=$val,     return  if ($var =~ /^DeltaSigns$/i);
  $Date::Manip::Jan1Week1=$val,      return  if ($var =~ /^Jan1Week1$/i);
  $Date::Manip::YYtoYYYY=$val,       return  if ($var =~ /^YYtoYYYY$/i);
  $Date::Manip::UpdateCurrTZ=$val,   return  if ($var =~ /^UpdateCurrTZ$/i);
  $Date::Manip::IntCharSet=$val,     return  if ($var =~ /^IntCharSet$/i);
  $Date::Manip::DebugVal=$val,       return  if ($var =~ /^Debug$/i);
  $Date::Manip::TomorrowFirst=$val,  return  if ($var =~ /^TomorrowFirst$/i);
  $Date::Manip::ForceDate=$val,      return  if ($var =~ /^ForceDate$/i);

  confess "ERROR: Unknown configuration variable $var in Date::Manip.\n";
}

# This reads an init file.
sub Date_InitFile {
  print "DEBUG: Date_InitFile\n"  if ($Date::Manip::Debug =~ /trace/);
  my($file)=@_;
  local($_)=();
  my($section)="vars";
  my($var,$val,$date,$name)=();

  open(IN,$file);
  while(defined ($_=<IN>)) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    next  if (! $_  or  /^\#/);
    if (s/^\*\s*//) {
      $section=$_;
      next;
    }

    if ($section =~ /var/) {
      confess "ERROR: invalid Date::Manip config file line.\n  $_\n"
        if (! /(.*\S)\s*=\s*(.*)$/);
      ($var,$val)=($1,$2);
      &Date_SetConfigVariable($var,$val);

    } elsif ($section =~ /holiday/i) {
      confess "ERROR: invalid Date::Manip config file line.\n  $_\n"
        if (! /(.*\S)\s*=\s*(.*)$/);
      ($date,$name)=($1,$2);
      $name=""  if (! defined $name);
      $Date::Manip::Holidays{$date}=$name;

    } else {
      # A section not currently used by Date::Manip (but may be
      # used by some extension to it).
      next;
    }
  }
  close(IN);
}

# Get rid of a problem with old versions of perl
no strict "vars";
# This sorts from longest to shortest element
sub sortByLength {
  return (length $b <=> length $a);
}
use strict "vars";

# $flag=&Date_TimeCheck(\$h,\$mn,\$s,\$ampm);
#   Returns 1 if any of the fields are bad.  All fields are optional, and
#   all possible checks are done on the data.  If a field is not passed in,
#   it is set to default values.  If data is missing, appropriate defaults
#   are supplied.
sub Date_TimeCheck {
  print "DEBUG: Date_TimeCheck\n"  if ($Date::Manip::Debug =~ /trace/);
  my($h,$mn,$s,$ampm)=@_;
  my($tmp1,$tmp2,$tmp3)=();

  $$h=""     if (! defined $$h);
  $$mn=""    if (! defined $$mn);
  $$s=""     if (! defined $$s);
  $$ampm=""  if (! defined $$ampm);
  $$ampm=uc($$ampm)  if ($$ampm);

  # Check hour
  $tmp1=$Date::Manip::AmPmExp;
  $tmp2="";
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

# $flag=&Date_DateCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk);
#   Returns 1 if any of the fields are bad.  All fields are optional, and
#   all possible checks are done on the data.  If a field is not passed in,
#   it is set to default values.  If data is missing, appropriate defaults
#   are supplied.
#
#   If the flag Date::Manip::UpdateHolidays is set, the year is set to
#   Date::Manip::CurrHolidayYear.
sub Date_DateCheck {
  print "DEBUG: Date_DateCheck\n"  if ($Date::Manip::Debug =~ /trace/);
  my($y,$m,$d,$h,$mn,$s,$ampm,$wk)=@_;
  my($tmp1,$tmp2,$tmp3)=();

  my(@d_in_m)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
  my($curr_y)=$Date::Manip::CurrY;
  my($curr_m)=$Date::Manip::CurrM;
  my($curr_d)=$Date::Manip::CurrD;
  $$m=1, $$d=1  if (defined $$y and ! defined $$m and ! defined $$d);
  $$y=""     if (! defined $$y);
  $$m=""     if (! defined $$m);
  $$d=""     if (! defined $$d);
  $$wk=""    if (! defined $$wk);
  $$d=$curr_d  if ($$y eq "" and $$m eq "" and $$d eq "");

  # Check year.
  $$y=$Date::Manip::CurrHolidayYear  if ($Date::Manip::UpdateHolidays);
  $$y=$curr_y    if ($$y eq "");
  $$y=&Date_FixYear($$y)  if (length($$y)<4);
  return 1       if (! &IsInt($$y,1,9999));
  $d_in_m[2]=29  if (&Date_LeapYear($$y));

  # Check month
  $$m=$curr_m     if ($$m eq "");
  $$m=$Date::Manip::Month{lc($$m)}  if (exists $Date::Manip::Month{lc($$m)});
  $$m="0$$m"      if (length($$m)==1);
  return 1        if (! &IsInt($$m,1,12));

  # Check day
  $$d="01"        if ($$d eq "");
  $$d="0$$d"      if (length($$d)==1);
  return 1        if (! &IsInt($$d,1,$d_in_m[$$m]));
  if ($$wk) {
    $tmp1=&Date_DayOfWeek($$m,$$d,$$y);
    $tmp2=$Date::Manip::Week{lc($$wk)}
      if (exists $Date::Manip::Week{lc($$wk)});
    return 1      if ($tmp1 != $tmp2);
  }

  return &Date_TimeCheck($h,$mn,$s,$ampm);
}

# Takes a year in 2 digit form and returns it in 4 digit form
sub Date_FixYear {
  print "DEBUG: Date_FixYear\n"  if ($Date::Manip::Debug =~ /trace/);
  my($y)=@_;
  my($curr_y)=$Date::Manip::CurrY;
  $y=$curr_y  if (! defined $y  or  ! $y);
  return $y  if (length($y)==4);
  confess "ERROR: Invalid year ($y)\n"  if (length($y)!=2);
  my($y1,$y2)=();

  if (lc($Date::Manip::YYtoYYYY) eq "c") {
    $y1=substring($y,0,2);
    $y="$y1$y";

  } elsif ($Date::Manip::YYtoYYYY =~ /^c(\d{2})$/) {
    $y1=$1;
    $y="$y1$y";

  } else {
    $y1=$curr_y-$Date::Manip::YYtoYYYY;
    $y2=$y1+99;
    $y="19$y";
    while ($y<$y1) {
      $y+=100;
    }
    while ($y>$y2) {
      $y-=100;
    }
  }
  $y;
}

# &Date_NthWeekOfYear($y,$n);
#   Returns a list of (YYYY,MM,DD) for the 1st day of the Nth week of the
#   year.
# &Date_NthWeekOfYear($y,$n,$dow,$flag);
#   Returns a list of (YYYY,MM,DD) for the Nth DoW of the year.  If flag
#   is nil, the first DoW of the year may actually be in the previous
#   year (since the 1st week may include days from the previous year).
#   If flag is non-nil, the 1st DoW of the year refers to the 1st one
#   actually in the year
sub Date_NthWeekOfYear {
  print "DEBUG: Date_NthWeekOfYear\n"  if ($Date::Manip::Debug =~ /trace/);
  my($y,$n,$dow,$flag)=@_;
  my($m,$d,$err,$tmp,$date,%dow)=();
  $y=$Date::Manip::CurrY  if (! defined $y  or  ! $y);
  $n=1       if (! defined $n  or  $n eq "");
  return ()  if ($n<0  ||  $n>53);
  if (defined $dow) {
    $dow=lc($dow);
    %dow=%Date::Manip::Week;
    $dow=$dow{$dow}  if (exists $dow{$dow});
    return ()  if ($dow<1 || $dow>7);
    $flag=""   if (! defined $flag);
  } else {
    $dow="";
    $flag="";
  }

  $y=&Date_FixYear($y)  if (length($y)<4);
  if ($Date::Manip::Jan1Week1) {
    $date=&Date_Join($y,1,1,0,0,0);
  } else {
    $date=&Date_Join($y,1,4,0,0,0);
  }
  $date=&Date_GetPrev($date,$Date::Manip::FirstDay,1);
  $date=&Date_GetNext($date,$dow,1)  if ($dow ne "");

  if ($flag) {
    ($tmp)=&Date_Split($date);
    $n++  if ($tmp != $y);
  }

  $date=&DateCalc_DateDelta($date,"+0:0:". ($n-1) . ":0:0:0:0",\$err,0)
    if ($n>1);
  ($y,$m,$d)=&Date_Split($date);
  ($y,$m,$d);
}

########################################################################
# LANGUAGE INITIALIZATION
########################################################################

# 8-bit international characters can be gotten by "\xXX".  I don't know
# how to get 16-bit characters.  I've got to read up on perllocale.
sub Char_8Bit {
  my($hash)=@_;

  #   grave `
  #     A`    00c0     a`    00e0
  #     E`    00c8     e`    00e8
  #     I`    00cc     i`    00ec
  #     O`    00d2     o`    00f2
  #     U`    00d9     u`    00f9
  #     W`    1e80     w`    1e81
  #     Y`    1ef2     y`    1ef3
  $$hash{"A`"} = "\xc0";   #   Å¿
  $$hash{"E`"} = "\xc8";   #   Å»
  $$hash{"I`"} = "\xcc";   #   ÅÃ
  $$hash{"O`"} = "\xd2";   #   Å“
  $$hash{"U`"} = "\xd9";   #   ÅŸ
  $$hash{"a`"} = "\xe0";   #   Å‡
  $$hash{"e`"} = "\xe8";   #   ÅË
  $$hash{"i`"} = "\xec";   #   ÅÏ
  $$hash{"o`"} = "\xf2";   #   ÅÚ
  $$hash{"u`"} = "\xf9";   #   Å˘

  #   acute '
  #     A'    00c1     a'    00e1
  #     C'    0106     c'    0107
  #     E'    00c9     e'    00e9
  #     I'    00cd     i'    00ed
  #     L'    0139     l'    013a
  #     N'    0143     n'    0144
  #     O'    00d3     o'    00f3
  #     R'    0154     r'    0155
  #     S'    015a     s'    015b
  #     U'    00da     u'    00fa
  #     W'    1e82     w'    1e83
  #     Y'    00dd     y'    00fd
  #     Z'    0179     z'    017a

  $$hash{"A'"} = "\xc1";   #   Å¡
  $$hash{"E'"} = "\xc9";   #   Å…
  $$hash{"I'"} = "\xcd";   #   ÅÕ
  $$hash{"O'"} = "\xd3";   #   Å”
  $$hash{"U'"} = "\xda";   #   Å⁄
  $$hash{"Y'"} = "\xdd";   #   Å›
  $$hash{"a'"} = "\xe1";   #   Å·
  $$hash{"e'"} = "\xe9";   #   ÅÈ
  $$hash{"i'"} = "\xed";   #   ÅÌ
  $$hash{"o'"} = "\xf3";   #   ÅÛ
  $$hash{"u'"} = "\xfa";   #   Å˙
  $$hash{"y'"} = "\xfd";   #   Å˝

  #   double acute "         "
  #     O"    0150     o"    0151
  #     U"    0170     u"    0171

  #   circumflex ^
  #     A^    00c2     a^    00e2
  #     C^    0108     c^    0109
  #     E^    00ca     e^    00ea
  #     G^    011c     g^    011d
  #     H^    0124     h^    0125
  #     I^    00ce     i^    00ee
  #     J^    0134     j^    0135
  #     O^    00d4     o^    00f4
  #     S^    015c     s^    015d
  #     U^    00db     u^    00fb
  #     W^    0174     w^    0175
  #     Y^    0176     y^    0177

  $$hash{"A^"} = "\xc2";   #   Å¬
  $$hash{"E^"} = "\xca";   #   Å 
  $$hash{"I^"} = "\xce";   #   ÅŒ
  $$hash{"O^"} = "\xd4";   #   Å‘
  $$hash{"U^"} = "\xdb";   #   Å€
  $$hash{"a^"} = "\xe2";   #   Å‚
  $$hash{"e^"} = "\xea";   #   ÅÍ
  $$hash{"i^"} = "\xee";   #   ÅÓ
  $$hash{"o^"} = "\xf4";   #   ÅÙ
  $$hash{"u^"} = "\xfb";   #   Å˚

  #   tilde ~
  #     A~    00c3    a~    00e3
  #     I~    0128    i~    0129
  #     N~    00d1    n~    00f1
  #     O~    00d5    o~    00f5
  #     U~    0168    u~    0169

  $$hash{"A~"} = "\xc3";   #   Å√
  $$hash{"N~"} = "\xd1";   #   Å—
  $$hash{"O~"} = "\xd5";   #   Å’
  $$hash{"a~"} = "\xe3";   #   Å„
  $$hash{"n~"} = "\xf1";   #   ÅÒ
  $$hash{"o~"} = "\xf5";   #   Åı

  #   macron -
  #     A-    0100    a-    0101
  #     E-    0112    e-    0113
  #     I-    012a    i-    012b
  #     O-    014c    o-    014d
  #     U-    016a    u-    016b

  #   breve ( [half circle up]
  #     A(    0102    a(    0103
  #     G(    011e    g(    011f
  #     U(    016c    u(    016d

  #   dot .
  #     C.    010a    c.    010b
  #     E.    0116    e.    0117
  #     G.    0120    g.    0121
  #     I.    0130
  #     Z.    017b    z.    017c

  #   diaeresis :  [side by side dots]
  #     A:    00c4    a:    00e4
  #     E:    00cb    e:    00eb
  #     I:    00cf    i:    00ef
  #     O:    00d6    o:    00f6
  #     U:    00dc    u:    00fc
  #     W:    1e84    w:    1e85
  #     Y:    0178    y:    00ff

  $$hash{"A:"} = "\xc4";   #   Åƒ
  $$hash{"E:"} = "\xcb";   #   ÅÀ
  $$hash{"I:"} = "\xcf";   #   Åœ
  $$hash{"O:"} = "\xd6";   #   Å÷
  $$hash{"U:"} = "\xdc";   #   Å‹
  $$hash{"a:"} = "\xe4";   #   Å‰
  $$hash{"e:"} = "\xeb";   #   ÅÎ
  $$hash{"i:"} = "\xef";   #   ÅÔ
  $$hash{"o:"} = "\xf6";   #   Åˆ
  $$hash{"u:"} = "\xfc";   #   Å¸
  $$hash{"y:"} = "\xff";   #   Å~

  #   ring o
  #     U0    016e    u0    016f

  #   cedilla ,  [squiggle down and left below the letter]
  #     ,C    00c7    ,c    00e7
  #     ,G    0122    ,g    0123
  #     ,K    0136    ,k    0137
  #     ,L    013b    ,l    013c
  #     ,N    0145    ,n    0146
  #     ,R    0156    ,r    0157
  #     ,S    015e    ,s    015f
  #     ,T    0162    ,t    0163

  $$hash{",C"} = "\xc7";   #   Å«
  $$hash{",c"} = "\xe7";   #   ÅÁ

  #   ogonek ;  [squiggle down and right below the letter]
  #     A;    0104    a;    0105
  #     E;    0118    e;    0119
  #     I;    012e    i;    012f
  #     U;    0172    u;    0173

  #   caron <  [little v on top]
  #     A<    01cd    a<    01ce
  #     C<    010c    c<    010d
  #     D<    010e    d<    010f
  #     E<    011a    e<    011b
  #     L<    013d    l<    013e
  #     N<    0147    n<    0148
  #     R<    0158    r<    0159
  #     S<    0160    s<    0161
  #     T<    0164    t<    0165
  #     Z<    017d    z<    017e


  # Other characters


  # First character is below, 2nd character is above
  $$hash{"||"} = "\xa6";   #   Å¶
  $$hash{" :"} = "\xa8";   #   Å®
  $$hash{"-a"} = "\xaa";   #   Å™
  #$$hash{" -"}= "\xaf";   #   ÅØ   (narrow bar)
  $$hash{" -"} = "\xad";   #   Å≠   (wide bar)
  $$hash{" o"} = "\xb0";   #   Å∞
  $$hash{"-+"} = "\xb1";   #   Å±
  $$hash{" 1"} = "\xb9";   #   Åπ
  $$hash{" 2"} = "\xb2";   #   Å≤
  $$hash{" 3"} = "\xb3";   #   Å≥
  $$hash{" '"} = "\xb4";   #   Å¥
  $$hash{"-o"} = "\xba";   #   Å∫
  $$hash{" ."} = "\xb7";   #   Å∑
  $$hash{", "} = "\xb8";   #   Å∏
  $$hash{"Ao"} = "\xc5";   #   Å≈
  $$hash{"ao"} = "\xe5";   #   ÅÂ
  $$hash{"ox"} = "\xf0";   #   Å

  # upside down characters

  $$hash{"ud!"} = "\xa1";  #   Å°
  $$hash{"ud?"} = "\xbf";  #   Åø

  # overlay characters

  $$hash{"X o"} = "\xa4";  #   Å§
  $$hash{"Y ="} = "\xa5";  #   Å•
  $$hash{"S o"} = "\xa7";  #   Åß
  $$hash{"O c"} = "\xa9";  #   Å©    Copyright
  $$hash{"O R"} = "\xae";  #   ÅÆ
  $$hash{"D -"} = "\xd0";  #   Å–
  $$hash{"O /"} = "\xd8";  #   Åÿ
  $$hash{"o /"} = "\xf8";  #   Å¯

  # special names

  $$hash{"1/4"} = "\xbc";  #   Åº
  $$hash{"1/2"} = "\xbd";  #   ÅΩ
  $$hash{"3/4"} = "\xbe";  #   Åæ
  $$hash{"<<"}  = "\xab";  #   Å´
  $$hash{">>"}  = "\xbb";  #   Åª
  $$hash{"cent"}= "\xa2";  #   Å¢
  $$hash{"lb"}  = "\xa3";  #   Å£
  $$hash{"mu"}  = "\xb5";  #   Åµ
  $$hash{"beta"}= "\xdf";  #   Åﬂ
  $$hash{"para"}= "\xb6";  #   Å∂
  $$hash{"-|"}  = "\xac";  #   Å¨
  $$hash{"AE"}  = "\xc6";  #   Å∆
  $$hash{"ae"}  = "\xe6";  #   ÅÊ
  $$hash{"x"}   = "\xd7";  #   Å◊
  $$hash{"P"}   = "\xde";  #   Åﬁ
  $$hash{"/"}   = "\xf7";  #   Å˜
  $$hash{"p"}   = "\xfe";  #   Å~
}

# $hashref = &Date_Init_LANGUAGE;
#   This returns a hash containing all of the initialization for a
#   specific language.  The hash elements are:
#
#   @ month_name      full month names          January February ...
#   @ month_abb       month abbreviations       Jan Feb ...
#   @ day_name        day names                 Monday Tuesday ...
#   @ day_abb         day abbreviations         Mon Tue ...
#   @ day_char        day character abbrevs     M T ...
#
#   @ num_suff        number with suffix        1st 2nd ...
#   @ num_word        numbers spelled out       first second ...
#
#   $ now             words which mean now      now today ...
#   $ last            words which mean last     last final ...
#   $ each            words which mean each     each every ...
#   $ of              of (as in a member of)    in of ...
#                     ex.  4th day OF June
#   $ at              at 4:00                   at
#   $ on              on Sunday                 on
#   $ future          in the future             in
#   $ past            in the past               ago
#   $ next            next item                 next
#   $ prev            previous item             last previous
#
#   % offset          a hash of special dates   { tomorrow->0:0:0:1:0:0:0 }
#   % times           a hash of times           { noon->12:00:00 ... }
#
#   $ years           words for year            y yr year ...
#   $ months          words for month
#   $ weeks           words for week
#   $ days            words for day
#   $ hours           words for hour
#   $ minutes         words for minute
#   $ seconds         words for second
#   % replace
#       The replace element is quite important, but a bit tricky.  In
#       English (and probably other languages), one of the abbreviations
#       for the word month that would be nice is "m".  The problem is that
#       "m" matches the "m" in "minute" which causes the string to be
#       improperly matched in some cases.  Hence, the list of abbreviations
#       for month is given as:
#         "mon month months"
#       In order to allow you to enter "m", replacements can be done.
#       $replace is a list of pairs of words which are matched and replaced
#       AS ENTIRE WORDS.  Having $replace equal to "m"->"month" means that
#       the entire word "m" will be replaced with "month".  This allows the
#       desired abbreviation to be used.  Make sure that replace contains
#       an even number of words (i.e. all must be pairs).  Any time a
#       desired abbreviation matches the start of any other, it has to go
#       here.
#
#   $ exact           exact mode                exactly
#   $ approx          approximate mode          approximately
#   $ business        business mode             business
#
#   r sephm           hour/minute separator     (?::)
#   r sepms           minute/second separator   (?::)
#   r sepss           second/fraction separator (?:[.:])
#
#   Elements marked with an asterix (@) are returned as a set of lists.
#   Each list contains the strings for each element.  The first set is used
#   when the 7-bit ASCII (US) character set is wanted.  The 2nd set is used
#   when an international character set is available.  Both of the 1st two
#   sets should be complete (but the 2nd list can be left empty to force the
#   first set to be used always).  The 3rd set and later can be partial sets
#   if desired.
#
#   Elements marked with a dollar ($) are returned as a simple list of words.
#
#   Elements marked with a percent (%) are returned as a hash list.
#
#   Elements marked with (r) are regular expression elements which must not
#   create a back reference.
#
# ***NOTE*** Every hash element (unless otherwise noted) MUST be defined in
# every language.

sub Date_Init_English {
  print "DEBUG: Date_Init_English\n"  if ($Date::Manip::Debug =~ /trace/);
  my($d)=@_;
  

  $$d{"month_name"}=
    [["January","February","March","April","May","June",
      "July","August","September","October","November","December"]];

  $$d{"month_abb"}=
    [["Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"],
     [],
     ["","","","","","","","","Sept"]];

  $$d{"day_name"}=
    [["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]];
  $$d{"day_abb"}=
    [["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]];
  $$d{"day_char"}=
    [["M","T","W","Th","F","Sa","S"]];

  $$d{"num_suff"}=
    [["1st","2nd","3rd","4th","5th","6th","7th","8th","9th","10th",
      "11th","12th","13th","14th","15th","16th","17th","18th","19th","20th",
      "21st","22nd","23rd","24th","25th","26th","27th","28th","29th","30th",
      "31st"]];
  $$d{"num_word"}=
    [["first","second","third","fourth","fifth","sixth","seventh","eighth",
      "ninth","tenth","eleventh","twelfth","thirteenth","fourteenth",
      "fifteenth","sixteenth","seventeenth","eighteenth","nineteenth",
      "twentieth","twenty-first","twenty-second","twenty-third",
      "twenty-fourth","twenty-fifth","twenty-sixth","twenty-seventh",
      "twenty-eighth","twenty-ninth","thirtieth","thirty-first"]];

  $$d{"now"}     =["today","now"];
  $$d{"last"}    =["last","final"];
  $$d{"each"}    =["each","every"];
  $$d{"of"}      =["in","of"];
  $$d{"at"}      =["at"];
  $$d{"on"}      =["on"];
  $$d{"future"}  =["in"];
  $$d{"past"}    =["ago"];
  $$d{"next"}    =["next"];
  $$d{"prev"}    =["previous","last"];

  $$d{"exact"}   =["exactly"];
  $$d{"approx"}  =["approximately"];
  $$d{"business"}=["business"];

  $$d{"offset"}  =["yesterday","-0:0:0:1:0:0:0","tomorrow","+0:0:0:1:0:0:0"];
  $$d{"times"}   =["noon","12:00:00","midnight","00:00:00"];

  $$d{"years"}   =["y","yr","year","yrs","years"];
  $$d{"months"}  =["mon","month","months"];
  $$d{"weeks"}   =["w","wk","wks","week","weeks"];
  $$d{"days"}    =["d","day","days"];
  $$d{"hours"}   =["h","hr","hrs","hour","hours"];
  $$d{"minutes"} =["mn","min","minute","minutes"];
  $$d{"seconds"} =["s","sec","second","seconds"];
  $$d{"replace"} =["m","month"];

  $$d{"sephm"}   =':';
  $$d{"sepms"}   =':';
  $$d{"sepss"}   ='[.:]';
}

sub Date_Init_French {
  print "DEBUG: Date_Init_French\n"  if ($Date::Manip::Debug =~ /trace/);
  my($d)=@_;
  my(%h)=();
  &Char_8Bit(\%h);
  my($e)=$h{"e'"};
  my($u)=$h{"u^"};
  my($a)=$h{"a'"};

  $$d{"month_name"}=
    [["janvier","fevrier","mars","avril","mai","juin",
      "juillet","aout","septembre","octobre","novembre","decembre"],
     ["janvier","f$e"."vrier","mars","avril","mai","juin",
      "juillet","ao$u"."t","septembre","octobre","novembre","d$e"."cembre"]];
  $$d{"month_abb"}=
    [["jan","fev","mar","avr","mai","juin",
      "juil","aout","sept","oct","nov","dec"],
     ["jan","f$e"."v","mar","avr","mai","juin",
      "juil","ao$u"."t","sept","oct","nov","d$e"."c"]];

  $$d{"day_name"}=
    [["lundi","mardi","mercredi","jeudi","vendredi","samedi","dimanche"]];
  $$d{"day_abb"}=
    [["lun","mar","mer","jeu","ven","sam","dim"]];
  $$d{"day_char"}=
    [["l","ma","me","j","v","s","d"]];

  $$d{"num_suff"}=
    [["1er","2e","3e","4e","5e","6e","7e","8e","9e","10e",
      "11e","12e","13e","14e","15e","16e","17e","18e","19e","20e",
      "21e","22e","23e","24e","25e","26e","27e","28e","29e","30e",
      "31e"]];
  $$d{"num_word"}=
    [["premier","deux","trois","quatre","cinq","six","sept","huit","neuf",
      "dix","onze","douze","treize","quatorze","quinze","seize","dix-sept",
      "dix-huit","dix-neuf","vingt","vingt et un","vingt-deux","vingt-trois",
      "vingt-quatre","vingt-cinq","vingt-six","vingt-sept","vingt-huit",
      "vingt-neuf","trente","trente et un"],
     ["1re"]];

  $$d{"now"}     =["aujourd'hui","maintenant"];
  $$d{"last"}    =["dernier"];
  $$d{"each"}    =["chaque","tous les","toutes les"];
  $$d{"of"}      =["en","de"];
  $$d{"at"}      =["a",$a."0"];
  $$d{"on"}      =["sur"];
  $$d{"future"}  =["en"];
  $$d{"past"}    =["il y a"];
  $$d{"next"}    =["suivant"];
  $$d{"prev"}    =["precedent","pr$e"."c$e"."dent"];

  $$d{"exact"}   =["exactement"];
  $$d{"approx"}  =["approximativement"];
  $$d{"business"}=["professionel"];

  $$d{"offset"}  =["hier","-0:0:0:1:0:0:0","demain","+0:0:0:1:0:0:0"];
  $$d{"times"}   =["midi","12:00:00","minuit","00:00:00"];

  $$d{"years"}   =["an","annee","ans","annees","ann$e"."e","ann$e"."es"];
  $$d{"months"}  =["mois"];
  $$d{"weeks"}   =["sem","semaine"];
  $$d{"days"}    =["j","jour","jours"];
  $$d{"hours"}   =["h","heure","heures"];
  $$d{"minutes"} =["mn","min","minute","minutes"];
  $$d{"seconds"} =["s","sec","seconde","secondes"];
  $$d{"replace"} =["m","mois"];

  $$d{"sephm"}   ='[h:]';
  $$d{"sepms"}   =':';
  $$d{"sepss"}   ='[.:,]';
}

sub Date_Init_Swedish {
  print "DEBUG: Date_Init_Swedish\n"  if ($Date::Manip::Debug =~ /trace/);
  my($d)=@_;

  $$d{"month_name"}=
    [["Januari","Februari","Mars","April","Maj","Juni",
      "Juli","Augusti","September","Oktober","November","December"]];
  $$d{"month_abb"}=
    [["Jan","Feb","Mar","Apr","Maj","Jun",
      "Jul","Aug","Sep","Okt","Nov","Dec"]];

  $$d{"day_name"}=
    [["Mondag","Tisdag","Onsdag","Torsdag","Fredag","Lurdag","Sundag"]];
  $$d{"day_abb"}=
    [["Mon","Tis","Ons","Tor","Fre","Lur","Sun"]];
  $$d{"day_char"}=
    [["M","Ti","O","To","F","Lu","S"]];

  $$d{"num_suff"}=
    [["1:a","2:a","3:e","4:e","5:e","6:e","7:e","8:e","9:e","10:e",
      "11:e","12:e","13:e","14:e","15:e","16:e","17:e","18:e","19:e","20:e",
      "21:a","22:a","23:e","24:e","25:e","26:e","27:e","28:e","29:e","30:e",
      "31:a"]];
  $$d{"num_word"}=
    [["fursta","andra","tredje","fjarde","femte","sjatte","sjunde",
      "ottonde","nionde","tionde","elte","tolfte","trettonde","fjortonde",
      "femtonde","sextonde","sjuttonde","artonde","nittonde","tjugonde",
      "tjugofursta","tjugoandra","tjugotredje","tjugofjarde","tjugofemte",
      "tjugosjatte","tjugosjunde","tjugoottonde","tjugonionde",
      "trettionde","trettiofursta"]];

  $$d{"now"}     =["idag","nu"];
  $$d{"last"}    =["furra","senaste"];
  $$d{"each"}    =["every","each"];
  $$d{"of"}      =["om"];
  $$d{"at"}      =["kl","kl.","klockan"];
  $$d{"on"}      =["on"];
  $$d{"future"}  =["in"];
  $$d{"past"}    =["ago"];
  $$d{"next"}    =["next"];
  $$d{"prev"}    =["previous","last"];

  $$d{"exact"}   =["exactly"];
  $$d{"approx"}  =["approximately"];
  $$d{"business"}=["business"];

  $$d{"offset"}  =["igor","-0:0:0:1:0:0:0","imorgon","+0:0:0:1:0:0:0"];
  $$d{"times"}   =["noon","12:00:00","midnight","00:00:00"];

  $$d{"years"}   =["o","or"];
  $$d{"months"}  =["mon","monad","monader"];
  $$d{"weeks"}   =["w","wk","week","weeks"];
  $$d{"days"}    =["d","dag","dagar"];
  $$d{"hours"}   =["t","tim","timme","timmar"];
  $$d{"minutes"} =["mn","min","minut","minuter"];
  $$d{"seconds"} =["s","sek","sekund","sekunder"];
  $$d{"replace"} =["m","monad"];

  $$d{"sephm"}   ='[.:]';
  $$d{"sepms"}   =':';
  $$d{"sepss"}   ='[.:]';
}

sub Date_Init_German {
  print "DEBUG: Date_Init_German\n"  if ($Date::Manip::Debug =~ /trace/);
  my($d)=@_;
  my(%h)=();
  &Char_8Bit(\%h);
  my($a)=$h{"a:"};
  my($u)=$h{"u:"};
  my($o)=$h{"o:"};
  my($b)=$h{"beta"};

  $$d{"month_name"}=
    [["Januar","Februar","Maerz","April","Mai","Juni",
      "Juli","August","September","Oktober","November","Dezember"],
    ["J$a"."nner","Februar","M$a"."rz","April","Mai","Juni",
      "Juli","August","September","Oktober","November","Dezember"]];
  $$d{"month_abb"}=
    [["Jan","Feb","Mar","Apr","Mai","Jun",
      "Jul","Aug","Sep","Okt","Nov","Dez"],
     ["J$a"."n","Feb","M$a"."r","Apr","Mai","Jun",
      "Jul","Aug","Sep","Okt","Nov","Dez"]];

  $$d{"day_name"}=
    [["Montag","Dienstag","Mittwoch","Donnerstag","Freitag","Samstag",
      "Sonntag"]];
  $$d{"day_abb"}=
    [["Mon","Die","Mit","Don","Fre","Sam","Son"]];
  $$d{"day_char"}=
    [["M","Di","Mi","Do","F","Sa","So"]];

  $$d{"num_suff"}=
    [["1","2","3","4","5","6","7","8","9","10",
      "11","12","13","14","15","16","17","18","19","20",
      "21","22","23","24","25","26","27","28","29","30",
      "31"]];
  $$d{"num_word"}=
    [
     ["erste","zweite","dritte","vierte","funfte","sechste","siebente",
      "achte","neunte","zehnte","elfte","zwolfte","dreizehnte","vierzehnte",
      "funfzehnte","sechzehnte","siebzehnte","achtzehnte","neunzehnte",
      "zwanzigste","einundzwanzigste","zweiundzwanzigste","dreiundzwanzigste",
      "vierundzwanzigste","funfundzwanzigste","sechundzwanzigste",
      "siebundzwanzigste","achtundzwanzigste","neunundzwanzigste",
      "dreibigste","einunddreibigste"],
     ["erste","zweite","dritte","vierte","f$u"."nfte","sechste","siebente",
      "achte","neunte","zehnte","elfte","zw$o"."lfte","dreizehnte",
      "vierzehnte","f$u"."nfzehnte","sechzehnte","siebzehnte","achtzehnte",
      "neunzehnte","zwanzigste","einundzwanzigste","zweiundzwanzigste",
      "dreiundzwanzigste","vierundzwanzigste","f$u"."nfundzwanzigste",
      "sechundzwanzigste","siebundzwanzigste","achtundzwanzigste",
      "neunundzwanzigste","drei$b"."igste","einunddrei$b"."igste"],
    ["erster"]];

  $$d{"now"}     =["heute","jetzt"];
  $$d{"last"}    =["letzte"];
  $$d{"each"}    =["jeden"];
  $$d{"of"}      =["der","im","des"];
  $$d{"at"}      =["zu"];
  $$d{"on"}      =["am"];
  $$d{"future"}  =["in"];
  $$d{"past"}    =["vor"];
  $$d{"next"}    =["nachste","n$a"."chste"];
  $$d{"prev"}    =["letzte"];

  $$d{"exact"}   =["genau"];
  $$d{"approx"}  =["ungefahr","ungef$a"."hr"];
  $$d{"business"}=["Arbeitstag"];

  $$d{"offset"}  =["gestern","-0:0:0:1:0:0:0","morgen","+0:0:0:1:0:0:0"];
  $$d{"times"}   =["mittag","12:00:00","mitternacht","00:00:00"];

  $$d{"years"}   =["j","Jahr","Jahre"];
  $$d{"months"}  =["Monat","Monate"];
  $$d{"weeks"}   =["w","Woche","Wochen"];
  $$d{"days"}    =["t","Tag","Tage"];
  $$d{"hours"}   =["h","std","Stunde","Stunden"];
  $$d{"minutes"} =["min","Minute","Minuten"];
  $$d{"seconds"} =["s","sek","Sekunde","Sekunden"];
  $$d{"replace"} =["m","Monat"];

  $$d{"sephm"}   =':';
  $$d{"sepms"}   ='[: ]';
  $$d{"sepss"}   ='[.:]';
}

########################################################################
# FROM MY PERSONAL LIBRARIES
########################################################################

no integer;

#++ ModuloAddition :: Num.pl
#!! ModuloAddition
# &ModuloAddition($N,$add,\$val,\$rem);
#   This calculates $val=$val+$add and forces $val to be in a certain range.
#   This is useful for adding numbers for which only a certain range is
#   allowed (for example, minutes can be between 0 and 59 or months can be
#   between 1 and 12).  The absolute value of $N determines the range and
#   the sign of $N determines whether the range is 0 to N-1 (if N>0) or
#   1 to N (N<0).  The remainder (as modulo N) is added to $rem.
#   Example:
#     To add 2 hours together (with the excess returned in days) use:
#       &ModuloAddition(60,$s1,\$s,\$day);
#!!
#&& ModuloAddition
sub ModuloAddition {
  my($N,$add,$val,$rem)=@_;
  return  if ($N==0);
  $$val+=$add;
  if ($N<0) {
    # 1 to N
    $N = -$N;
    if ($$val>$N) {
      $$rem+= int(($$val-1)/$N);
      $$val = ($$val-1)%$N +1;
    } elsif ($$val<1) {
      $$rem-= int(-$$val/$N)+1;
      $$val = $N-(-$$val % $N);
    }

  } else {
    # 0 to N-1
    if ($$val>($N-1)) {
      $$rem+= int($$val/$N);
      $$val = $$val%$N;
    } elsif ($$val<0) {
      $$rem-= int(-($$val+1)/$N)+1;
      $$val = ($N-1)-(-($$val+1)%$N);
    }
  }
}
#&&

#++ IsInt :: Num.pl
#!! IsInt
# $Flag=&IsInt($String [,$low, $high]);
#    Returns 1 if $String is a valid integer, 0 otherwise.  If $low
#    and $high are entered, the integer must be in that range.
#!!
#&& IsInt
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
#&&

#++ SinLindex :: Index.pl
#!! SinLindex
# $Pos=&SinLindex(\@List,$Str [,$Offset [,$CaseInsensitive]]);
#    Searches for an exact string in a list.
#
#    This is similar to RinLindex except that it searches for elements
#    which are exactly equal to $Str (possibly case insensitive).
#!!
#&& SinLindex
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
#&&

#++ Index_First :: Index.pl
#&& Index_First
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
#&&

#++ CleanFile :: Path.pl
#!! CleanFile
# $File=&CleanFile($file);
#   This cleans up a path to remove the following things:
#     double slash       /a//b  -> /a/b
#     trailing dot       /a/.   -> /a
#     leading dot        ./a    -> a
#     trailing slash     a/     -> a
#!!
#&& CleanFile
sub CleanFile {
  my($file)=@_;
  $file =~ s/\s*$//;
  $file =~ s/^\s*//;
  $file =~ s|//+|/|g;  # multiple slash
  $file =~ s|/\.$|/|;  # trailing /. (leaves trailing slash)
  $file =~ s|^\./||    # leading ./
    if ($file ne "./");
  $file =~ s|/$||      # trailing slash
    if ($file ne "/");
  return $file;
}
#&&

#++ ExpandTilde :: Path.pl
#!! ExpandTilde
# $File=&ExpandTilde($file);
#   This checks to see if a "~" appears as the first character in a path.
#   If it does, the "~" expansion is interpreted (if possible) and the full
#   path is returned.  If a "~" expansion is used but cannot be
#   interpreted, an empty string is returned.  CleanFile is called.
#!!
#&& ExpandTilde
sub ExpandTilde {
  my($file)=shift;
  my($user)=();
  my($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell)=();
  # ~aaa/bbb=      ~  aaa      /bbb
  if ($file =~ m% ^~ ([^\/]*) (\/.*)? %x) {
    ($user,$file)=($1,$2);
    # Single user operating systems (Mac, MSWindows) don't have the getpwnam
    # and getpwuid routines defined.  Try to catch various different ways
    # of knowing we are on one of these systems:
    return ""  if (defined $^O and
                   $^O =~ /MacOS/i ||
                   $^O =~ /MSWin32/i ||
                   $^O =~ /Windows_95/i ||
                   $^O =~ /Windows_NT/i);
    return ""  if (defined $ENV{OS} and
                   $ENV{OS} =~ /MacOS/i ||
                   $ENV{OS} =~ /MSWin32/i ||
                   $ENV{OS} =~ /Windows_95/i ||
                   $ENV{OS} =~ /Windows_NT/i);
    $user=""  if (! defined $user);
    $file=""  if (! defined $file);
    if ($user) {
      ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell)=
        getpwnam($user);
    } else {
      ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell)=
        getpwuid($<);
    }
    return ""  if (! $dir);

    $file="$dir/$file";
  }
  return &CleanFile($file);
}
#&&

#++ FullFilePath :: Path.pl
#!! FullFilePath
# $File=&FullFilePath($file);
#   Returns the full path to $file.  Returns an empty string if a "~"
#   expansion cannot be interpreted.  The path does not need to exist.
#   CleanFile is called.
#!!
#&& FullFilePath
sub FullFilePath {
  my($file)=shift;
  $file=&ExpandTilde($file);
  return ""  if (! $file);
  $file=cwd . "/$file"  if ($file !~ m|^/|);   # $file = "a/b/c"
  return &CleanFile($file);
}
#&&

#++ CheckFilePath :: Path.pl
#!! CheckFilePath
# $Flag=&CheckFilePath($file [,$mode]);
#   Checks to see if $file exists, to see what type it is, and whether
#   the script can access it.  If it exists and has the correct mode, 1
#   is returned.
#
#   $mode is a string which may contain any of the valid file test operator
#   characters except t, M, A, C.  The appropriate test is run for each
#   character.  For example, if $mode is "re" the -r and -e tests are both
#   run.
#
#   An empty string is returned if the file doesn't exist.  A 0 is returned
#   if the file exists but any test fails.
#
#   All characters in $mode which do not correspond to valid tests are
#   ignored.
#!!
#&& CheckFilePath
sub CheckFilePath {
  my($file,$mode)=@_;
  my($test)=();
  $file=&FullFilePath($file);
  $mode = ""  if (! defined $mode);

  # Run tests
  return 0  if (! defined $file or ! $file);
  return 0  if ((                  ! -e $file) or
                ($mode =~ /r/  &&  ! -r $file) or
                ($mode =~ /w/  &&  ! -w $file) or
                ($mode =~ /x/  &&  ! -x $file) or
                ($mode =~ /R/  &&  ! -R $file) or
                ($mode =~ /W/  &&  ! -W $file) or
                ($mode =~ /X/  &&  ! -X $file) or
                ($mode =~ /o/  &&  ! -o $file) or
                ($mode =~ /O/  &&  ! -O $file) or
                ($mode =~ /z/  &&  ! -z $file) or
                ($mode =~ /s/  &&  ! -s $file) or
                ($mode =~ /f/  &&  ! -f $file) or
                ($mode =~ /d/  &&  ! -d $file) or
                ($mode =~ /l/  &&  ! -l $file) or
                ($mode =~ /s/  &&  ! -s $file) or
                ($mode =~ /p/  &&  ! -p $file) or
                ($mode =~ /b/  &&  ! -b $file) or
                ($mode =~ /c/  &&  ! -c $file) or
                ($mode =~ /u/  &&  ! -u $file) or
                ($mode =~ /g/  &&  ! -g $file) or
                ($mode =~ /k/  &&  ! -k $file) or
                ($mode =~ /T/  &&  ! -T $file) or
                ($mode =~ /B/  &&  ! -B $file));
  return 1;
}
#&&

#++ FixPath :: Path.pl
#!! FixPath
# $Path=&FixPath($path [,$full] [,$mode] [,$error]);
#   Makes sure that every directory in $path (a colon separated list of
#   directories) appears as a full path or relative path.  All "~"
#   expansions are removed.  All trailing slashes are removed also.  If
#   $full is non-nil, relative paths are expanded to full paths as well.
#
#   If $mode is given, it may be either "e", "r", or "w".  In this case,
#   additional checking is done to each directory.  If $mode is "e", it
#   need ony exist to pass the check.  If $mode is "r", it must have have
#   read and execute permission.  If $mode is "w", it must have read,
#   write, and execute permission.
#
#   The value of $error determines what happens if the directory does not
#   pass the test.  If it is non-nil, if any directory does not pass the
#   test, the subroutine returns the empty string.  Otherwise, it is simply
#   removed from $path.
#
#   The corrected path is returned.
#!!
#&& FixPath
sub FixPath {
  my($path,$full,$mode,$err)=@_;
  local($_)="";
  my(@dir)=split(/:/,$path);
  $full=0  if (! defined $full);
  $mode="" if (! defined $mode);
  $err=0   if (! defined $err);
  $path="";
  if ($mode eq "e") {
    $mode="de";
  } elsif ($mode eq "r") {
    $mode="derx";
  } elsif ($mode eq "w") {
    $mode="derwx";
  }

  foreach (@dir) {

    # Expand path
    if ($full) {
      $_=&FullFilePath($_);
    } else {
      $_=&ExpandTilde($_);
    }
    if (! $_) {
      return ""  if ($err);
      next;
    }

    # Check mode
    if (! $mode  or  &CheckFilePath($_,$mode)) {
      $path .= ":$_";
    } else {
      return "" if ($err);
    }
  }
  $path =~ s/^://;
  return $path;
}
#&&

#++ SearchPath :: Path.pl
#!! SearchPath
# $File=&SearchPath($file,$path [,$mode] [,@suffixes]);
#   Searches through directories in $path for a file named $file.  The
#   full path is returned if one is found, or an empty string otherwise.
#   The file may exist with one of the @suffixes.  The mode is checked
#   similar to &CheckFilePath.
#
#   The first full path that matches the name and mode is returned.  If none
#   is found, an empty string is returned.
#!!
#&& SearchPath
sub SearchPath {
  my($file,$path,$mode,@suff)=@_;
  my($f,$s,$d,@dir,$fs)=();
  $path=&FixPath($path,1,"r");
  @dir=split(/:/,$path);
  foreach $d (@dir) {
    $f="$d/$file";
    $f=~ s|//|/|g;
    return $f if (&CheckFilePath($f,$mode));
    foreach $s (@suff) {
      $fs="$f.$s";
      return $fs if (&CheckFilePath($fs,$mode));
    }
  }
  return "";
}
#&&

#++ ReturnList :: Num.pl
#!! ReturnList
# @list=&ReturnList($str);
#    This takes a string which should be a comma separated list of integers
#    or ranges (5-7).  It returns a sorted list of all integers referred to
#    by the string, or () if there is an invalid element.
#
#    Negative integers are also handled.  "-2--1" is equivalent to "-2,-1".
#!!
#&& ReturnList
sub ReturnList {
  my($str)=@_;
  my(@ret,@str,$from,$to,$tmp)=();
  @str=split(/,/,$str);
  foreach $str (@str) {
    if ($str =~ /^[-+]?\d+$/) {
      push(@ret,$str);
    } elsif ($str =~ /^([-+]?\d+)-([-+]?\d+)$/) {
      ($from,$to)=($1,$2);
      if ($from>$to) {
        $tmp=$from;
        $from=$to;
        $to=$tmp;
      }
      push(@ret,$from..$to);
    } else {
      return ();
    }
  }
  @ret;
}
#&&

1;
