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
);
use strict;
use integer;
use Carp;
use Cwd;
use IO::File;

#use POSIX qw(tzname);

########################################################################
# HISTORY
########################################################################
# Important changes marked with *** (as of 5.20)

# Written by:
#    Sullivan Beck (sbeck@cise.ufl.edu)
# Any suggestions, bug reports, or donations :-) should be sent to me.

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
#    Included ideas from packages
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
#    Added DateCalc
#
# Version 4.2  10/23/95
#    UnixDate will now return a scalar or list depending on context
#    ParseDate/ParseDateDelta will now take a scalar, a reference to a
#       scalar, or a eference to an array
#    Added copyright notice (requested by Tim Bunce <Tim.Bunce@ig.co.uk>)
#    Simple timezone handling
#    Added Date_SetTime, Date_GetPrev, Date_GetNext
#
# Version 4.3  10/26/95
#    Added "which dofw in mmm" formats to ParseDate
#    Added a bugfix of Adam Nevins where "12:xx pm" used to be parsed
#        "24:xx:00".
#
# Version 5.00  06/21/96
#    Switched to a package (patch supplied by Peter Bray
#       <pbray@ind.tansu.com.au>)
#       o  renamed to Date::Manip
#       o  changed version number to 2 decimal places
#       o  added POD documentation
#       Thanks to Peter Bray, Randal Schwartz, Andreas Koenig for suggestions
#    Fixed a bug pointed out by Peter Bray where it was complaining of
#       an uninitialized variable.
#
# Version 5.01  06/24/96
#    Fixes suggested by Rob Perelman <robp@electriciti.com>
#       o  Fixed a typo (Friday misspelled Fridat)
#       o  Documentation problem for \$err in DateCalc
#       o  Added %F formtat to UnixDate
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
#    Declared package variables to avoid warning "Identifier XXX used
#       only once".  Thanks to Peter Bray for the suggestion.
#
# Version 5.04  08/01/96
#    Added support for fractional seconds (as generated by Sybase).  They
#       are parsed and ignored.  Added by Kurt Stephens
#       <stephens@il.us.swissbank.com>.
#    Fixed bugs reported by J.B. Nicholson-Owens
#       <jbn@mystery-train.cu-online.com>
#       o  "Tue Jun 25 1996" wasn't parsed correctly (regexp was case
#          sensitive)
#       o  full day names not parsed correctly
#       o  the default day in ErrorCheck should be 1, NOT currd since when
#          currd>28, it may not be a valid date for the month
#
# Version 5.05  10/11/96
#    Added Swedish translation (thanks to Andreas Johansson
#       <Andreas.XS.Johansson@trab.se>
#    Fixed bad mistake in documentation (use Date::Manip instead of
#       use DateManip) pointed out by tuc@valhalla.stormking.com
#    Fixed bug introduced in 5.04 when default day set to 1.  When no
#       date given, have day default to today rather than 1.  It only
#       defaults to one if a partial date is given.
#    Changed deltas to be all positive or all negative when produced by
#       DateCalc.  Suggested by Steve Braun <braun@gandalf.sp.trw.com>
#    Fixed bug where Date_DaysSince999 returned the wrong value (the
#       error did not affect any other functions in Date::Manip due to
#       the way it was called and the nature of the error).  Pointed out
#       by Jason Baker <bm11455@themis.ag.gov.bc.ca>.
#    Minor improvements to documentation.
#    Documented the 'sort within a sort' bug.
#    Added DateManipVersion routine.
#    Dates with commas in them are now read properly.
#    Now supports timezones.
#    Parses RFC 822 dates (thanks to J.B. Nicholson-Owens
#       <jbn@mystery-train.cu-online.com> for suggestion).
#    Parses ctime() date formats (suggested by Matthew R. Sheahan
#       <chaos@crystal.palace.net>).
#    Added Date_ConvTZ routine for timezone support.
#    Fixed two places where a variable was declared twice using my (thanks
#       to Ric Steinberger <ric@isl.sri.com>).
#    Hopefully fixed installation problems.
#    Now supports times like "noon" and "midnight".
#    Got rid of the last (I think) couple of US specific strings.
#    The time separators are now language specific so the French can
#       write "10h30" and the Swedes can write "10.30".  Suggested by
#       Andreas Johansson <Andreas.XS.Johansson@trab.se>.
#    Fixed type in documentation/README pointed out by James K. Bence
#       <jbence@math.ucla.edu>.
#    Fixed bug in Date_SetTime (didn't work with $hr,$min,$sec < 10).
#    Added ModuloAddition routine and simplified DateCalc.
#    Date_TimeZone will now also check `date '+%Z'` suggested by
#       Aharon Schkolnik <aharon@healdb.matat.health.gov.il>.
#
# Version 5.06  10/25/96
#    Fixed another two places where a variable was declared twice using my
#       (thanks to Ric Steinberger <ric@isl.sri.com>).
#    Fixed a bug where fractional seconds weren't parsed correctly.
#    Fixed a bug where "noon" and other special times were not parsed
#       in the "which day of month" formats.
#    Added "today at time" formats.
#    Fixed a minor bug where a few matches were case sensitive.
#    ParseDateDelta now normalizes the delta as well as DateCalc.
#    Added %Q format "YYYYMMDD" to UnixDate.  Requested by Rob Perelman
#       <robp@electriciti.com>.
#    The command "date +%Z" doesn't work on SunOS machines (and perhaps
#        others) so 5.05 is effectively broken.  5.06 released to fix this.
#        Reported by Rob Perelman <robp@electriciti.com>.
#
# Version 5.07  12/10/96
#    Huge number of code changes to clean things up.
#    Added %q format "YYYYMMDDHHMMSS" to UnixDate.  Requested by Rob Perelman
#       <robp@electriciti.com>.  Also added %P format "YYYYMMDDHH:MM:SS".
#    Added a new config variable to allow you to work with multiple internal
#       formats (with and without colons).  Requested by Rob Perelman
#       <robp@electriciti.com>.  See Date_Init documentation.
#    Added the following formats suggested by Andreas Johansson
#       <Andreas.XS.Johansson@trab.se>:
#          sunday week 22 [in 1996] [at 12:00]
#          22nd sunday [in 1996] [at 12:00]
#          sunday 22nd week [in 1996] [at 12:00]
#    Added weeks to ParseDateDelta.  Suggested by Mike Bassman
#       <mbassman@fia21-43.fiadev21.lehman.com>.  Note that since
#       this is a late addition, I did not change the internal format
#       of a delta.  Instead, it is added to the days field.
#    Added a new config variable to allow you to define the first day of
#       the week.  See Date_Init documentation.
#    Added the following formats to ParseDate for conveniance (some were
#       suggested by Mike Bassman <mbassman@fia21-43.fiadev21.lehman.com>):
#          next/last friday [at time]
#          next/last week [at time]
#          in 2 weeks [at time]
#          2 weeks ago [at time]
#          Friday in 2 weeks
#          in 2 weeks on friday
#          Friday 2 weeks ago
#          2 weeks ago friday
#    Added Date_SecsSince1970GMT, moved the %s format to %o (secs since 1/1/70)
#       and added %s format (secs since 1/1/70 GMT).  Based on suggestions by
#       Mark Osbourne <marko@lexis-nexis.com>.  Note this introduces a minor
#       backward incompatibility!
#    Date_SetTime now works with international time separators.
#    Changed how Date_Init arguments work.
#    Fixed bug in Date_TimeZone where it didn't recognize +HHMN type time
#       zones.  Thanks to Are Bryne <are.bryne@communique.no>.
#    Added the %g format (%a, %d %b %Y %H:%M:%S %z) for an RFC 1123 date.
#       Suggested by Are Bryne <are.bryne@communique.no>.
#    Added WindowsNT check to Date_TimeZone to get around NT's weird date
#       command.  Thanks to Are Bryne <are.bryne@communique.no>.
#    Subroutines now check to see if 4 digit years are entered.  Suggested
#       by Are Bryne <are.bryne@communique.no>.
#    Fixed typo (CSD instead of CST).
#    Now reads a config file.
#    Added options to delete existing holidays and ignore global config file.
#    The d:h:mn:s of ALL deltas are normalized.
#    Added local($_) to all routines which use $_.  Suggested by Rob
#       Perelman <robp@electriciti.com>.
#    Date_GetNext and Date_GetPrev now return the next/prev occurence of a
#       time as well as a day.  Suggested by Are Bryne
#       <are.bryne@communique.no>.
#    Complete rewrite of DateCalc.
#    In approximate mode, deltas now come out completely normalized (only 1
#       sign).  Suggested by Rob Perelman <robp@electriciti.com>.
#    Added business mode.  See documentation.  Suggested by Mike Bassman
#       <mbassman@fia21-43.fiadev21.lehman.com>.
#    Modified how deltas are normalized and added the DeltaSigns config
#       variable.
#    Added test suite!
#    Fixed sign in military timezones making Date::Manip RFC 1123 compliant
#       (except that timezone information is not stored in any format)
#    Added Date::Manip::InitDone so initialization isn't duplicated.
#    Added a 3rd internal format to store YYYY-MM-DD HH:MN:SS (iso 8601).
#    Fixed a bug where UnixDate %E format didn't work with single digit
#       dates.  Patch supplied by J\yrgen N\yrgaard <jnp@www.ifs.dk>.
#    Added a config variable to allow you to work with 24 hour business
#       days.  Suggested by Mike Bassman
#       <mbassman@fia21-43.fiadev21.lehman.com>.
#    ParseDateDelta now returns "" rather than "+0:0:0:0:0:0" when there is
#       an error.
#    Fixed a bug where "today" was not converted to the correct timezone.
#
# Version 5.07p2  01/03/97
#    Added lots of timezone abbreviations.
#    Can now understand PST8PDT type zones (but only in Date_TimeZone).
#    Fixed some tests (good for another year).
#    Fixed a bug where a delta component of "-0" would mess things up.
#       Reported by Nigel Chapman <nigel@macavon.demon.co.uk>.
#    Released two patches for 5.07.
#
# Version 5.08  01/24/97
#    Fixed serious bug in ConvTZ pointed out by David Hall
#       <dhall@sportsline.com>.
#    Modified Date_ConvTZ (and documented it).
#    Released 5.08 to get this and the other two patches into circulation.
#
# Version 5.09  01/28/97
#    Upgraded to 5.003_23 and fixed one problem associated with it.
#    Used carp and changed all die's to confess.
#    Replaced some UNIX commands with perl equivalents (date with localtime
#       in the tests, pwd with cwd in the path routines).
#    Cleaned up all routines working with the path.
#    Tests work again (broke in 5.08).  Thanks to Alex Lewin <lewin@vgi.com>,
#       and Michael Fuhr <mfuhr@blackhole.dimensional.com> for running
#       debugging tests.
#
# Version 5.10  03/19/97
#    Tests will now run regardless of the timezone you are in.
#    Test will always read the DateManip.cnf file in t/ now.
#    A failed test will now give slightly more information.
#    Cleaned up In, At, and On regexps.
#    DateManip.cnf file in t/ now sets ALL options to override any changes
#       made in the Manip.pm file.
#    Added documentation for backwards incompatibilities to POD.
#    Added 2 checks for MSWin32 (date command and getpw* didn't work).  Thanks
#       to Alan Humphrey <alanh@velleb.com>.
#    Fixed two bugs in the DateCalc routines.  Pointed out by Kevin Baker
#       <ol@twics.com>
#    Fixed some problems in POD documentation.  Thanks to Marvin Solomon
#       <solomon@cs.wisc.edu>.
#    Fixed some problems with how "US/Eastern" type timezones were used.
#       Thanks to Marvin Solomon <solomon@cs.wisc.edu>.
#    Fixed minor POD error pointed out by John Perkins <john@cs.wisc.edu>.
#    Added a check for Windows_95.  Thanks to charliew@atfppc.ppc.att.com.
#    Changed documentation for Date_IsWorkDay (it was quite confusing using
#       a variable named $time).  Thanks to Erik M. Schwartz
#       <eriks@library.nrl.navy.mil>.
#    Cleaned up checks for MacOS and Microsoft OS's.  Hopefully I'm catching
#       everything.  Thanks to Charlie Wu <charwu@ibm.net> for one more check.
#    Fixed typo in docs (midnight mispelled).  Thanks to Timothy Kimball
#       <kimball@stsci.edu>.
#    Fixed a typo which broke Time%Date (Date=dd%mmm%yy) format.  Thanks to
#       Timothy Kimball <kimball@stsci.edu>.
#
# Version 5.11  08/07/97
#    Added one more check for NT perl.  Thanks to Rodney Haywood
#       <rodos@hotspace.net>
#    Added METDST timezone.  Thanks to Paul Gillingwater
#       <p.gillingwater@iaea.org>
#    Added CEST timezone.  Thanks to Rosella Antonio <antonio.rosella@agip.it>
#    Added some comments to help me keep my personal libraries up-to-date
#       with respect to Date::Manip and vice-versa.
#    Fixed a bug which showed up in French dates (though it could happen in
#       other languages as well).  Thanks to Georges Martin
#       <georges.martin@deboeck.be>.
#    Added ROK timezone.  Thanks to Kang Taewook <twkang@www.netcenter.co.kr>
#    Fixed a bug in DateCalc.  Thanks to Thomas Winzig <tsw@pvo.com>
#    Removed the "eval" statement from CheckFilePath which causes a suid
#       c wrapper program to die when it calls a Date::Manip script.
#       Thanks to Hank Hughes <thigpen@ccs.neu.edu>
#    Fixed a bug in business mode calculations.  Thanks to Sterling Swartwout
#       <sterling_swartwout@urgentmail.com>
#    Fixed a bug in which "1997023100:00:00" was accepted as valid.  Thanks
#       to Doug Emerald <emerald@reston.ans.net>.
#    Fixed a bug in which ConvTZ was not used correctly in ParseDate.  Redid
#       portions of Date_ConvTZ.  Thanks to Vivek Khera <khera@kci.kciLink.com>
#    Fixed a bug in business mode calculations.  Thanks to Ian Duplisse
#       <duplisse@rentwks1.golden.csc.com>
#    Added $^X check for Win95 perl.  Thanks to Walter.Soldierer@t-online.de
#       <Walter Soldierer>
#    Missed one call to NormalizeDelta so the output was wrong.  Thanks to
#       Brad A. Buikema <babuike@sandia.gov>
#    Version 5.11 was never released to CPAN.
#
# Version 5.20  10/12/97
#    Reorganized ParseDate more efficiently.
#    Fixed some incorrect uses of $in instead of $future in ParseDate.
#       Thanks to Erik Corry <erik@arbat.com>
#    Added formats:
#       *** All ISO 8601 formats
#       "Friday"    suggested by Rob Perelman <robp@electriciti.com>
#       "12th"      suggested by Rob Perelman <robp@electriciti.com>
#       12th (12th day of current month)
#       "last day of MONTH"  suggested by Chadd Westhoff <CWESTHOFF@cyprus.com>
#    Added ParseDateString for speed (and simplicity for modifying ParseDate)
#    Changed all week handling to meet ISO 8601 standards.
#    Added %J and %K formats to UnixDate.
#    Added some speedups (more to come).
#    Cleaned up testing mechanism a bit and added tests for ISO 8601 formats.
#    Added Date_DaysInMonth.
#
# Version 5.21  01/15/98
#    Documented how to get around Micro$oft problem.  Based on a mail by
#       Patrick Stepp <stepp@adelphia.net>
#    Now passes Taint checks.  Thanks to Mike Fuhr <Fuhr.Mike@tci.com>,
#       Ron E. Nelson <rnelson@mpr.org>, and Jason L Tibbitts III
#       <tibbs@hpc.uh.edu>
#    Put everything in a "use integer" pragma.
#    Added YYtoYYYY variable.  Suggested by Michel van der List
#       <vanderlistmj@sbphrd.com>
#    Added a missing space in the %g UnixDate format.  Thanks to Mike Booth
#       <booth@bohr.pha.jhu.edu>
#    Fixed some Australian time zones.  Kim Davies <kim@cynosure.com.au>
#    Removed all mandatory call to Date_Init (only called when current time
#       is required).  Significantly faster.
#    Added the UpdateCurrTZ variable to increase speed at the cost of being
#       wrong on the timezone.
#    Cleaned up multi-lingual initialization and added the IntCharSet
#       variable.
#    Improved French translations.  Thanks to Emmanuel Bataille
#       <ebat@micronet.fr>
#    Fixed a bug in Date_ConvTZ.
#    Fixed another bug in Date_ConvTZ.  Thanks to Patrick K Malone
#       <malone@bighorn.sdvc.uwyo.edu>
#    Added "Sept" as a recognized abbreviation.  Thanks to Martin Thurn
#       <mthurn@copper.irnet.rest.tasc.com>
#    Added British date formats.  Piran Montford <piran@cogapp.com>
#       monday week
#       today week
#       as well as some US formats
#       in 2 months
#       next month
#    Time can now be written 5pm.  Piran Montford <piran@cogapp.com>
#    Added the TomorrowFirst variable and Date_NearestWorkDay function.
#    Fixed a bug in Date_IsWorkDay.
#    Typo in the French initialization.  Thanks to Michel Minsoul
#       <minsoul@segi.ulg.ac.be>
#    Fixed how %W and %U was incorrectly stored between weeks 52,53,01.
#       They now return the correct week (no more week 00).  Added UnixDate
#       formats %G and %L to correctly handle the year.  Samuli Karkkainen
#       <skarkkai@kelloseppakoulu.fi>
#    Added ForceDate variable.
#    Fixed the tests to not fail in 1998.
#
# Version 5.30  01/20/98
#    *** Added a week field to deltas.
#    All routines can now take either a 2- or 4-digit year.
#    Added Delta_Format.  First suggested by Alan Burlison
#       <aburlison@cix.compulink.co.uk>
#    Added Date_SetDateField.  Martin Thurn <mthurn@copper.irnet.rest.tasc.com>
#    Made the $err argument to DateCalc optional.
#    Changed the name of several of the library routines (not the callable
#       ones) to standardize naming.
#    *** Added ParseRecur.  First suggested by Chris Jackson
#       <chrisj@biddeford.com>


