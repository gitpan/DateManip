#!/usr/local/bin/perl

# This takes a list of strings of the form:
#   ARG1
#   ...
#   ARGn
#   NOTE
#   EXP
# where ARGi are a list of arguments to pass to the appropriate function
# NOTE is an optional note to print if the test fails, and EXP is the
# expected parse value.  NOTE must begin with the character ">".  All tests
# must be separated by a blank line from the next test.  If EXP starts with
# a "~", it is treated as approximate.
#
# $funcref is the function to pass the arguments to, $tests is the list of
# newline separated strings, $runtests is a value passed in if it is called
# using the runtests command, @extra are extra arguments which are added
# to the function call.
#
# If $runtests=0, everything is printed.  If it equals -N, only test N is
# run.  If it equals N, start at test N.
sub test_Func {
  my($funcref,$tests,$runtests,@extra)=@_;
  my(@tests)=split(/\n/,$tests);
  my($comment)="#";
  my($test,@args,$note,$exp,$ans,$approx,$ans1,$ans2,$t)=();

  $t=0;
  while (@tests) {

    # Find the first argument
    while(@tests) {
      $test=$tests[0];
      $test =~ s/^\s+//;
      shift(@tests), next  if ($test eq ""  or  $test =~ /^$comment/);
      last;
    }

    $t++;
    # Read all arguments, note, and expected value
    @args=();
    while(@tests) {
      $test=shift(@tests);
      $test =~ s/^\s+//;
      last  if ($test eq "");
      next  if ($test =~ /^$comment/);
      if ($test eq "nil") {
        push(@args,"");
      } else {
        push(@args,$test);
      }
    }

    next  if (defined $runtests and $runtests<0 and $t!=-$runtests);
    next  if (defined $runtests and $runtests>0 and $t<$runtests);

    # Separate out the note and expected value
    $exp=pop(@args);
    $exp=~ s/\s+//g;
    $exp=~ s/_/ /g;

    $note="";
    if ($args[$#args] =~ /^>/) {
      $note=pop(@args);
      $note =~ s/^>\s*//;
    }

    # An approximate answer is good to within 10 seconds.
    $approx=0;
    if ($exp =~ /^~/) {
      $approx=1;
      $exp=~ s/^~//;
      $ans1=DateCalc($exp,"-10");
      $ans2=DateCalc($exp,"+10");
    }

    $ans=&$funcref(@args,@extra);
    $bad=1;
    $bad=0  if ($exp eq $ans  or  $exp eq "nil" && $ans eq "");
    $bad=0  if ($approx  and  $ans ge $ans1 && $ans le $ans2);

    if ($bad) {
      warn "########################\n";
      warn "Expected = $exp\n";
      warn "Got      = $ans\n";
      warn "========================\n";
      foreach $test (@args) {
        if (defined $test) {
          warn "Test     = $test\n";
        } else {
          warn "Test     = nil\n";
        }
      }
      foreach $test (@extra) {
        if (defined $test) {
          warn "Extra    = $test\n";
        } else {
          warn "Extra    = nil\n";
        }
      }
      warn "Note     = $note\n"   if ($note);
      warn "########################\n";
      print "not ok $t\n";
    } else {
      print "ok $t\n"  if (! defined $runtests or $runtests==0);
    }
  }
  print "$t tests\n"  if (defined $runtests);
}

1;
