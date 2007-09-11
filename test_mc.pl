#!
#
# interactive test script: run all tests from .\t
# in interactive mode
use strict;
use warnings;
use lib "lib/Tk/";

foreach my $script (<t/*.t>){
  $ENV{INTERACTIVE_MODE} = 1;
  system "perl $script";
}