# Backwards incompatibilities
#
# In 5.07
#   %s UnixDate format changed
#   By default, the signs of a diff are stored in a different format (only
#     minimum number of signs stored).  Backwards compatible if you set
#     DeltaSigns=1.
#   Date_Init arguments changed (old method supported but depreciated)
#
# In 5.20
#   ISO 8601 dates added, several old formats are no longer available
#     MM-DD-YY  (conflicts with YY-MM-DD)
#     YYMMDD    (conflicts with YYYYMM)
#   In keeping with ISO 8601, the weekdays are now numbered 1-7 (mon-sun)
#     instead of 0-6 (sun-sat).
#   Also for ISO 8601, the week starts with Monday by default.
#   By default, the first week of the year contains Jan 4 (ISO 8601).
#
# In 5.21
#   Long running process timezone may slip.  See UpdateCurrTZ variable.
#   UnixDate formats %W,%U no longer return week 00.  %J is now correct.
#
# In 5.30
#   Delta now contains a week field.

$Date::Manip::VERSION="5.30";

########################################################################
# TODO
########################################################################

### MISC

# Make work weeks able to start and stop on arbitrary days (even across
# weekends).

# Add the other ISO8601 stuff.

# The only change needed to get it to work under 5.001 is to change the line:
#    $file=cwd . "/$file"  if ($file !~ m|^/|);   # $file = "a/b/c"
# to:
#    $file=&getcwd . "/$file"  if ($file !~ m|^/|);   # $file = "a/b/c"
# Since this also may eliminate a shell command (`pwd`), add a flag to
# switch between the two.  Piran Montford <piran@cogapp.com>

# Add 15/Oct/1997:07:56:43 (netscape log) suggested by:
#  bugaj@dnrc.bell-labs.com  Stephan Vladimir Bugaj

# Try to get rid of `date` in Date_TimeZone
# Also, Cwd::cwd calls `pwd` (Bowen Dwelle) , but this may be inevitable.
# If not, add a variable which will allow you to skip the sections where
#    backticks are used since they are a performance sink.  Suggested by
#    Bowen Dwelle.

# Combine GetNext and GetPrev (?)

# Add a "SPECIAL HOLIDAY" section to fully specify holidays so weird ones
# can be defined for each year.  Add Easter calculations here as well:
#   Easter = easter
# means that Easter is calculated using the method easter.

# Add
#   Spanish
#   German
#   Italian
#   Japanese (Kevin Baker will help)

# Fill in some of the language variables ($past, $future, $zones).

# Check Swedish/French special characters.

# Change EXPORT to EXPORT_OK (message 9 by Peter Bray)

# Add ParseDateTemplate where a template containing any of the formats
# from UnixDate may be used in a string (which may contain perl REs)
# to parse a very strange date.

### TESTS

# Add tests for all the new ParseDate formats to the test suite.

### GRANULARITY

# $flag=&Date_GranularityTest($date,$base,$granularity [,$flags] [$width])
#    $date and $base are dates
#    $granularity and $width are deltas
#    $flags is a list of flags
#
#    To test if a day is one of every other Friday (starting at Friday
#    Feb 7, 1997), go:
#       $base=&ParseDate("Friday Feb 7 1997");
#       $date=&ParseDate("...");
#       $granularity=&ParseDateDelta("+ 2 weeks");
#       $flag=&Date_Granularity($date,$base,$granularity,"exact");
#    If $flag is 1, the $date is a 2nd Friday from Feb 7.
#
#    The most important field in $granularity is the last non-zero element.
#    In the above example, 2 weeks returns the delta 0:0:14:0:0:0 so the
#    last non-zero element is days with a value of 14.
#
#    If $flags is empty, $date is checked to see if it occurs some multiple
#    of 14 days before or after $base.  In this case, hourse, minutes, and
#    seconds are completely ignored.
#
#    If $flags contains the words "before" or "after", $date must come
#    before or after $base.
#
#    If $flags contains any other options, or if $width is passed in, the
#    test is treated in an approximate way.  A flag of "approx" forces this
#    behavior.
#
#    If $width is not passed in in an approximate comparison, it defaults
#    to 1 in the last non-zero element.  Here, the default width is 1 day.
#    If the flag "half" is used, the width (default or passed in) is
#    halved.
#
#    For example if $width is 1 day, add a multiple of $granularity to
#    $base to get as close to $date as possible.  If $date is within plus
#    or minus 1 day of this new base, the test is successful.  A flag of
#    "plus" or "minus" means that $date must be with plus 1 day or within
#    minus one day of this new base.  Flags of "before" or "after" work
#    as well.

# @list=&Date_GranularityList($date,$N,$granularity)
#    Returns a list of $N dates AFTER $date which are created by adding
#    $granularity to $date $N times.  If $N<0, it returns $N dates BEFORE
#    $date (the list is in chronological order).
#
#    Make it work in business mode as well which will return only working
#    days.  Example, every other friday and it can be told that if friday
#    falls on a holiday to return either thursday or the following monday
#    or leave it out.

### DAYLIGHT SAVINGS TIME

# Use POSIX tzset/tzname (and perhaps GNU date) to handle timezone and
# daylight savings time correctly.  See messages by Marvin Soloman.

# If ignoring TIMEZONE info, treat all dates as in current timezone with
# no d.s.t. effects (i.e. Jun 1 12:00 EDT == Jun 1 12:00 EST).

# To do calculations, convert to current timezone (Jun 1 12:00 EDT -> Jun 1
# 11:00 EST even if that date doesn't really exist)

# Determine zone pairings EST/EDT, PST/PDT for all zones.  Store EST#EDT in
# $Date::Manip::TZ rather than just EST or EDT.  Make sure everything is
# paired up.  Places with only a single timezone should work as well.

# Make a 2nd hash where EST -> EST#EDT for all timezones.

# When doing date calculations, if neither date has a time (or if both are
# at the exact same time and are in the same timezone or in timezones
# related through daylight savings time such as EST and EDT), ignore the
# time gain/loss from savings time transitions IFF the variable IgnoreDST
# is on (it is by default).  Otherwise, do the calculation exactly.

# Add an option to all date calculations to ignore daylight savings time
# transitions.

### TIMEZONES

# It is just too confusing knowing what timezone you are working it.  I
# give up.  Change the internal format to YYYYMMDDHH:MN:SS+HHMN or
# YYYYMMDDHH:MN::SS-HHMN
# By default, convert all dates to current timezone however unless a
# NOCONV option is set.

# Add a Date_Compare to compare two dates (with timezone).

# Modify all routines accordingly.

### SPEEDUPS

# UpdateHolidays, don't use ParseDate to parse dates of form DD/MM or MM/DD.

