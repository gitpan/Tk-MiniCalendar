#########################
use Test::More;
use Tk;
BEGIN { plan tests => 11 };
use Tk::MiniCalendar;
ok(1, "load module"); # If we made it this far, we're ok.

#########################
my $top = MainWindow->new;

my $frm1=$top->Frame->pack;
my $frm2=$top->Frame->pack;
my $frm3=$top->Frame->pack;
#------------- use MiniCalendar widget:
my $minical=$frm1->MiniCalendar(
  -day => 15,
  -month => 10,
  -year => 1957,
)->pack(-pady => 4, -padx => 4);
#-------------

my $text = $frm2->Label(
  -text => "
  Date should be 15.10.1957;
  Some automtic actions are done when you
  press the 'Start' button ...
  ",
)->pack;

my $b_s;
my $b_ok;
my $b_nok;
$b_s = $frm3->Button(
  -text      => "Start",
  -width     => 4,
  -command   => sub{

    # set to 15.10.1957
    $minical->select_date(1957, 10, 15);
    my ($y, $m, $d) = $minical->date;
    is($y, 1957, "select_date: year");
    is($m, 10, "select_date: month");
    is($d, 15, "select_date: day");


    # set to 11.04.2003
    $minical->select_date(2003, 4, 11);
    ($y, $m, $d) = $minical->date;
    is($y, 2003, "select_date: year");
    is($m, "04", "select_date: month");
    is($d, 11, "select_date: day");

    # display_month
    $minical->display_month(2004, 3);

    $text->configure(-text => "
      Now you should see March 2004

      Press 'Ok' if this is the case.
      Otherwise press 'Not Ok'.
    "
     );
     $b_s->configure(-state => "disabled");
     $b_ok->configure(-state => "normal");
     $b_nok->configure(-state => "normal");

     # check that selected date did not change:
     my ($sy, $sm, $sd) = $minical->date;
     is($sy, 2003, "start date: year");
     is($sm, "04", "start date: month");
     is($sd, 11, "start date: day");


   },
)->pack(-side => "left", -padx => 2, -pady => 2);

$b_ok = $frm3->Button(
  -text      => "Ok",
  -width     => 4,
  -command   => sub{
    ok(1, "display_month");
    exit;
   },
   -state => "disabled",
)->pack(-side => "left", -padx => 2, -pady => 2);

$b_nok = $frm3->Button(
  -text      => "Not Ok",
  -width     => 8,
  -command   => sub{
    ok(0, "not ok button");
    exit;
   },
   -state => "disabled",
)->pack(-side => "left", -padx => 2, -pady => 2);



MainLoop;

__END__

 vim:foldmethod=marker:foldcolumn=4:ft=perl
