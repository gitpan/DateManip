#!/usr/local/bin/perl -w

require 5.001;
use Date::Manip;
@Date::Manip::TestArgs=();
$runtests=shift(@ARGV);

# Here we are testing that an exception is thrown; we do not expect
# any result to be returned, so we can't use test.pl.
#
print "1..1\n"  if (! $runtests);
&Date_Init(@Date::Manip::TestArgs);

my $bad_date = 'today';
# ParseDate handles it, but ConvTZ shouldn't.
die unless ParseDate($bad_date);
eval {
    Date_ConvTZ($bad_date, '+0000', '+0100');
};
if ($@) {
    if ($@ =~ /is not a Date::Manip object/) {
	print "ok 1\n";
    }
    else {
	warn "unexpected exception: $@\n";
	print "not ok 1\n";
    }
}
else {
    warn "expected exception was not thrown\n";
    print "not ok 1 \n";
}

1;
