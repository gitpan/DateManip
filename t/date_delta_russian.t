#!/usr/local/bin/perl -w

require 5.001;
use Date::Manip;
@Date::Manip::TestArgs=();
$runtests=shift(@ARGV);
if ( -f "t/test.pl" ) {
  require "t/test.pl";
} elsif ( -f "test.pl" ) {
  require "test.pl";
} else {
  die "ERROR: cannot find test.pl\n";
}
$ntest=2;

print "1..$ntest\n"  if (! $runtests);
&Date_Init(@Date::Manip::TestArgs);

$calcs="

����� 20 ������ 1996 12�00
����� �� 3 ��� 2 ���� 20 �����
  1996111509:40:00

������� 4 ������� 2001 23�00
������ �� 1 ������ 2 ��� 3 ����
  2001121411:00:00

";

print "DateCalc (Russian,date,delta)...\n";
&Date_Init("Language=Russian","DateFormat=non-US","Internal=0");
&test_Func($ntest,\&DateCalc,$calcs,$runtests,2);

1;
