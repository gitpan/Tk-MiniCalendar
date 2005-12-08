#########################
use Test::More;
use Tk;
BEGIN { plan tests => 2 };
use Tk::MiniCalendar;
ok(1, "load module"); # If we made it this far, we're ok.

#########################
my $top = MainWindow->new;

my $frm1=$top->Frame->pack;
my $frm2=$top->Frame->pack;
my $frm3=$top->Frame->pack;
#------------- use MiniCalendar widget:
# use english day and month names

eval {
 my $minical=$frm1->MiniCalendar(
  -day => 32,  # Error in date
  -month => 8,
  -year => 2003,
 )->pack(-pady => 4, -padx => 4);
};
print "$@\n";
ok($@, "Error in date");
#-------------

#MainLoop;  # do not start GUI ...

__END__

 vim:foldmethod=marker:foldcolumn=4:ft=perl
