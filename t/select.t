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
my $frm4=$top->Frame->pack;
my $frm3=$top->Frame->pack;
#------------- use MiniCalendar widget:
# use default values

my $minical=$frm1->MiniCalendar(
)->pack(-pady => 4, -padx => 4);
#-------------

my $text = $frm2->Label(
  -text => "
  The selected date should be today.

  Try also selecting other days. Scrolling back
  and forth must not alter the selected day.
  Check the selected date with the 'Check' button.

  Click 'Ok' if all seems to work correctly.
  Otherwise click 'Not Ok'
  ",
)->pack;



my $l_check;
my $b_check = $frm4->Button(
  -text      => "Check",
  -width     => 7,
  -command   => sub{
    my ($y, $m, $d) = $minical->date;
    my $text = "$d.$m.$y";
    $l_check->configure(-text => $text);
   },
)->pack(-side => "left", -padx => 2, -pady => 2);
$l_check = $frm4->Label(
  -text => "",
  -width => 14,
  -relief => "sunken",
)->pack(-side => "left", -padx => 2, -pady => 2);

#-------
my $b_ok = $frm3->Button(
  -text      => "Ok",
  -width     => 4,
  -command   => sub{
    ok(1, "ok button");
    exit;
   },
)->pack(-side => "left", -padx => 2, -pady => 2);

my $b_nok = $frm3->Button(
  -text      => "Not Ok",
  -width     => 8,
  -command   => sub{
    ok(0, "not ok button");
    exit;
   },
)->pack(-side => "left", -padx => 2, -pady => 2);


MainLoop;

__END__

 vim:foldmethod=marker:foldcolumn=4:ft=perl