# In business mode date-date calculations, add a "quick" mode in which the
# number of business days is estimated by:
#     $date1 = &ParseDate("...");
#     $date2 = &ParseDate("...");         # a 2nd date a long time after date1
#     $delta = &DateCalc($date1,$date2);  # get an exact delta
#     $days  = ( split(/:/,$delta) )[2];  # the number of days between the two
#     $yrs   = $days/365.24;              # the number of years between the two
#     $days  = $days*(5/7) - $yrs*9;
# where 9 is the number of holidays in the year.  Add a variable to turn this
# behavior off and another to tell what threshold to apply this to (by default
# apply it to anything 2 months apart or more).  In this mode, only days are
# returned, hours, minutes, seconds are ignored.

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

  my($lang,$tmp,@tmp,%tmp,@tmp2,
     $i,$j,$a,$b,$now,$offset,$in,$at,$on,@tmp3,
     @mon,@month,
     @w,@wk,@week,
     $days,$am,$pm,
     $zones,$zonesrfc,@zones,$sephm,$sepms,$sepss)=();

  if (! $Date::Manip::Init) {
    $Date::Manip::Init=1;

    # Set the following variables based on the language.  They should all
    # be capitalized correctly, and any spaces appearing in the string
    # should be replaced with an underscore (_) (they will be correctly
    # parsed as spaces).

    #  $am,$pm  : different ways of expressing AM (PM), the first one in each
    #             list is the one that will be used when printing out an AM
    #             or PM string
    #  $now     : string containing words referring to now
    #  $zones   : a space separated string containing additional timezone
    #             strings (beyond the RFC 822 zones) along with their
    #             translatrion.  So, the string "EST -0500 EDT -0400"
    #             contain two time zones, EST and EDT, which have offsets
    #             of -0500 and -0400 respectively from Universal Time.
    #  $sephm   : the separator used between the hours and minutes of a time
    #  $sepms   : the separator used between the minutes and seconds of a time
    #  $sepss   : the separator used between seconds and fractional seconds
    #             NOTE:  all three of the separators can be any format suitable
    #             for a regular expression PROVIDED it does not create a
    #             back-reference.  For example, in french, the hour/minute
    #             separator might be a colon or the letter h.  This would be
    #             defined as (?::|h) or [:h] but NOT as (:|h) since the latter
    #             produces a back-reference.  Also, the dot "." should be
    #             defined as '\.' since it is in a regular expression.
    #
    # One other variable to set is $offset.  This contains a space separated
    # set of dates which are defined as offsets from the current time.
    #
    # If a string contains spaces, replace the space(s) with underscores.

    if ($Date::Manip::Language eq "English") {
      $lang=&Date_Init_English();

      $am="AM";
      $pm="PM";

      $now="today now";
      $offset="yesterday -0:0:0:1:0:0:0 tomorrow +0:0:0:1:0:0:0";

      $sephm=':';
      $sepms=':';
      $sepss='[.:]';
      $zones="";

    } elsif ($Date::Manip::Language eq "Swedish") {
      $lang=&Date_Init_Swedish();

      $am="FM";
      $pm="EM";

      $now="idag nu";
      $offset="igor -0:0:0:1:0:0:0 imorgon +0:0:0:1:0:0:0";
      $sephm='[:.]';
      $sepms=':';
      $sepss='[.:]';
      $zones="";

    } elsif ($Date::Manip::Language eq "French") {
      $lang=&Date_Init_French();

      $am="du_matin";  # le matin
      $pm="du_soir";   # le soir

      $now="aujourd'hui maintenant";
      $offset="hier -0:0:0:1:0:0:0 demain +0:0:0:1:0:0:0";
      $sephm='(?::|h)';
      $sepms=':';
      $sepss='(?:\.|:|,)';

      $zones="";

      # } elsif ($Date::Manip::Language eq "Danish") {
      # } elsif ($Date::Manip::Language eq "Spanish") {
      # } elsif ($Date::Manip::Language eq "Italian") {
      # } elsif ($Date::Manip::Language eq "Portugese") {
      # } elsif ($Date::Manip::Language eq "German") {
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
    &Date_InitLists([$$lang{"month_name"},$$lang{"month_abb"}],
                    \$Date::Manip::MonExp,"lc,sort,back",
                    [\@Date::Manip::Month,\@Date::Manip::Mon],
                    [\%Date::Manip::Month,1]);

    # Date::Manip:: variables for day of week
    #   $WkExp  : "(mon|monday|tue|tuesday ... )"
    #   @W      : ("M","T",...)
    #   @Wk     : ("Mon","Tue",...)
    #   @Week   : ("Monday","Tudesday",...)
    #   %Week   : ("monday",1,"mon",1,"m",1,...)
    &Date_InitLists([$$lang{"day_name"},$$lang{"day_abb"}],
                    \$Date::Manip::WkExp,"lc,sort,back",
                    [\@Date::Manip::Week,\@Date::Manip::Wk],
                    [\%Date::Manip::Week,1]);
    &Date_InitLists([$$lang{"day_char"}],
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
    &Date_InitLists([$$lang{"num_suff"},$$lang{"num_word"}],
                    \$Date::Manip::DayExp,"lc,sort,back",
                    [\@Date::Manip::Day,\@tmp],
                    [\%Date::Manip::Day,1]);
    @tmp=@{ $$lang{"last"} };
    &Date_InitStrings($$lang{"last"},\$Date::Manip::LastExp,"lc,sort");
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
    &Date_InitStrings($$lang{"each"},\$Date::Manip::EachExp,"lc,sort");

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
    &Date_InitStrings($$lang{"years"}  ,\$Date::Manip::YExp,"lc,sort");
    &Date_InitStrings($$lang{"months"} ,\$Date::Manip::MExp,"lc,sort");
    &Date_InitStrings($$lang{"weeks"}  ,\$Date::Manip::WExp,"lc,sort");
    &Date_InitStrings($$lang{"days"}   ,\$Date::Manip::DExp,"lc,sort");
    &Date_InitStrings($$lang{"hours"}  ,\$Date::Manip::HExp,"lc,sort");
    &Date_InitStrings($$lang{"minutes"},\$Date::Manip::MnExp,"lc,sort");
    &Date_InitStrings($$lang{"seconds"},\$Date::Manip::SExp,"lc,sort");
    &Date_InitHash($$lang{"replace"},undef,"lc",\%Date::Manip::Replace);

    # Date::Manip:: variables for special dates that are offsets from now
    #    $Now      : "(now|today)"
    #    $Offset   : "(yesterday|tomorrow)"
    #    %Offset   : ("yesterday","-1:0:0:0",...)
    #    $TimesExp : "(noon|midnight)"
    #    %Times    : ("noon","12:00:00","midnight","00:00:00")
    &Date_InitHash($$lang{"times"},\$Date::Manip::TimesExp,"lc,sort,back",
                   \%Date::Manip::Times);
    $Date::Manip::Now=   &Date_Regexp($now,"lc,back,under");
    ($Date::Manip::Offset,%Date::Manip::Offset)=
      &Date_Regexp($offset,"lc,under,back","keys");
    $Date::Manip::SepHM=$sephm;
    $Date::Manip::SepMS=$sepms;
    $Date::Manip::SepSS=$sepss;

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
      &Date_Regexp("$zonesrfc $zones","sort,lc,under,back",
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
    &Date_InitStrings($$lang{"at"},\$Date::Manip::At,"lc,sort");
    &Date_InitStrings($$lang{"on"},\$Date::Manip::On,"lc,sort");
    &Date_InitStrings($$lang{"future"},\$Date::Manip::Future,"lc,sort");
    &Date_InitStrings($$lang{"past"},\$Date::Manip::Past,"lc,sort");
    &Date_InitStrings($$lang{"next"},\$Date::Manip::Next,"lc,sort");
    &Date_InitStrings($$lang{"prev"},\$Date::Manip::Prev,"lc,sort");
    &Date_InitStrings($$lang{"of"},\$Date::Manip::Of,"lc,sort");

    # Date::Manip:: calc mode variables
    #    $Approx  : "(?:approximately)"
    #    $Exact   : "(?:exactly)"
    #    $Business: "(?:business)"
    &Date_InitStrings($$lang{"exact"},\$Date::Manip::Exact,"lc,sort");
    &Date_InitStrings($$lang{"approx"},\$Date::Manip::Approx,"lc,sort");
    &Date_InitStrings($$lang{"business"},\$Date::Manip::Business,"lc,sort");

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
  &Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk);
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
    my($zone)='\s+'.$Date::Manip::ZoneExp.
      '(?:\s+|$)';                          # \s+(edt|est|...)\s+
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

    my($time)="$hm$DD(?:$ms$DD$FS)?(?:\\s*$ampmexp)?";

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

    # Remove the time
    $iso=1;
    if (/$D$time/i || /$ampmexp/i) {
      $iso=0;
      $tmp=0;
      $tmp=1  if (/$time$zone2?\s*$/i);
      $tmp=0  if (/$ampmexp/i);
      if (s/(^|[^a-z])$at\s*$D$time$zone/$1 /i  ||
          s/(^|[^a-z])$at\s*$D$time$zone2?/$1 /i  ||
          s/(^|[^0-9$hm])(\d)$time$zone/$1 /i ||
          s/(^|[^0-9$hm])(\d)$time$zone2?/$1 /i ||
          s/()$DD$time$zone/ /i ||
          (s/()$DD$time$zone2?/ /i and (($iso=$tmp) || 1))  ||
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
        &Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk), last PARSE
          if (/^\s*$/);
      }
    }
    $time=0  if ($time ne "1");
    s/\s+$//;
    s/^\s+//;

    # Parse ISO 8601 dates now
    if ( ( $iso  ||  /^[0-9]+(W[0-9]+)?$/ ) and
         /^[0-9-]+(?:W[0-9-]+)?$/i ) {
      # ISO 8601 dates
      s,-, ,g;            # Change all ISO8601 seps to spaces
      s/^\s+//;
      s/\s+$//;

      if (/^$D4\s*$DD\s*$DD\s*$DD(?:$DD(?:$DD\d*)?)?$/  ||
          /^$DD\s+$DD\s*$DD\s*$DD(?:$DD(?:$DD\d*)?)?$/) {
        # ISO 8601 Dates with times
        #    YYYYMMDDHHMNSSFFFF
        #    YYYYMMDDHHMNSS
        #    YYYYMMDDHHMN
        #    YYYYMMDDHH
        #    YY MMDDHHMNSSFFFF
        #    YY MMDDHHMNSS
        #    YY MMDDHHMN
        #    YY MMDDHH
        ($y,$m,$d,$h,$mn,$s)=($1,$2,$3,$4,$5,$6);
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

      } elsif (/^(\d{4})\s*(\d{3})$/ ||
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
        return ""  if (&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
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
            if (&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
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

      } elsif (/^$now$/i) {
        # now, today
        &Date_Init()  if (! $Date::Manip::UpdateCurrTZ);
        $date=$Date::Manip::Curr;
        if ($time) {
          return ""
            if (&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
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
            if (&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
          $date=&Date_SetTime($date,$h,$mn,$s);
        }
        last PARSE;

      } else {
        return "";
      }
    }
  }

  if (! $date) {
    return ""  if (&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
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
    if (s/$signexp?$numexp?(:($signexp?$numexp)?){1,6}$//) {
      $colon=$&;
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
      $colon[$i] =~ /^$signexp$numexp/;
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
    while ($format) {
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
  return ""  if (&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk));
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
  $h+= $m/60;
  $m-= ($m/60)*60;
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
    if ($delta =~ /^([+-]?0+:){6}[+-]?0+/ and $Date::Manip::DeltaSigns);
  return "+0:0:0:0:0:0:0" if ($delta =~ /^([+-]?0+:){6}[+-]?0+/);

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

  $s += ($d+7*$w)*$len*60 + $h*3600 + $m*60; # convert w/d/h/m to s
  $sign2="+";
  if ($s<0) {
    $s*=-1;
    $sign2="-";
  }

  $m  = $s/60;                           # convert s to m
  $s -= $m*60;
  $d  = $m/$len;                         # convert m to d
  $m -= $d*$len;
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

# $flag=&Date_ErrorCheck(\$y,\$m,\$d,\$h,\$mn,\$s,\$ampm,\$wk);
#   Returns 1 if any of the fields are bad.  All fields are optional, and
#   all possible checks are done on the data.  If a field is not passed in,
#   it is set to default values.  If data is missing, appropriate defaults
#   are supplied.
#
#   If the flag Date::Manip::UpdateHolidays is set, the year is set to
#   Date::Manip::CurrHolidayYear.
sub Date_ErrorCheck {
  print "DEBUG: Date_ErrorCheck\n"  if ($Date::Manip::Debug =~ /trace/);
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
  $$h=""     if (! defined $$h);
  $$mn=""    if (! defined $$mn);
  $$s=""     if (! defined $$s);
  $$ampm=""  if (! defined $$ampm);
  $$ampm=uc($$ampm)  if ($$ampm);
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

# &Date_NthDayOfYear($y,$n);
#   Returns a list of (YYYY,MM,DD) for the Nth day of the year.
sub Date_NthDayOfYear {
  print "DEBUG: Date_NthDayOfYear\n"  if ($Date::Manip::Debug =~ /trace/);
  my($y,$n)=@_;
  my($m,$d)=();
  $y=$Date::Manip::CurrY  if (! defined $y  or  ! $y);
  $n=1       if (! defined $n  or  $n eq "");
  $n+=0;     # to turn 023 into 23
  return ()  if ($n<0  ||  $n>366);
  $y=&Date_FixYear($y)  if (length($y)<4);

  my(@d_in_m)=(31,28,31,30,31,30,31,31,30,31,30,31);
  $d_in_m[1]=29  if (&Date_LeapYear($y));

  $m=$d=0;
  while ($n>0) {
    $m++;
    if ($n<=$d_in_m[0]) {
      $d=$n;
      $n=0;
    } else {
      $n-= $d_in_m[0];
      shift(@d_in_m);
    }
  }
  ($y,$m,$d);
}

########################################################################
# LANGUAGE INITIALIZATION
########################################################################

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
#     num_word        numbers spelled out       first second ...
#
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
#       The replace element is quite important.  In English (and probably
#       other languages), one of the abbreviations for the word month that
#       would be nice is "m".  The problem is that "m" matches the "m" in
#       "minute" which causes the string to be improperly matched in some
#       cases.  Hence, the list of abbreviations for month is given as:
#         "mon month months"
#       In order to allow you to enter "m", replacements can be done.
#       $replace is a list of pairs of words which are matched and replaced
#       AS ENTIRE WORDS.  Having $replace equal to "m"->"month" means that
#       the entire word "m" will be replaced with "month".  This allows the
#       desired abbreviation to be used.  Make sure that replace contains
#       an even number of words (i.e. all must be pairs).
#
#   $ exact           exact mode                exactly
#   $ approx          approximate mode          approximately
#   $ business        business mode             business
#
#   Elements marked with an asterix (@) are returned as a set of lists.
#   Each list contains the strings for each element.  The first set is used
#   when the 7-bit ASCII (US) character set is wanted.  The 2nd set is used
#   when an international character set is available.  Be sure that if the
#   2nd set is used, it is complete.  It can be left empty and a partial
#   3rd set used if desired.
#
#   Elements marked with a dollar ($) are returned as a simple list of words.
#
#   Elements marked with a percent (%) are returned as a hash list.
#
# 8-bit international characters can be gotten by "\xXX".  I don't know
# how to get 16-bit characters.
#   grave       !  slants up and left (`)
#     A!    00c0     a!    00e0
#     E!    00c8     e!    00e8
#     I!    00cc     i!    00ec
#     O!    00d2     o!    00f2
#     U!    00d9     u!    00f9
#     W!    1e80     w!    1e81
#     Y!    1ef2     y!    1ef3
#   acute       '  slants up and right
#   dble acute  "
#     A'    00c1     a'    00e1
#     C'    0106     c'    0107
#     E'    00c9     e'    00e9
#     I'    00cd     i'    00ed
#     L'    0139     l'    013a
#     N'    0143     n'    0144
#     O"    0150     o"    0151
#     O'    00d3     o'    00f3
#     R'    0154     r'    0155
#     S'    015a     s'    015b
#     U"    0170     u"    0171
#     U'    00da     u'    00fa
#     W'    1e82     w'    1e83
#     Y'    00dd     y'    00fd
#     Z'    0179     z'    017a
#   circumflex  >  hat (^)
#     A>    00c2     a>    00e2
#     C>    0108     c>    0109
#     E>    00ca     e>    00ea
#     G>    011c     g>    011d
#     H>    0124     h>    0125
#     I>    00ce     i>    00ee
#     J>    0134     j>    0135
#     O>    00d4     o>    00f4
#     S>    015c     s>    015d
#     U>    00db     u>    00fb
#     W>    0174     w>    0175
#     Y>    0176     y>    0177
#   tilde       ?  squiggly line (~)
#     A?    00c3    a?    00e3
#     I?    0128    i?    0129
#     N?    00d1    n?    00f1
#     O?    00d5    o?    00f5
#     U?    0168    u?    0169
#   macron      -  bar above
#     A-    0100    a-    0101
#     E-    0112    e-    0113
#     I-    012a    i-    012b
#     O-    014c    o-    014d
#     U-    016a    u-    016b
#   breve       (  half circle up
#     A(    0102    a(    0103
#     G(    011e    g(    011f
#     U(    016c    u(    016d
#   dot         .  dot above
#     C.    010a    c.    010b
#     E.    0116    e.    0117
#     G.    0120    g.    0121
#     I.    0130
#     Z.    017b    z.    017c
#   diaeresis   :  side by side dots
#     A:    00c4    a:    00e4
#     E:    00cb    e:    00eb
#     I:    00cf    i:    00ef
#     O:    00d6    o:    00f6
#     U:    00dc    u:    00fc
#     W:    1e84    w:    1e85
#     Y:    0178    y:    00ff
#   ring        0  ring above
#     U0    016e    u0    016f
#   cedilla     ,  squiggle down and left below the letter
#     C,    00c7    c,    00e7
#     G,    0122    g,    0123
#     K,    0136    k,    0137
#     L,    013b    l,    013c
#     N,    0145    n,    0146
#     R,    0156    r,    0157
#     S,    015e    s,    015f
#     T,    0162    t,    0163
#   ogonek      ;  squiggle down and right below the letter
#     A;    0104    a;    0105
#     E;    0118    e;    0119
#     I;    012e    i;    012f
#     U;    0172    u;    0173
#   caron       <  little v on top
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
#
# ***NOTE*** Every hash element (unless otherwise noted) MUST be defined in
# every language.

sub Date_Init_English {
  print "DEBUG: Date_Init_English\n"  if ($Date::Manip::Debug =~ /trace/);
  my(%d)=();
  $d{"month_name"}=
    [["January","February","March","April","May","June",
      "July","August","September","October","November","December"]];

  $d{"month_abb"}=
    [["Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"],
     [],
     ["","","","","","","","","Sept"]];

  $d{"day_name"}=
    [["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]];
  $d{"day_abb"}=
    [["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]];
  $d{"day_char"}=
    [["M","T","W","Th","F","Sa","S"]];

  $d{"num_suff"}=
    [["1st","2nd","3rd","4th","5th","6th","7th","8th","9th","10th",
      "11th","12th","13th","14th","15th","16th","17th","18th","19th","20th",
      "21st","22nd","23rd","24th","25th","26th","27th","28th","29th","30th",
      "31st"]];
  $d{"num_word"}=
    [["first","second","third","fourth","fifth","sixth","seventh","eighth",
      "ninth","tenth","eleventh","twelfth","thirteenth","fourteenth",
      "fifteenth","sixteenth","seventeenth","eighteenth","nineteenth",
      "twentieth","twenty-first","twenty-second","twenty-third",
      "twenty-fourth","twenty-fifth","twenty-sixth","twenty-seventh",
      "twenty-eighth","twenty-ninth","thirtieth","thirty-first"]];

  $d{"last"}    =["last","final"];
  $d{"each"}    =["each","every"];
  $d{"of"}      =["in","of"];
  $d{"at"}      =["at"];
  $d{"on"}      =["on"];
  $d{"future"}  =["in"];
  $d{"past"}    =["ago"];
  $d{"next"}    =["next"];
  $d{"prev"}    =["previous","last"];

  $d{"exact"}   =["exactly"];
  $d{"approx"}  =["approximately"];
  $d{"business"}=["business"];

  $d{"times"}   =["noon","12:00:00","midnight","00:00:00"];

  $d{"years"}   =["y","yr","year","yrs","years"];
  $d{"months"}  =["mon","month","months"];
  $d{"weeks"}   =["w","wk","wks","week","weeks"];
  $d{"days"}    =["d","day","days"];
  $d{"hours"}   =["h","hr","hrs","hour","hours"];
  $d{"minutes"} =["mn","min","minute","minutes"];
  $d{"seconds"} =["s","sec","second","seconds"];
  $d{"replace"} =["m","month"];

  \%d;
}

sub Date_Init_French {
  print "DEBUG: Date_Init_French\n"  if ($Date::Manip::Debug =~ /trace/);
  my(%d)=();
  my(@tmp)=();

  $d{"month_name"}=
    [["janvier","fevrier","mars","avril","mai","juin",
      "juillet","aout","septembre","octobre","novembre","decembre"],
     ["janvier","f\xe9vrier","mars","avril","mai","juin",
      "juillet","ao\xfbt","septembre","octobre","novembre","d\xe9cembre"]];
  $d{"month_abb"}=
    [["jan","fev","mar","avr","mai","juin",
      "juil","aout","sept","oct","nov","dec"],
     ["jan","fev","mar","avr","mai","juin",
      "juil","ao\xfbt","sept","oct","nov","dec"]];

  $d{"day_name"}=
    [["lundi","mardi","mercredi","jeudi","vendredi","samedi","dimanche"]];
  $d{"day_abb"}=
    [["lun","mar","mer","jeu","ven","sam","dim"]];
  $d{"day_char"}=
    [["l","ma","me","j","v","s","d"]];

  $d{"num_suff"}=
    [["1er","2e","3e","4e","5e","6e","7e","8e","9e","10e",
      "11e","12e","13e","14e","15e","16e","17e","18e","19e","20e",
      "21e","22e","23e","24e","25e","26e","27e","28e","29e","30e",
      "31e"]];
  $d{"num_word"}=
    [["premier","deux","trois","quatre","cinq","six","sept","huit","neuf",
      "dix","onze","douze","treize","quatorze","quinze","seize","dix-sept",
      "dix-huit","dix-neuf","vingt","vingt et un","vingt-deux","vingt-trois",
      "vingt-quatre","vingt-cinq","vingt-six","vingt-sept","vingt-huit",
      "vingt-neuf","trente","trente et un"],
     ["1re"]];

  $d{"last"}    =["dernier"];
  $d{"each"}    =["chaque","tout les","toute les","toutes les"];
  $d{"of"}      =["en","de"];
  $d{"at"}      =["a","\xe0"];
  $d{"on"}      =["sur"];
  $d{"future"}  =["en"];
  $d{"past"}    =["il y a"];
  $d{"next"}    =["suivant"];
  $d{"prev"}    =["precedent","pr\xe9c\xe9dent"];

  $d{"exact"}   =["exactement"];
  $d{"approx"}  =["approximativement"];
  $d{"business"}=["professionel"];

  $d{"times"}   =["noon","12:00:00","midnight","00:00:00"];

  $d{"years"}   =["an","annee","ans","annees","ann\xe9e","ann\xe9es"];
  $d{"months"}  =["mois"];
  $d{"weeks"}   =["sem","semaine"];
  $d{"days"}    =["j","jour","jours"];
  $d{"hours"}   =["h","heure","heures"];
  $d{"minutes"} =["mn","min","minute","minutes"];
  $d{"seconds"} =["s","sec","seconde","secondes"];
  $d{"replace"} =["m","mois"];

  \%d;
}

sub Date_Init_Swedish {
  print "DEBUG: Date_Init_Swedish\n"  if ($Date::Manip::Debug =~ /trace/);
  my(%d)=();
  $d{"month_name"}=
    [["Januari","Februari","Mars","April","Maj","Juni",
      "Juli","Augusti","September","Oktober","November","December"]];
  $d{"month_abb"}=
    [["Jan","Feb","Mar","Apr","Maj","Jun",
      "Jul","Aug","Sep","Okt","Nov","Dec"]];

  $d{"day_name"}=
    [["Mondag","Tisdag","Onsdag","Torsdag","Fredag","Lurdag","Sundag"]];
  $d{"day_abb"}=
    [["Mon","Tis","Ons","Tor","Fre","Lur","Sun"]];
  $d{"day_char"}=
    [["M","Ti","O","To","F","Lu","S"]];

  $d{"num_suff"}=
    [["1:a","2:a","3:e","4:e","5:e","6:e","7:e","8:e","9:e","10:e",
      "11:e","12:e","13:e","14:e","15:e","16:e","17:e","18:e","19:e","20:e",
      "21:a","22:a","23:e","24:e","25:e","26:e","27:e","28:e","29:e","30:e",
      "31:a"]];
  $d{"num_word"}=
    [["fursta","andra","tredje","fjarde","femte","sjatte","sjunde",
      "ottonde","nionde","tionde","elte","tolfte","trettonde","fjortonde",
      "femtonde","sextonde","sjuttonde","artonde","nittonde","tjugonde",
      "tjugofursta","tjugoandra","tjugotredje","tjugofjarde","tjugofemte",
      "tjugosjatte","tjugosjunde","tjugoottonde","tjugonionde",
      "trettionde","trettiofursta"]];

  $d{"last"}    =["furra","senaste"];
  $d{"each"}    =["every","each"];
  $d{"of"}      =["om"];
  $d{"at"}      =["kl","kl.","klockan"];
  $d{"on"}      =["on"];
  $d{"future"}  =["in"];
  $d{"past"}    =["ago"];
  $d{"next"}    =["next"];
  $d{"prev"}    =["previous","last"];

  $d{"exact"}   =["exactly"];
  $d{"approx"}  =["approximately"];
  $d{"business"}=["business"];

  $d{"times"}   =["noon","12:00:00","midnight","00:00:00"];

  $d{"years"}   =["o","or"];
  $d{"months"}  =["mon","monad","monader"];
  $d{"weeks"}   =["w","wk","week","weeks"];
  $d{"days"}    =["d","dag","dagar"];
  $d{"hours"}   =["t","tim","timme","timmar"];
  $d{"minutes"} =["mn","min","minut","minuter"];
  $d{"seconds"} =["s","sek","sekund","sekunder"];
  $d{"replace"} =["m","monad"];

  \%d;
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

########################################################################
########################################################################
# POD
########################################################################
########################################################################

=head1 NAME

Date::Manip - date manipulation routines

=head1 SYNOPSIS

 use Date::Manip;

 $date=&ParseDate(\@args)
 $date=&ParseDate($string)
 $date=&ParseDate(\$string)

 @date=&UnixDate($date,@format)
 $date=&UnixDate($date,@format)

 $delta=&ParseDateDelta(\@args)
 $delta=&ParseDateDelta($string)
 $delta=&ParseDateDelta(\$string)

 @str=&Delta_Format($delta,$dec,@format)
 $str=&Delta_Format($delta,$dec,@format)

 $recur=&ParseRecur($string,$base,$date0,$date1,$flags)
 @dates=&ParseRecur($string,$base,$date0,$date1,$flags)

 $d=&DateCalc($d1,$d2 [,$errref] [,$del])

 $date=&Date_SetTime($date,$hr,$min,$sec)
 $date=&Date_SetTime($date,$time)

 $date=&Date_SetDateField($date,$field,$val [,$nocheck])

 $date=&Date_GetPrev($date,$dow,$today,$hr,$min,$sec)
 $date=&Date_GetPrev($date,$dow,$today,$time)

 $date=&Date_GetNext($date,$dow,$today,$hr,$min,$sec)
 $date=&Date_GetNext($date,$dow,$today,$time)

 &Date_Init()
 &Date_Init("VAR=VAL",...)

 $version=&DateManipVersion

 $flag=&Date_IsWorkDay($date [,$flag]);

 $date=&Date_NextWorkDay($date,$off [,$time]);
 $date=&Date_PrevWorkDay($date,$off [,$time]);

The following routines are used by the above routines (though they can also
be called directly).  $y may be entered as either a 2 or 4 digit year (it
will be converted to a 4 digit year based on the variable YYtoYYYY
described below).  Month and day should be numeric in all cases.  Most (if
not all) of the information below can be gotten from UnixDate which is
really the way I intended it to be gotten, but there are reasons to use
these (these are significantly faster).

 $day=&Date_DayOfWeek($m,$d,$y)
 $secs=&Date_SecsSince1970($m,$d,$y,$h,$mn,$s)
 $secs=&Date_SecsSince1970GMT($m,$d,$y,$h,$mn,$s)
 $days=&Date_DaysSince999($m,$d,$y)
 $day=&Date_DayOfYear($m,$d,$y)
 $days=&Date_DaysInYear($y)
 $wkno=&Date_WeekOfYear($m,$d,$y,$first)
 $flag=&Date_LeapYear($y)
 $day=&Date_DaySuffix($d)
 $tz=&Date_TimeZone()

=head1 DESCRIPTION

This is a set of routines designed to make any common date/time
manipulation easy to do.  Operations such as comparing two times,
calculating a time a given amount of time from another, or parsing
international times are all easily done.  From the very beginning, the main
focus of Date::Manip has been to be able to do ANY desired date/time
operation easily, not necessarily quickly.  There are other modules that
can do a small subset of the operations available in Date::Manip much
quicker than those presented here, so if speed is a primary issue, you
should look elsewhere.  But for sheer flexibility, I believe that
Date::Manip is your best bet.

Date::Manip deals with time as it is presented the Gregorian calendar (the
one currently in use).  The Julian calendar defined leap years as every 4th
year.  The Gregorian calendar improved this by making every 100th year NOT
a leap year, unless it was also the 400th year.  The Gregorian calendar has
been extrapolated back to the year 1000 AD and forward to the year 9999 AD.
Note that in historical context, the Julian calendar was in use until 1582
when the Gregorian calendar was adopted by the Catholic church.  Protestant
countries did not accept it until later; Germany and Netherlands in 1698,
British Empire in 1752, Russia in 1918.  Note that the Gregorian calendar
is itself imperfect.  Each year is on average 26 seconds too long, which
means that every 3,323 years, a day should be removed from the calendar.
No attempt is made to correct for that.

Date::Manip is therefore not equipped to truly deal with historical dates,
but should be able to perform (virtually) any operation dealing with a
modern time and date.

Date::Manip has (or will have) functionality to work with several fundamental
types of data.

=over 4

=item DATE

Although the word date is used extensively here, it is actually somewhat
misleading.  Date::Manip works with the full date AND time (year, month,
day, hour, minute, second).  It doesn't work with fractional seconds.
Timezones are also supported.

NOTE:  Much better support for timezones (including Daylight Savings Time)
is planned for the future.

=item DELTA

This refers to a duration or elapsed time.  One thing to note is that, as
used in this module, a delta refers only to the amount of time elapsed.  It
includes no information about a starting or ending time.

=item RECURRENCE

A recurrence is simply a notation for defining when a recurring event
occurs.  For example, if an event occurs every other Friday or every
4 hours, this can be defined as a recurrence.  With a recurrence and a
starting and ending date, you can get a list of dates in that period when
a recurring event occurs.

=item GRAIN

The granularity of a time basically refers to how accurate you wish to
treat a date.  For example, if you want to compare two dates to see if
they are identical at a granularity of days, then they only have to occur
on the same day.  At a granularity of an hour, they have to occur within
an hour of each other, etc.

NOTE:  Support for this will be added soon.

=back

Among other things, Date::Manip allow you to:

1.  Enter a date and be able to choose any format conveniant

2.  Compare two dates, entered in widely different formats to determine
    which is earlier

3.  Extract any information you want from ANY date using a format string
    similar to the Unix date command

4.  Determine the amount of time between two dates

5.  Add a time offset to a date to get a second date (i.e. determine the
    date 132 days ago or 2 years and 3 months after Jan 2, 1992)

6.  Work with dates with dates using international formats (foreign month
    names, 12/10/95 referring to October rather than December, etc.).

7.  To find a list of dates where a recurring event happens.

Each of these tasks is trivial (one or two lines at most) with this package.

=head1 EXAMPLES

In the documentation below, US formats are used, but in most (if not all)
cases, a non-English equivalent will work equally well.

1.  Parsing a date from any conveniant format

  $date=&ParseDate("today");
  $date=&ParseDate("1st thursday in June 1992");
  $date=&ParseDate("05/10/93");
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

  print &UnixDate("today","The time is now %T on %b %e, %Y.");
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

  It even works with business days:

  $date=&DateCalc("today","+ 3 business days",\$err);

6.  To work with dates in another language.

  &Date_Init("Language=French","DateFormat=non-US");
  $date=&ParseDate("1er decembre 1990");

7.  To find a list of dates where a recurring event happens.

  # To find the 2nd tuesday of every month
  @date=&ParseRecur("0:1*2:2:0:0:0",$base,$start,$stop);

NOTE: Some date forms do not work as well in languages other than English,
but this is not because DateManip is incapable of doing so (almost nothing
in this module is language dependent).  It is simply that I do not have the
correct translation available for some words.  If there is a date form that
works in English but does not work in a language you need, let me know and
if you can provide me the translation, I will fix DateManip.

=head1 ROUTINES

=over 4

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

The real work is done in the ParseDateString routine.

The ParseDate routine is primarily used to handle command line arguments.
If you have a command where you want to enter a date as a command line
arguement, you can use Date::Manip to make something like the following
work:

  mycommand -date Dec 10 1997 -arg -arg2

No more reading man pages to find out what date format is required in a
man page.

Historical note: this is originally why the Date::Manip routines were
written.  I was using a bunch of programs where dates and times were
entered as command line options and I was getting highly annoyed at the
many different (but not compatible) ways that they could be entered.

=item ParseDateString

 $date=&ParseDateString($string)

This routine is called by ParseDate, but it may also be called directly
to save some time.

A date actually includes 2 parts: date and time.  A time must include
hours and minutes and can optionally include seconds, fractional seconds,
an am/pm type string, and a timezone.  For example:

     [at] HH:MN              [Zone]
     [at] HH:MN         [am] [Zone]
     [at] HH:MN:SS      [am] [Zone]
     [at] HH:MN:SS.SSSS [am] [Zone]
     [at] HH            am   [Zone]

Hours can be written using 1 or 2 digits, but the single digit form may
only be used when no ambiguity is introduced (i.e. when it is not
immediately preceded by a digit).

A time is usually entered in 24 hour mode, but 12 hour mode can be used
as well if AM/PM are entered.

Fractional seconds are also supported in parsing but the fractional part is
discarded.

Timezones always appear after the time.  A number of different forms are
supported (see the section TIMEZONEs below).

Spaces (or other separators such as "/" or "-") in the date are always
optional when there is absolutely no ambiguity if they are not present.  If
there is ambiguity, the date will either be unparsable, or (as is more
often the case) get parsed differently than desired.

Years can be entered as 2 or 4 digits, days and months as 1 or 2 digits.
Both days and months must include 2 digits whenver they are immediately
adjacent to another part of the date or time.

Incidentally, the time is removed from the date before the date is parsed,
so the time may appear before or after the date, or between any two parts
of the date.

Sections of the date may be separated by spaces or by other valid date
separators (including "/", ".", and in some cases "-").  These separators
are treated very flexibly (they are converted to spaces), so the following
dates are all equivalent:

   12/10/1965
   12-10 / 1965
   12 // 10 -. 1965

In some cases, this may actually be TOO flexible, but not attempt is made
to trap this.

Valid date formats include the ISO 8601 formats:

   YYYYMMDDHHMNSSFFFF
   YYYYMMDDHHMNSS
   YYYYMMDDHHMN
   YYYYMMDDHH
   YY-MMDDHHMNSSF...
   YY-MMDDHHMNSS
   YY-MMDDHHMN
   YY-MMDDHH
   YYYYMMDD
   YYYYMM
   YYYY
   YY-MMDD
   YY-MM
   YY
   YYYYwWWD      ex.  1965-W02-2
   YYwWWD
   YYYYDOY       ex.  1965-045
   YYDOY

In the above list, YYYY and YY signify 4 or 2 digit years, MM, DD, HH, MN, SS
refer to two digit month, day, hour, minute, and second respectively.  F...
refers to fractional seconds (any number of digits) which will be ignored.
The last 4 formats can be explained by example:  1965-w02-2 refers to Tuesday
(day 2) of the 2nd week of 1965.  1965-045 refers to the 45th day of 1965.

In all cases, parts of the date may be separated by dashes "-".  If this is
done, 1 or 2 digit forms of MM, DD, etc. may be used.  All dashes are optional
except for those given in the table above (which MUST be included for that
format to be correctly parsed).

Additional date formats are available which may or may not be common including:

  MM/DD  **
  MM/DD/YY  **
  MM/DD/YYYY  **

  mmmDD       DDmmm                   mmmYYYY/DD
  mmmDDYY     DDmmmYY     DDYYmmm     YYYYmmmDD
  mmmDDYYYY   DDmmmYYYY   DDYYYYmmm   YYYY/DDmmm

Where mmm refers to the name of a month.  All parts of the date can be
separated by valid separators (space, "/", ".", or "-" as long as it
doesn't conflict with an ISO 8601 format), but these are optional except
for those given as a "/" in the list above.

** Note that with these formats, Americans tend to write month first, but
many other contries tend to write day first.  The latter behavior can be
obtained by setting the config variable DateFormat to something other than
"US" (see CUSTOMIZING DATE::MANIP below).

Miscellaneous other allowed formats are:
  which dofw in mmm in YY           "first sunday in june 1996 at 14:00"
  dofw week num YY                  "sunday week 22 1995"
  which dofw YY                     "22nd sunday at noon"
  dofw which week YY                "sunday 22nd week in 1996"
  next/last dofw                    "next friday at noon"
  next/last week/month              "next month"
  in num weeks/months               "in 3 weeks at 12:00"
  num weeks/months ago              "3 weeks ago"
  dofw in num week                  "Friday in 2 weeks"
  in num weeks dofw                 "in 2 weeks on friday"
  dofw num week ago                 "Friday 2 weeks ago"
  num week ago dofw                 "2 weeks ago friday"
  last day in mmm in YY             "last day of October"
  dofw                              "Friday" (Friday of current week)
  Nth                               "12th", "1st" (day of current month)

Note that certain words such as "in", "at", "of", etc. which commonly appear
in a date or time are ignored.  Also, the year is alway optional.

In addition, the following strings are recognized:
  today
  now       (synonym for today)
  yesterday (exactly 24 hours before now)
  tomorrow  (exactly 24 hours from now)
  noon      (12:00:00)
  midnight  (00:00:00)

Some things to note:

All strings are case insensitive.  "December" and "DEceMBer" both work.

When a part of the date is not given, defaults are used: year defaults
to current year; hours, minutes, seconds to 00.

The year may be entered as 2 or 4 digits.  If entered as 2 digits, it must
first be converted to a 4 digit year.  There are a couple of ways to do
this based on the value of the YYtoYYYY variable (described below).  The
default behavior it to force the 2 digit year to be in the 100 year period
CurrYear-89 to CurrYear+10.  So in 1996, the range is [1907 to 2006], so
the 2 digit year 05 would refer to 2005 but 07 would refer to 1907.  See
CUSTOMIZING DATE::MANIP below for information on YYtoYYYY for other methods.

Dates are always checked to make sure they are valid.

In all of the formats, the day of week ("Friday") can be entered anywhere
in the date and it will be checked for accuracy.  In other words,
  "Tue Jul 16 1996 13:17:00"
will work but
  "Jul 16 1996 Wednesday 13:17:00"
will not (because Jul 16, 1996 is Tuesday, not Wednesday).  Note that
depending on where the weekday comes, it may give unexpected results when
used in array context (with ParseDate).  For example, the date
("Jun","25","Sun","1990") would return June 25 of the current year since
Jun 25, 1990 is not Sunday.

The times "12:00 am", "12:00 pm", and "midnight" are not well defined.  For
good or bad, I use the following convention in Date::Manip:
  midnight = 12:00am = 00:00:00
  noon     = 12:00pm = 12:00:00
and the day goes from 00:00:00 to 23:59:59.  In otherwords, midnight is the
beginning of a day rather than the end of one.  At midnight on July 5, July
5 has just begun.  The time 24:00:00 is NOT allowed (even though ISO 8601
allows it).

The format of the date returned is YYYYMMDDHH:MM:SS.  The advantage of this
time format is that two times can be compared using simple string comparisons
to find out which is later.  Also, it is readily understood by a human.
Alternate forms can be used if that is more conveniant.  See Date_Init below
and the config variable Internal.

NOTE: The format for the date is going to change at some point in the future
to YYYYMMDDHH:MN:SS+HHMN (i.e. it'll include the timezone).  In order to
maintain compatibility, you should use UnixDate to extract information from
a date.

=item UnixDate

 @date=&UnixDate($date,@format)
 $date=&UnixDate($date,@format)

This takes a date and a list of strings containing formats roughly
identical to the format strings used by the UNIX date(1) command.  Each
format is parsed and an array of strings corresponding to each format is
returned.

$date may be any string that can be parsed by ParseDateString.

The format options are:

 Year
     %y     year                     - 00 to 99
     %Y     year                     - 0001 to 9999
     %G     year                     - 0001 to 9999 (see below)
     %L     year                     - 0001 to 9999 (see below)
 Month, Week
     %m     month of year            - 01 to 12
     %f     month of year            - " 1" to "12"
     %b,%h  month abbreviation       - Jan to Dec
     %B     month name               - January to December
     %U     week of year, Sunday
            as first day of week     - 01 to 53
     %W     week of year, Monday
            as first day of week     - 01 to 53
 Day
     %j     day of the year          - 001 to 366
     %d     day of month             - 01 to 31

     %e     day of month             - " 1" to "31"
     %v     weekday abbreviation     - " S"," M"," T"," W","Th"," F","Sa"
     %a     weekday abbreviation     - Sun to Sat
     %A     weekday name             - Sunday to Saturday
     %w     day of week              - 1 (Monday) to 7
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
     %s     seconds from 1/1/1970 GMT- negative if before 1/1/1970
     %o     seconds from Jan 1, 1970
            in the current time zone
     %z,%Z  timezone (3 characters)  - "EDT"
 Date, Time
     %c     %a %b %e %H:%M:%S %Y     - Fri Apr 28 17:23:15 1995
     %C,%u  %a %b %e %H:%M:%S %z %Y  - Fri Apr 28 17:25:57 EDT 1995
     %g     %a, %d %b %Y %H:%M:%S %z - Fri, 28 Apr 1995 17:23:15 EDT
     %D,%x  %m/%d/%y                 - 04/28/95
     %l     date in ls(1) format
              %b %e $H:$M            - Apr 28 17:23  (if within 6 months)
              %b %e  %Y              - Apr 28  1993  (otherwise)
     %r     %I:%M:%S %p              - 05:39:55 PM
     %R     %H:%M                    - 17:40
     %T,%X  %H:%M:%S                 - 17:40:58
     %V     %m%d%H%M%y               - 0428174095
     %Q     %Y%m%d                   - 19961025
     %q     %Y%m%d%H%M%S             - 19961025174058
     %P     %Y%m%d%H%M%S             - 1996102517:40:58
     %F     %A, %B %e, %Y            - Sunday, January  1, 1996
     %J     %G-W%W-%w                - 1997-W02-2
     %K     %Y-%j                    - 1997-045
 Other formats
     %n     insert a newline character
     %t     insert a tab character
     %%     insert a `%' character
     %+     insert a `+' character
 The following formats are currently unused but may be used in the future:
     NO 1234567890 !@#$^&*()_|-=\`[];',./~{}:<>?
 They currently insert the character following the %, but may (and probably
 will) change in the future as new formats are added.

If a lone percent is the final character in a format, it is ignored.

Note that the ls format (%l) applies to date within the past OR future 6
months!

The formats %U and %W return a week from 01 to 53.  Because days at the
beginning or end of the year may actually appear in a week in the previous
or next year, the %L and %G formats were added to handle this case.  %L and %G
give the year of the week for %U and %W respectively.  So Jan 1, 1993 is
written in ISO-8601 format as 1992-W53-5.  In this case, %Y is 1993, but %G
is 1992 and %W is 53.  %L and %U are similar for weeks starting with Sunday.
%J returns the full ISO-8601 format.

Note that the %s format was introduced in version 5.07.  Prior to that,
%s referred to the seconds since 1/1/70.  This was moved to %o in 5.07.

The formats used in this routine were originally based on date.pl (version
3.2) by Terry McGonigal, as well as a couple taken from different versions
of the date(1).  Also, several have been added which are unique to
Date::Manip.

=item ParseDateDelta

 $delta=&ParseDateDelta(\@args)
 $delta=&ParseDateDelta($string)
 $delta=&ParseDateDelta(\$string)

This takes an array and shifts a valid delta date (an amount of time)
from the array.  Recognized deltas are of the form:
  +Yy +Mm +Ww +Dd +Hh +MNmn +Ss
      examples:
         +4 hours +3mn -2second
         + 4 hr 3 minutes -2
         4 hour + 3 min -2 s
  +Y:+M:+W:+D:+H:+MN:+S
      examples:
         0:0:0:0:4:3:-2
         +4:3:-2
  mixed format
      examples:
         4 hour 3:-2

A field in the format +Yy is a sign, a number, and a string specifying
the type of field.  The sign is "+", "-", or absent (defaults to the
next larger element).  The valid strings specifying the field type
are:
   y:  y, yr, year, years
   m:  m, mon, month, months
   w:  w, wk, ws, wks, week, weeks
   d:  d, day, days
   h:  h, hr, hour, hours
   mn: mn, min, minute, minutes
   s:  s, sec, second, seconds

Also, the "s" string may be omitted.  The sign, number, and string may
all be separated from each other by any number of whitespaces.

In the date, all fields must be given in the order: Y M W D H MN S.  Any
number of them may be omitted provided the rest remain in the correct
order.  In the 2nd (colon) format, from 2 to 7 of the fields may be given.
For example +D:+H:+MN:+S may be given to specify only four of the fields.
In any case, both the MN and S field may be present.  No spaces may be
present in the colon format.

Deltas may also be given as a combination of the two formats.  For example,
the following is valid: +Yy +D:+H:+MN:+S.  Again, all fields must be given
in the correct order.

The word "in" may be prepended to the delta ("in 5 years") and the word
"ago" may be appended ("6 months ago").  The "in" is completely ignored.
The "ago" has the affect of reversing all signs that appear in front of the
components of the delta.  I.e. "-12 yr 6 mon ago" is identical to "+12yr
+6mon" (don't forget that there is an impled minus sign in front of the 6
because when no sign is explicitely given, it carries the previously
entered sign).

One thing is worth noting.  The year/month and day/hour/min/sec parts are
returned in a "normalized" form.  That is, the signs are adjusted so as to
be all positive or all negative.  For example, "+ 2 day - 2hour" does not
return "0:0:0:2:-2:0:0".  It returns "+0:0:0:1:22:0:0" (1 day 22 hours
which is equivalent).  I find (and I think most others agree) that this is
a more useful form.

Since the year/month and day/hour/min/sec parts must be normalized
separately there is the possibility that the sign of the two parts will be
different.  So, the delta "+ 2years -10 months - 2 days + 2 hours" produces
the delta "+1:2:-0:1:22:0:0".

It is possible to include a sign for all elements that is output.  See the
configuration variable DeltaSigns below.

NOTE: The internal format of the delta changed in version 5.30 from
Y:M:D:H:MN:S to Y:M:W:D:H:MN:S .  Also, it is going to change again at some
point in the future to Y:M:W:D:H:MN:S*FLAGS .  Use the routine Delta_Format
to extract information rather than parsing it yourself.

=item Delta_Format

 @str=&Delta_Format($delta,$dec,@format)
 $str=&Delta_Format($delta,$dec,@format)

This is similar to the UnixDate routine except that it extracts information
from a delta.  Unlike the UnixDate routine, most of the formats are 2
characters instead of 1.

NOTE:  For the time being, Delta_Format only understands the "exact" parts of
a delta (W/D/H/MN/S).  Additional formats to handle the remainder will be
added shortly.

Formats currently understood are:

   %Xv     : the value of the field named X
   %Xd     : the value of the field X, and all smaller fields, expressed in
             units of X
   %Xh     : the value of field X, and all larger fields, expressed in units
             of X
   %Xt     : the value of all fields expressed in units of X

   X is one of w,d,h,m,s (case sensitive).

   %%      : returns a "%"

So, the format "%hd" means the values of H, MN, and S expressed in hours.
So for the delta "0:0:0:0:2:30:0", this format returns 2.5.

The format "%hh" returns the value of W, D, and H expressed in hours.

If $dec is non-zero, the %Xd and %Xt values are formatted to contain $dec
decimal places.

=item ParseRecur

 $recur=&ParseRecur($string [,$base,$date0,$date1,$flags])
 @dates=&ParseRecur($string [,$base,$date0,$date1,$flags])

A recurrence refers to a recurring event.  A fully specified recurrence
requires (in most cases) 4 items: a recur description (describing the
frequency of the event), a base date (a date when the event occurred and
which other occurences are based on), and a start and end date.  There may
be one or more flags included which modify the behavior of the recur
description.  It is written as:

  recur*flags*base*date0*date1

Here, base, date0, and date1 are any strings (which must not contain any
asterixes) which can be parsed by ParseDate.  flags is a comma separated
list of flags (described below), and recur is a string describing a
recurring event.

If called in scalar context, it returns a string containing a fully
specified recurrence (or as much of it as can be determined with
unspecified fields left blank).  In list context, it returns a list of all
dates referred to by a recurrence if enough information is given in the
recurrence.  All dates returned are in the range:

  date0 <= date < date1

The argument $string can contain any of the parts of a full recurrence.
For example:

  recur
  recur*flags
  recur**base*date0*date1

The only part which is required is the recur description.  Any values
contained in $string are overridden by values passed in as parameters to
ParseRecur.

A recur description is a string of the format Y:M:W:D:H:MN:S .  Exactly one
of the colons may optionally be replaced by an asterix, or an asterix may
be prepended to the string.

Any value "N" to the left of the asterix refers to the "Nth" one.  Any value
to the right of the asterix refers to a value as it appears on a calendar.
Values right of the asterix can be a comma separated list of values or ranges.
In a few cases, negative values are appropriate.

This is best illustrated by example.

  0:0:2:1:0:0:0        every 2 weeks and 1 day
  0:0:0:0:5:30:0       every 5 hours and 30 minutes
  0:0:0:2*12:30:0      every 2 days at 12:30 (each day)
  3*1:0:2:12:0:0       every 3 years on Jan 2 at noon
  0:1*0:2:12,14:0:0    2nd of every month at 12:00 and 14:00
  1:0:0*45:0:0:0       45th day of every year
  0:1*4:2:0:0:0        4th tuesday (day 2) of every month
  0:1*-1:2:0:0:0       last tuesday of every month
  0:0:3*2:0:0:0        every 3rd tuesday (every 3 weeks on 2nd day of week)
  1:0*12:2:0:0:0       tuesday of the 12th week of each year
  *1990-1995:12:0:1:0:0:0
                       Dec 1 in 1990 through 1995

  0:1*2:0:0:0:0        the start of the 2nd week of every month (see Note 2)
  1*1:2:0:0:0:0        the start of the 2nd week in January each year (Note 2)

Note 1: There is no way to express the following with a single recurrence:

  every day at 12:30 and 1:00

Note 2: A recurrence specifying the week of a month is NOT clearly defined
in common usage.  What is the 1st week in a month?  The behavior (with
respect to this module) is well defined (using some of the flags below),
but in common usage, this is so ambiguous that this form should probably
never be used.

There are a small handful of English strings which can be parsed in place
of a numerical recur description.  These include:

  every 2nd day [in 1997]
  every 2nd day in June [1997]
  2nd day of every month [in 1997]
  2nd tuesday of every month [in 1997]
  last tuesday of every month [in 1997]
  every 2nd tuesday [in 1997]
  every 2nd tuesday in June [1997]

Each of these set base, date0, and date1 to a default value (the current
year with Jan 1 being the base date is the default if the year and month
are missing).

Flags are not yet implemented, but will allow even more complex behaviors
to be easily defined.

=item DateCalc

 $d=&DateCalc($d1,$d2 [,\$err] [,$mode])

This takes two dates, deltas, or one of each and performs the appropriate
calculation with them.  Dates must be a string that can be parsed by
&ParseDateString.  Deltas must be a string that can be parsed by
&ParseDateDelta.  Two deltas add together to form a third delta.  A date
and a delta returns a 2nd date.  Two dates return a delta (the difference
between the two dates).

Note that in many cases, it is somewhat ambiguous what the delta actually
refers to.  Although it is ALWAYS known how many months in a year, hours in
a day, etc., it is NOT known how many days form a month.  As a result, the
part of the delta containing month/year and the part with sec/min/hr/day
must be treated separately.  For example, "Mar 31, 12:00:00" plus a delta
of 1month 2days would yield "May 2 12:00:00".  The year/month is first
handled while keeping the same date.  Mar 31 plus one month is Apr 31 (but
since Apr only has 30 days, it becomes Apr 30).  Apr 30 + 2 days is May 2.
As a result, in the case where two dates are entered, the resulting delta
can take on two different forms.  By default ($mode=0), an absolutely
correct delta (ignoring daylight savings time) is returned in days, hours,
minutes, and seconds.

If $mode is 1, the math is done using an approximate mode where a delta is
returned using years and months as well.  The year and month part is
calculated first followed by the rest.  For example, the two dates "Mar 12
1995" and "Apr 13 1995" would have an exact delta of "31 days" but in the
approximate mode, it would be returned as "1 month 1 day".  Also, "Mar 31"
and "Apr 30" would have deltas of "30 days" or "1 month" (since Apr 31
doesn't exist, it drops down to Apr 30).  Approximate mode is a more human
way of looking at things (you'd say 1 month and 2 days more often then 33
days), but it is less meaningful in terms of absolute time.  In approximate
mode $d1 and $d2 must be dates.  If either or both is a delta, the
calculation is done in exact mode.

If $mode is 2, a business mode is used.  That is, the calculation is done
using business days, ignoring holidays, weekends, etc.  In order to
correctly use this mode, a config file must exist which contains the
section defining holidays (see documentation on the config file below).
The config file can also define the work week and the hours of the work
day, so it is possible to have different config files for different
businesses.

For example, if a config file defines the workday as 08:00 to 18:00, a
workweek consisting of Mon-Sat, and the standard (American) holidays, then
from Tuesday at 12:00 to the following Monday at 14:00 is 5 days and 2
hours.  If the "end" of the day is reached in a calculation, it
autmoatically switches to the next day.  So, Tuesday at 12:00 plus 6 hours
is Wednesday at 08:00 (provided Wed is not a holiday).  Also, a date that
is not during a workday automatically becomes the start of the next
workday.  So, Sunday 12:00 and Monday at 03:00 both automatically becomes
Monday at 08:00 (provided Monday is not a holiday).  In business mode, any
combination of date and delta may be entered, but a delta should not
contain a year or month field (weeks are fine though).

See below for some additional comments about business mode calculations.

Any other non-nil value of $mode is treated as $mode=1 (approximate mode).

The mode can be automatically set in the dates/deltas passed by including a
key word somewhere in it.  For example, in English, if the word
"approximately" is found in either of the date/delta arguments, approximate
mode is forced.  Likewise, if the word "business" or "exactly" appears,
business/exact mode is forced (and $mode is ignored).  So, the two
following are equivalent:

   $date=&DateCalc("today","+ 2 business days",\$err);
   $date=&DateCalc("today","+ 2 days",\$err,2);

Note that if the keyword method is used instead of passing in $mode, it is
important that the keyword actually appear in the argument passed in to
DateCalc.  The following will NOT work:

   $delta=&ParseDateDelta("+ 2 business days");
   $today=&ParseDate("today");
   $date=&DateCalc($today,$delta,\$err);

because the mode keyword is removed from a date/delta by the parse routines,
and the mode is reset each time a parse routine is called.  Since DateCalc
parses both of its arguments, whatever mode was previously set is ignored.

If \$err is passed in, it is set to:
   1 is returned if $d1 is not a delta or date
   2 is returned if $d2 is not a delta or date
   3 is returned if the date is outside the years 1000 to 9999
This argument is optional, but if included, it must come before $mode.

Nothing is returned if an error occurs.

When a delta is returned, the signs such that it is strictly positive or
strictly negative ("1 day - 2 hours" would never be returned for example).
The only time when this cannot be enforced is when two deltas with a
year/month component are entered.  In this case, only the signs on the
day/hour/min/sec part are standardized.

=item Date_SetTime

 $date=&Date_SetTime($date,$hr,$min,$sec)
 $date=&Date_SetTime($date,$time)

This takes a date (any string that may be parsed by ParseDateString) and
sets the time in that date.  For example, to get the time for 7:30
tomorrow, use the lines:

   $date=&ParseDate("tomorrow")
   $date=&Date_SetTime($date,"7:30")

Note that in this routine (as well as the other routines below which use
a time argument), no real parsing is done on the times.  As a result,

   $date=&Date_SetTime($date,"13:30")

works, but

   $date=&Date_SetTime($date,"1:30 PM")

doesn't.

=item Date_SetDateField

 $date=&Date_SetDateField($date,$field,$val [,$nocheck])

This takes a date and sets one of it's fields to a new value.  $field is
any of the strings "y", "m", "d", "h", "mn", "s" (case insensitive) and
$val is the new value.

If $nocheck is non-zero, no check is made as to the validity of the date.

=item Date_GetPrev

 $date=&Date_GetPrev($date,$dow, $curr [,$hr,$min,$sec])
 $date=&Date_GetPrev($date,$dow, $curr [,$time])
 $date=&Date_GetPrev($date,undef,$curr,$hr,$min,$sec)
 $date=&Date_GetPrev($date,undef,$curr,$time)

This takes a date (any string that may be parsed by ParseDateString) and finds
a previous date.

If $dow is defined, it is a day of week (a string such as "Fri" or a number
from 0 to 6).  The date of the previous $dow is returned.  If $date falls
on this day of week, the date returned will be $date (if $curr is non-zero)
or a week earlier (if $curr is 0).  If a time is passed in (either as
separate hours, minutes, seconds or as a time in HH:MM:SS or HH:MM format),
the time on this date is set to it.  The following examples should
illustrate the use of Date_GetPrev:

    date                   dow    curr  time            returns
    Fri Nov 22 18:15:00    Thu    0     12:30           Thu Nov 21 12:30:00
    Fri Nov 22 18:15:00    Fri    0     12:30           Fri Nov 15 12:30:00
    Fri Nov 22 18:15:00    Fri    1     12:30           Fri Nov 22 12:30:00

If $dow is undefined, then a time must be entered, and the date returned is
the previous occurence of this time.  If $curr is non-zero, the current
time is returned if it matches the criteria passed in.  In other words, the
time returned is the last time that a digital clock (in 24 hour mode) would
have displayed the time you pass in.  If you define hours, minutes and
seconds default to 0 and you might jump back as much as an entire day.  If
hours are undefined, you are looking for the last time the minutes/seconds
appeared on the digital clock, so at most, the time will jump back one hour.

    date               curr  hr     min    sec      returns
    Nov 22 18:15:00    0/1   18     undef  undef    Nov 22 18:00:00
    Nov 22 18:15:00    0/1   18     30     0        Nov 21 18:30:00
    Nov 22 18:15:00    0     18     15     undef    Nov 21 18:15:00
    Nov 22 18:15:00    1     18     15     undef    Nov 22 18:15:00
    Nov 22 18:15:00    0     undef  15     undef    Nov 22 17:15:00
    Nov 22 18:15:00    1     undef  15     undef    Nov 22 18:15:00

=item Date_GetNext

 $date=&Date_GetNext($date,$dow, $curr [,$hr,$min,$sec])
 $date=&Date_GetNext($date,$dow, $curr [,$time])
 $date=&Date_GetNext($date,undef,$curr,$hr,$min,$sec)
 $date=&Date_GetNext($date,undef,$curr,$time)

Similar to Date_GetPrev.

=item Date_DayOfWeek

 $day=&Date_DayOfWeek($m,$d,$y);

Returns the day of the week (0 for Sunday, 6 for Saturday).  Dec 31, 0999
was Tuesday.

All arguments must be numeric.

=item Date_SecsSince1970

 $secs=&Date_SecsSince1970($m,$d,$y,$h,$mn,$s)

Returns the number of seconds since Jan 1, 1970 00:00 (negative if date is
earlier).

All arguments must be numeric.

=item Date_SecsSince1970GMT

 $secs=&Date_SecsSince1970GMT($m,$d,$y,$h,$mn,$s)

Returns the number of seconds since Jan 1, 1970 00:00 GMT (negative if date
is earlier).  If CurrTZ is "IGNORE", the number will be identical to
Date_SecsSince1970 (i.e. the date given will be treated as being in GMT).

All arguments must be numeric.

=item Date_DaysSince999

 $days=&Date_DaysSince999($m,$d,$y)

Returns the number of days since Dec 31, 0999.

All arguments must be numeric.

=item Date_DayOfYear

 $day=&Date_DayOfYear($m,$d,$y);

Returns the day of the year (001 to 366)

All arguments must be numeric.

=item Date_DaysInYear

 $days=&Date_DaysInYear($y);

Returns the number of days in the year (365 or 366)

=item Date_DaysInMonth

 $days=&Date_DaysInMonth($m,$y);

Returns the number of days in the month.

=item Date_WeekOfYear

 $wkno=&Date_WeekOfYear($m,$d,$y,$first);

Figure out week number.  $first is the first day of the week which is
usually 0 (Sunday) or 1 (Monday), but could be any number between 0 and 6
in practice.

All arguments must be numeric.

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

This returns a timezone.  It looks in the following places for a timezone
in the following order:

   $ENV{TZ}
   $main::TZ
   unix 'date' command
   /etc/TIMEZONE

If it's not found in any of those places, an error occurs:

   ERROR: Date::Manip unable to determine TimeZone.

Date_TimeZone is able to read zones of the format PST8PDT (see TIMEZONES
documentation below).

=item Date_ConvTZ

 $date=&Date_ConvTZ($date)
 $date=&Date_ConvTZ($date,$from)
 $date=&Date_ConvTZ($date,(),$to)
 $date=&Date_ConvTZ($date,$from,$to)

This converts a date (which MUST be in the format returned by ParseDate)
from one timezone to another.

If it is called with no arguments, the date is converted from the local
timezone to the timezone specified by the config variable ConvTZ (see
documentation on ConvTZ below).  If ConvTZ is set to "IGNORE", no
conversion is done.

If called with $from but no $to, the timezone is converted from the
timezone in $from to ConvTZ (of TZ if ConvTZ is not set).  Again, no
conversion is done if ConvTZ is set to "IGNORE".

If called with $to but no $from, $from defaults to ConvTZ (if set) or the
local timezone otherwise.  Although this does not seem immediately obvious,
it actually makes sense.  By default, all dates that are parsed are
converted to ConvTZ, so most of the dates being worked with will be stored
in that timezone.

If Date_ConvTZ is called with both $from and $to, the date is converted
from the timezone $from to $to.

NOTE: As in all other cases, the $date returned from Date_ConvTZ has no
timezone information included as part of it, so calling UnixDate with the
"%z" format will return the timezone that Date::Manip is working in
(usually the local timezone).

Example:  To convert 2/2/96 noon PST to CST (regardless of what timezone
you are in, do the following:

 $date=&ParseDate("2/2/96 noon");
 $date=&Date_ConvTZ($date,"PST","CST");

Both timezones MUST be in one of the formst listed below in the section
TIMEZONES.

=item Date_Init

 $flag=&Date_Init();
 $flag=&Date_Init("VAR=VAL","VAR=VAL",...);

Normally, it is not necessary to explicitely call Date_Init.  The first
time any of the other routines are called, Date_Init will be called to set
everything up.  If for some reason you want to change the configuration of
Date::Manip, you can pass the appropriate string or strings into Date_Init
to reinitizize things.

The strings to pass in are of the form "VAR=VAL".  Any number may be
included and they can come in any order.  VAR may be any configuration
variable.  A list of all configuaration variables is given in the section
CUSTOMIZING DATE::MANIP below.  VAL is any allowed value for that variable.
For example, to switch from English to French and use non-US format (so
that 12/10 is Oct 12), do the following:

  &Date_Init("Language=French","DateFormat=nonUS");

Note that the usage of Date_Init changed with version 5.07.  The old
calling convention is allowed but is depreciated.

If you change timezones in the middle of using Date::Manip, comparing dates
from before the switch to dates from after the switch will produce incorrect
results.

=item Date_IsWorkDay

  $flag=&Date_IsWorkDay($date [,$flag]);

This returns 1 if $date is a work day.  If $flag is non-zero, the time is
checked to see if it falls within work hours.

=item Date_NextWorkDay

  $date=&Date_NextWorkDay($date,$off [,$time]);

Finds the day $off work days from now.  If $time is passed in, we must also
take into account the time of day.

If $time is not passed in, day 0 is today (if today is a workday) or the
next work day if it isn't.  In any case, the time of day is unaffected.

If $time is passed in, day 0 is now (if now is part of a workday) or the
start of the very next work day.

=item Date_PrevWorkDay

  $date=&Date_PrevWorkDay($date,$off [,$time]);

Similar to Date_NextWorkDay.

=item Date_NearestWorkDay

  $date=&Date_NearestWorkDay($date [,$tomorrowfirst]);

This looks for the work day nearest to $date.  If $date is a work day, it
is returned.  Otherwise, it will look forward or backwards in time 1 day
at a time until a work day is found.  If $tomorrowfirst is non-zero (or if
it is omitted and the config variable TomorrowFirst is non-zero), we look
to the future first.  Otherwise, we look in the past first.  In otherwords,
in a normal week, if $date is Wednesday, $date is returned.  If $date is
Saturday, Friday is returned.  If $date is Sunday, Monday is returned.  If
Wednesday is a holiday, Thursday is returned if $tomorrowfirst is non-nil
or Tuesday otherwise.

=item DateManipVersion

  $version=&DateManipVersion

Returns the version of Date::Manip.

=back

=head1 TIMEZONES

The following timezone names are currently understood (and can be used in
parsing dates).  These are zones defined in RFC 822.

    Universal:  GMT, UT
    US zones :  EST, EDT, CST, CDT, MST, MDT, PST, PDT
    Military :  A to Z (except J)
    Other    :  +HHMM or -HHMM
    ISO 8601 :  +HH:MM, +HH, -HH:MM, -HH

In addition, the following timezone abbreviations are also accepted.  In a
few cases, the same abbreviation is used for two different timezones (for
example, NST stands for Newfoundland Standare -0330 and North Sumatra +0630).
In these cases, only 1 of the two is available.  The one preceded by a "#"
sign is NOT available but is documented here for completeness.  This list of
zones comes from the Time::Zone module by Graham Barr, David Muir Sharnoff,
and Paul Foley (with some additions by myself).

      IDLW    -1200    International Date Line West
      NT      -1100    Nome
      HST     -1000    Hawaii Standard
      CAT     -1000    Central Alaska
      AHST    -1000    Alaska-Hawaii Standard
      YST     -0900    Yukon Standard
      HDT     -0900    Hawaii Daylight
      YDT     -0800    Yukon Daylight
      PST     -0800    Pacific Standard
      PDT     -0700    Pacific Daylight
      MST     -0700    Mountain Standard
      MDT     -0600    Mountain Daylight
      CST     -0600    Central Standard
      CDT     -0500    Central Daylight
      EST     -0500    Eastern Standard
      EDT     -0400    Eastern Daylight
      AST     -0400    Atlantic Standard
     #NST     -0330    Newfoundland Standard       nst=North Sumatra    +0630
      NFT     -0330    Newfoundland
     #GST     -0300    Greenland Standard          gst=Guam Standard    +1000
      BST     -0300    Brazil Standard             bst=British Summer   +0100
      ADT     -0300    Atlantic Daylight
      NDT     -0230    Newfoundland Daylight
      AT      -0200    Azores
      WAT     -0100    West Africa
      GMT     +0000    Greenwich Mean
      UT      +0000    Universal (Coordinated)
      UTC     +0000    Universal (Coordinated)
      WET     +0000    Western European
      CET     +0100    Central European
      FWT     +0100    French Winter
      MET     +0100    Middle European
      MEWT    +0100    Middle European Winter
      SWT     +0100    Swedish Winter
     #BST     +0100    British Summer              bst=Brazil standard  -0300
      CEST    +0200    Central European Summer
      EET     +0200    Eastern Europe, USSR Zone 1
      FST     +0200    French Summer
      MEST    +0200    Middle European Summer
      METDST  +0200    An alias for MEST used by HP-UX
      SST     +0200    Swedish Summer              sst=South Sumatra    +0700
      BT      +0300    Baghdad, USSR Zone 2
      IT      +0330    Iran
      ZP4     +0400    USSR Zone 3
      ZP5     +0500    USSR Zone 4
      IST     +0530    Indian Standard
      ZP6     +0600    USSR Zone 5
      NST     +0630    North Sumatra               nst=Newfoundland Std -0330
     #SST     +0700    South Sumatra, USSR Zone 6  sst=Swedish Summer   +0200
      JT      +0730    Java (3pm in Cronusland!)
      CCT     +0800    China Coast, USSR Zone 7
      AWST    +0800    West Australian Standard
      WST     +0800    West Australian Standard
      JST     +0900    Japan Standard, USSR Zone 8
      ROK     +0900    Republic of Korea
      CAST    +0930    Central Australian Standard
      EAST    +1000    Eastern Australian Standard
      GST     +1000    Guam Standard, USSR Zone 9  gst=Greenland Std    -0300
      CADT    +1030    Central Australian Daylight
      EADT    +1100    Eastern Australian Daylight
      IDLE    +1200    International Date Line East
      NZST    +1200    New Zealand Standard
      NZT     +1200    New Zealand
      NZDT    +1300    New Zealand Daylight

Others can be added in the future upon request.

DateManip needs to be able to determine the local timezone.  It can do this
by certain things such as the TZ environment variable (see Date_TimeZone
documentation above) or useing the TZ config variable (described below).
In either case, the timezone can be of the form STD#DST (for example
EST5EDT).  Both the standard and daylight savings time abbreviations must
be in the table above in order for this to work.  Also, this form may NOT
be used when parsing a date as there is no way to determine whether the
date is in daylight saving time or not.  The following forms are also
available and are treated similar to the STD#DST forms:

      US/Pacific
      US/Mountain
      US/Central
      US/Eastern

=head1 BUSINESS MODE

Anyone using business mode is going to notice a few quirks about it which
should be explained.  When I designed business mode, I had in mind what UPS
tells me when they say 2 day delivery, or what the local business which
promises 1 business day turnaround really means.

If you do a business day calculation (with the workday set to 9:00-5:00),
you will get the following:

   Saturday at noon + 1 business day = Tuesday at 9:00
   Saturday at noon - 1 business day = Friday at 9:00

What does this mean?

We have a business that works 9-5 and they have a drop box so I can drop
things off over the weekend and they promise 1 business day turnaround.  If
I drop something off Friday night, Saturday, or Sunday, it doesn't matter.
They're going to get started on it Monday morning.  It'll be 1 business day
to finish the job, so the earliest I can expect it to be done is around
17:00 Monday or 9:00 Tuesday morning.  Unfortunately, there is some
ambiguity as to what day 17:00 really falls on, similar to the ambiguity
that occurs when you ask what day midnight falls on.  Although it's not the
only answer, Date::Manip treats midnight as the beginning of a day rather
than the end of one.  In the same way, 17:00 is equivalent to 9:00 the next
day and any time the date calculations encounter 17:00, it automatically
switch to 9:00 the next day.  Although this introduces some quirks, I think
this is justified.  You just have to treat 9:00 as being ambiguous (in the
same way you treat midnight as being ambiguous).

Equivalently, if I want a job to be finished on Saturday (despite the fact
that I cannot pick it up since the business is closed), I have to drop it
off no later than Friday at 9:00.  That gives them a full business day to
finish it off.  Of course, I could just as easily drop it off at 17:00
Thursday, or any time between then and 9:00 Friday.  Again, it's a matter
of treating 9:00 as ambiguous.

So, in case the business date calculations ever produce results that you
find confusing, I believe the solution is to write a wrapper which,
whenever it sees a date with the time of exactly 9:00, it treats it
specially (depending on what you want.

So Saturday + 1 business day = Tuesday at 9:00 (which means anything
from Monday 17:00 to Tuesday 9:00), but Monday at 9:01 + 1 business
day = Tuesday at 9:01 which is exact.

If this is not exactly what you have in mind, don't use the DateCalc
routine.  You can probably get whatever behavior you want using the
routines Date_IsWorkDay, Date_NextWorkDay, and Date_PrevWorkDay described
above.

=head1 CUSTOMIZING DATE::MANIP

There are a number of variables which can be used to customize the way
Date::Manip behaves.  There are also several ways to set these variables.

At the top of the Manip.pm file, there is a section which contains all
customization variables.  These provide the default values.

These can be overridden in a global config file if one is present (this
file is optional).  If the GlobalCnf variable is set in the Manip.pm file,
it contains the full path to a config file.  If the file exists, it's
values will override those set in the Manip.pm file.  A sample config file
is included with the Date::Manip distribution.  Modify it as appropriate
and copy it to some appropriate directory and set the GlobalCnf variable
in the Manip.pm file.

Each user can have a personal config file which is of the same form as
the global config file.  The variables PersonalCnf and PersonalCnfPath
set the name and search path for the personal config file.  This file is
also optional.

NOTE: if you use business mode calculations, you must have a config file
(either global or personal) since this is the only place where you can
define holidays.

Finally, any variables passed in through Date_Init override all other
values.

A config file can be composed of several sections (though only 2 of them
are currently used).  The first section sets configuration varibles.  Lines
in this section are of the form:

   VARIABLE = VALUE

For example, to make the default language French, include the line:

   Language = French

Only variables described below may be used.  Blank lines and lines beginning
with a pound sign (#) are ignored.  All spaces are optional and strings are
case insensitive.

A line which starts with an asterix (*) designates a new section.  The only
section currently used is the Holiday section.  All lines are of the form:

   DATE = HOLIDAY

HOLIDAY is the name of the holiday (or it can be blank in which case the
day will still be treated as a holiday... for example the day after
Thanksgiving or Christmas is often a work holiday though neither are
named).

DATE is a string which can be parsed to give a valid date in any year.  It
can be of the form

   Date
   Date + Delta
   Date - Delta

A valid holiday section would be:

   *Holiday

   1/1                             = New Year's Day
   third Monday in Feb             = Presidents' Day
   fourth Thu in Nov               = Thanksgiving

   # The Friday after Thanksgiving is an unnamed holiday most places
   fourth Thu in Nov + 1 day       =

In a Date + Delta or Date - Delta string, you can use business mode by
including the appropriate string (see documentation on DateCalc) in the
Date or Delta.  So (in English), the first workday before Christmas could
be defined as:

   12/25 - 1 business day          =

All Date::Manip variables which can be used are described in the following
section.

=over 4

=item IgnoreGlobalCnf

If this variable is used (any value is ignored), the global config file
is not read.  It must be present in the initial call to Date_Init or the
global config file will be read.

=item EraseHolidays

If this variable is used (any value is ignored), the current list of
defined holidays is erased.  A new set will be set the next time a
config file is read in.

=item PersonalCnf

This variable can be passed into Date_Init to read a different personal
configuration file.  It can also be included in the global config file
to define where personal config files live.

=item PersonalCnfPath

Used in the same way as the PersonalCnf option.  You can use tilde (~)
expansions when defining the path.

=item Language

Date::Manip can be used to parse dates in many different languages.
Currently, it is configured to read English, Swedish, and French dates,
but others can be added easily.  Language is set to the language used to
parse dates.

=item DateFormat

Different countries look at the date 12/10/96 as Dec 10 or Oct 12.  In the
United States, the first is most common, but this certainly doesn't hold
true for other countries.  Setting DateFormat to "US" forces the first
behavior (Dec 10).  Setting DateFormat to anything else forces the second
behavior (Oct 12).

=item TZ

Date::Manip is able to understand some timezones (and others will be added
in the future).  At the very least, all zones defined in RFC 822 are
supported.  Currently supported zones are listed in the TIMEZONES section
above and all timezones should be entered as one of them.

Date::Manip must be able to determine the timezone the user is in.  It does
this by looking in the following places:

   the environment variable TZ
   the variable $main::TZ
   the file /etc/TIMEZONE
   the 5th element of the unix "date" command (not available on NT machines)

At least one of these should contain a timezone in one of the supported
forms.  If it doesn't, the TZ variable must be set to contain the local
timezone in the appropriate form.

The TZ variable will override the other methods of determining the
timezone, so it should probably be left blank if any of the other methods
will work.  Otherwise, you will have to modify the variable every time you
switch to/from daylight savings time.

=item ConvTZ

All date comparisons and calculations must be done in a single time zone in
order for them to work correctly.  So, when a date is parsed, it should be
converted to a specific timezone.  This allows dates to easily be compared
and manipulated as if they are all in a single timezone.

The ConvTZ variable determines which timezone should be used to store dates
in.  If it is left blank, all dates are converted to the local timezone
(see the TZ variable above).  If it is set to one of the timezones listed
above, all dates are converted to this timezone.  Finally, if it is set to
the string "IGNORE", all timezone information is ignored as the dates are
read in (in this case, the two dates "1/1/96 12:00 GMT" and "1/1/96 12:00
EST" would be treated as identical).

=item Internal

When a date is parsed using ParseDate, that date is stored in an internal
format which is understood by the Date::Manip routines UnixDate and
DateCalc.  Originally, the format used to store the date internally was:

   YYYYMMDDHH:MN:SS

It has been suggested that I remove the colons (:) to shorten this to:

   YYYYMMDDHHMNSS

The main advantage of this is that some databases are colon delimited which
makes storing a date from Date::Manip tedious.

In order to maintain backwards compatibility, the Internal variable was
introduced.  Set it to 0 (to use the old format) or 1 (to use the new
format).

=item FirstDay

It is sometimes necessary to know what day of week is regarded as first.
By default, this is set to Monday, but many countries and people will
prefer Sunday (and in a few cases, a different day may be desired).  Set
the FirstDay variable to be the first day of the week (1=Monday, 7=Sunday)
Monday should be chosen to to comply with ISO 8601.

=item WorkWeekBeg, WorkWeekEnd

The first and last days of the work week.  By default, monday and friday.
WorkWeekBeg must come before WorkWeekEnd numerically.  The days are
numbered from 0 (sunday) to 6 (saturday).  There is no way to handle an odd
work week of Thu to Mon for example.

=item WorkDay24Hr

If this is non-nil, a work day is treated as being 24 hours long.  The
WorkDayBeg and WorkDayEnd variables are ignored in this case.

=item WorkDayBeg, WorkDayEnd

The times when the work day starts and ends.  WorkDayBeg must come before
WorkDayEnd (i.e. there is no way to handle the night shift where the work
day starts one day and ends another).  Also, the workday MUST be more than
one hour long (of course, if this isn't the case, let me know... I want a
job there!).

The time in both can be in any valid time format (including international
formats), but seconds will be ignored.

=item TomorrowFirst

Periodically, if a day is not a business day, we need to find the nearest
business day to it.  By default, we'll look to "tomorrow" first, but if this
variable is set to 0, we'll look to "yesterday" first.  This is only used in
the Date_NearestWorkDay and is easily overridden (see documentation for that
function).

=item DeltaSigns

Prior to Date::Manip version 5.07, a negative delta would put negative
signs in front of every component (i.e. "0:0:-1:-3:0:-4").  By default,
5.07 changes this behavior to print only 1 or two signs in front of the
year and day elements (even if these elements might be zero) and the sign
for year/month and day/hour/minute/second are the same.  Setting this
variable to non-zero forces deltas to be stored with a sign in front of
every element (including elements equal to 0).

=item Jan1Week1

ISO 8601 states that the first week of the year is the one which contains
Jan 4 (i.e. it is the first week in which most of the days in that week
fall in that year).  This means that the first 3 days of the year may
be treated as belonging to the last week of the previous year.  If this
is set to non-nil, the ISO 8601 standard will be ignored and the first
week of the year contains Jan 1.

=item YYtoYYYY

By default, a 2 digit year is treated as falling in the 100 year period of
CURR-89 to CURR+10.  YYtoYYYY may be set to any integer N to force a 2
digit year into the period CURR-N to CURR+(99-N).  A value of 0 forces
the year to be the current year or later.  A value of 99 forces the year
to be the current year or earlier.  Since I do no checking on the value of
YYtoYYYY, you can actually have it any positive or negative value to force
it into any century you want.

YYtoYYYY can also be set to "C" to force it into the current century, or
to "C##" to force it into a specific century.  So, no (1998), "C" forces
2 digit years to be 1900-1999 and "C18" would force it to be 1800-1899.

=item UpdateCurrTZ

If a script is running over a long period of time, the timezone may change
during the course of running it (i.e. when daylight savings time starts or
ends).  As a result, parsing dates may start putting them in the wrong time
zone.  Since a lot of overhead can be saved if we don't have to check the
current timezone every time a date is parsed, by default checking is turned
off.  Setting this to non-nill will force timezone checking to be done every
time a date is parsed... but this will result in a considerable performance
penalty.

A better solution would be to restart the process on the two days per year
where the timezone switch occurs.

=item IntCharSet

If set to 0, use the US character set (7-bit ASCII) to return strings such
as the month name.  If set to 1, use the appropriate international character
set.

=item ForceDate

This variable can be set to a date in the format: YYYY-MM-DD-HH:MN:SS
to force the current date to be interpreted as this date.  Since the current
date is used in parsing, this string will not be parsed and MUST be in the
format given above.

=back

=head1 BACKWARDS INCOMPATIBILITIES

For the most part, Date::Manip has remained backward compatible at every
release.  There have been a few minor incompatibilities introduced at
various stages.  Major differences are marked with bullets.

=over 4

=item VERSION 5.30

=over 4

=item * Delta format changed

A week field has been added to the internal format of the delta.  It now
reads "Y:M:W:D:H:MN:S" instead of "Y:M:D:H:MN:S".

=back

=item VERSION 5.21

=over 4

=item Long running processes may give incorrect timezone

A process that runs during a timezone change (Daylight Saving Time
specifically) may report the wrong timezone.  See the UpdateCurrTZ variable
for more information.

=item UnixDate "%J", "%W", and "%U" formats fixed

The %J, %W, and %U will no longer report a week 0 or a week 53 if it should
really be week 1 of the following year.  They now report the correct week
number according to ISO 8601.

=back

=item VERSION 5.20

=over 4

=item * ParseDate formats removed (ISO 8601 compatibility)

Full support for ISO 8601 formats was added.  As a result, some formats
which previously worked may no longer be parsed since they conflict with an
ISO 8601 format.  These include MM-DD-YY (conflicts with YY-MM-DD) and
YYMMDD (conflicts with YYYYMM).  MM/DD/YY still works, so the first form
can be kept easily by changing "-" to "/".  YYMMDD can be changed to
YY-MM-DD before being parsed.  Whenever parsing dates using dashes as
separators, they will be treated as ISO 8601 dates.  You can get around
this by converting all dashes to slashes.

=item * Week day numbering

The day numbering was changed from 0-6 (sun-sat) to 1-7 (mon-sun) to be
ISO 8601 compatible.  Weeks start on Monday (though this can be overridden
using the FirstDay config variable) and the 1st week of the year contains
Jan 4 (though it can be forced to contain Jan 1 with the Jan1Week1 config
variable).

=back

=item VERSION 5.07

=over 4

=item UnixDate "%s" format

Used to return the number of seconds since 1/1/1970 in the current
timezone.  It now returns the number of seconds since 1/1/1970 GMT.
The "%o" format was added which returns what "%s" previously did.

=item Internal format of delta

The format for the deltas returned by ParseDateDelta changed.  Previously,
each element of a delta had a sign attached to it (+1:+2:+3:+4:+5:+6).  The
new format removes all unnecessary signs by default (+1:2:3:4:5:6).  Also,
because of the way deltas are normalized (see documentation on
ParseDateDelta), at most two signs are included.  For backwards
compatibility, the config variable DeltaSigns was added.  If set to 1, all
deltas include all 6 signs.

=item Date_Init arguments

The format of the Date_Init calling arguments changed.  The
old method

  &Date_Init($language,$format,$tz,$convtz);

is still supported, but this support will likely disappear in the future.
Use the new calling format instead:

  &Date_Init("var=val","var=val",...);

=back

=back

=head1 COMMON PROBLEMS

=over 4

=item Unable to determine TimeZone

Perhaps the most common problem occurs when you get the error:

   Error: Date::Manip unable to determine TimeZone.

Date::Manip tries hard to determine the local timezone, but on some
machines, it cannot do this (especially those without a unix date
command... i.e. Microsoft Windows systems).  To fix this, just set the TZ
variable, either at the top of the Manip.pm file, or in the DateManip.cnf
file.  I suggest using the form "EST5EDT" so you don't have to change it
every 6 months when going to or from daylight savings time.

Another problem is when running on Micro$oft OS'es.  I have added many
tests to catch them, but they still slip through occasionally.  If any ever
complain about getpwnam/getpwuid, simply add one of the lines:

  $ENV{OS} = Windows_NT
  $ENV{OS} = Windows_95

to your script before

  use Date::Manip

=item Date::Manip is slow

From the very beginning, I have designed Date::Manip to be capable of doing
virtually every common operation that you could ever want to do with a
date and to do it easily.  To get this amount of flexibility, there is
a price to be paid, and in this case it is in performance.  Date::Manip is
NOT an extremely fast module and it likely never will be.

If you are going to be using the module in cases where performance is an
important factor (parsing 10,000 dates from a database or started up in a
CGI program being run by your web server 5,000 times a second), you might
check out one of the other Date or Time modules in CPAN.  Date::DateCalc,
Date::TimeDate, or Time::Time-modules might meet your needs.

Although I am working on making Date::Manip faster, it will never be as
fast as these other modules.  Some of them are written in C for one thing.
And before anyone asks, Date::Manip will never be translated to C (at least
by me).  I write C because I have to.  I write perl because I like to.
Date::Manip is something I do because it interests me, not something I'm
paid for.  Version 5.21 does run noticably faster than earlier versions due
to rethinking some of the initialization, so at the very least, make sure
you are running this version or later.

Some things that will definitely help:

ISO-8601 dates are parsed first and fastest.  Use them whenever possible.

Avoid parsing dates that are referenced against the current time (in 2
days, today at noon, etc.).  These take a lot longer to parse.

   Example:  parsing 1065 dates with version 5.11 took 48.6 seconds, 36.2
   seconds with version 5.21, and parsing 1065 ISO-8601 dates with version
   5.21 took 29.1 seconds (these were run on a slow, overloaded computer with
   little memory... but the ratios should be reliable on a faster computer).

Business date calculations are extremely.  You should consider alternatives
if possible (i.e. doing the calculation in exact mode and then multiplying
by 5/7).  There will be an approximate business mode in one of the next
versions which will be much faster (though less accurate) which will do
something like this.  Whenever possible, use this mode.  And who needs a
business date more accurate than "6 to 8 weeks" anyway huh :-)

Never call Date_Init more than once.  Unless you're doing something very
strange, there should never be a reason to anyway.

=item Sorting Problems

If you use Date::Manip to sort a number of dates, you must call Date_Init
either explicitely, or by way of some other Date::Manip routine before it
is used in the sort.  For example, the following code fails:

   use Date::Manip;
   # &Date_Init;
   sub sortDate {
       my($date1, $date2);
       $date1 = &ParseDate($a);
       $date2 = &ParseDate($b);
       return ($date1 cmp $date2);
   }
   @date = ("Fri 16 Aug 96",
            "Mon 19 Aug 96",
            "Thu 15 Aug 96");
   @i=sort sortDate @dates;

but if you uncomment the Date_Init line, it works.  The reason for this is
that the first time you call Date_Init, it initializes a number of items
used by Date::Manip.  Some of these are sorted.  It turns out that perl
(5.003 and earlier) has a bug in it which does not allow a sort within a
sort.  The next version (5.004) may fix this.  For now, the best thing to
do is to call Date_Init explicitely.  NOTE: This is an EXTREMELY
inefficient way to sort data.  Instead, you should translate the dates to
the Date::Manip internal format, sort them using a normal string
comparison, and then convert them back to the format desired using
UnixDate.

NOTE:  5.004 has not fixed this to date.

=item RCS Control

If you try to put Date::Manip under RCS control, you are going to have
problems.  Apparently, RCS replaces strings of the form "$Date...$" with
the current date.  This form occurs all over in Date::Manip.  Since very
few people will ever have a desire to do this (and I don't use RCS), I have
not worried about it.

=back

=head1 KNOWN BUGS

=over 4

=item Daylight Savings Times

Date::Manip does not handle daylight savings time, though it does handle
timezones to a certain extent.  Converting from EST to PST works fine.
Going from EST to PDT is unreliable.

The following examples are run in the winter of the US East coast (i.e.
in the EST timezone).

	print UnixDate(ParseDate("6/1/97 noon"),"%u"),"\n";
        => Sun Jun  1 12:00:00 EST 1997

June 1 EST does not exist.  June 1st is during EDT.  It should print:

        => Sun Jun  1 00:00:00 EDT 1997

Even explicitely adding the timezone doesn't fix things (if anything, it
makes them worse):

	print UnixDate(ParseDate("6/1/97 noon EDT"),"%u"),"\n";
        => Sun Jun  1 11:00:00 EST 1997

Date::Manip converts everything to the current timezone (EST in this case).

Related problems occur when trying to do date calculations over a timezone
change.  These calculations may be off by an hour.

Also, if you are running a script which uses Date::Manip over a period of
time which starts in one time zone and ends in another (i.e. it switches
form Daylight Savings Time to Standard Time or vice versa), many things may
be wrong (especially elapsed time).

I hope to fix these problems in a future release so that it would convert
everything to the current zones (EST or EDT).

=back

=head1 BUGS AND QUESTIONS

If you find a bug in Date::Manip, please send it directly to me (see the
AUTHOR section below) rather than posting it to one of the newsgroups.
Although I try to keep up with the comp.lang.perl.* groups, all too often I
miss news (flaky news server, articles expiring before I caught them, 1200
articles to wade through and I missed one that I was interested in, etc.).

If you have a problem using Date::Manip that perhaps isn't a bug (can't
figure out the syntax, etc.), you're in the right place.  Go right back to
the top of this man page and start reading.  If this still doesn't answer
your question, mail me (again, please mail me rather than post to the
newsgroup).

=head1 AUTHOR

Sullivan Beck (sbeck@cise.ufl.edu)

You can always get the newest beta version of Date::Manip (which may fix
problems in the current CPAN version) from my home page:

http://www.cise.ufl.edu/~sbeck/

=cut
