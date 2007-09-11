package Tk::MiniCalendar;

our $VERSION = "0.09";

use Tk;
use Tk::BrowseEntry;
use Tk::XPMs qw(:arrows);
use Carp;
use Date::Calc qw(
  check_date
  Days_in_Month
  Day_of_Week
  Add_Delta_Days
  Today
);
use strict;

require Tk::Frame;
use base qw(Tk::Frame);
#use Data::Dumper;

Construct Tk::Widget 'MiniCalendar';

# POD Section {{{

=head1 NAME

Tk::MiniCalendar - simple calendar widget for date selection

=head1 SYNOPSIS

 use Tk;
 use Tk::MiniCalendar;

 my $minical = <PARENT>->MiniCalendar(-day   => $dd, 
                                      -month => $mm, 
                                      -year  => $yyyy,
                                      -day_names   => \@DAYNAMES,
                                      -month_names => \@MONTHNAMES);

 $minical->pack;
 # or:
 $minical->grid( ... );

 my ($yyyy, $mm, $dd) = $minical->date; # --> (2004, 09, 16)

=head1 DESCRIPTION

C<Tk::MiniCalendar> provides a tiny calendar widget
which can be used to select valid dates.

=head2 Graphical Representation

The widget looks like:

  +------------------------------+
  |<<  <   September 2004   >  >>|
  |                              |
  |  Mo  Di  Mi  Do  Fr  Sa  So  |
  |           1   2   3   4   5  |
  |   6   7   8   9  10  11  12  |
  |  13  14  15 [16] 17  18  19  |
  |  20  21  22  23  24  25  26  |
  |  27  28  29  30              |
  +------------------------------+

The year can be entered directly into the corresponding entry field. The "<<" and ">>"
buttons allow the user to scroll one year back or forth and the "<" and ">"
buttons can be used for scrolling through the months of a year. The month
can also be selected directly from a pulldown menu which can be invoked
by clicking the monthname.

Clicking with mouse button one on a day selects that day. The selected day
can be retrieved with the $minical->date() method.

=head2 Handlers

It is possible to register user provided handlers for the MiniCalendar widget.
You may for example register a "double-button-1" handler which is invoked by
doubleclicking one of the days.

Example:

 $minical->register('<Double-1>', \&double_1_handler);
 $minical->register('<Button-3>', \&button_3_handler);

Only the following event specifications are recognized:

 <Button-1>  <Double-1>
 <Button-2>  <Double-2>
 <Button-3>  <Double-3>

If one of those events occurs on one of the displayed days, the registered callback
is invoked with the following parameters:

 $yyyy, $mm, $dd   (year, month and day)

NOTE: If there are two handlers for <Button-n> and <Double-n> then both handlers are
invoked in case of a double-button-n event because a double-button-n event is also a
button-n event.

=head1 EXAMPLE

Here is a fullblown example for the usage of Tk::MiniCalendar

 use Tk;
 use Tk::MiniCalendar;

 use strict;
 my $top = MainWindow->new;

 my $frm1 = $top->Frame->pack;  # Frame to place MiniCalendar in

 my $minical = $frm1->MiniCalendar->pack;

 my $frm2 = $top->Frame->pack;  # Frame for Ok Button
 my $b_ok = $frm2->Button(-text => "Ok",
                -command => sub {
                  my ($year, $month, $day) = $minical->date;
                  print "Selected date: $year/$month/$day\n";
                  exit;
                },
            );
 MainLoop;

=head1 METHODS

The following methods are provided by Tk::MiniCalendar:

=cut

#}}}


# valid options for MiniCalendar:
my @validArgs = qw( -day -month -year -day_names -month_names);

my $mtxt;

sub Populate { # {{{
  my ($w, $args) = @_;
# print ">", join("|", @_), "\n";
# print Dumper(@_);

  # get parameters which are only for me ...
  my ($y, $m, $d) = Today;
  {
    my %received;
    @received{@validArgs} = @$args{@validArgs};
    # ... and remove them before we give $args to SUPER::Populate ...
#   delete @$args{ @validArgs };
#   print Dumper $args;

    # defaults:
    $w->{DAYNAME}  = [ qw(Mo Di Mi Do Fr Sa So)];
    $w->{MONNAME}  = [ qw(Januar Februar März April Mai Juni Juli August September Oktober November Dezember)];
    $w->{DAY}      = $d; # default is Today
    $w->{MONTH}    = $m;
    $w->{YEAR}     = $y;
    $w->{CALLBACK} = {};
    $w->{MON_ARR}  = [];
    # Global array of 6 x 7 day labels
    # $MON_ARR[$i][$j] is on position $j in line $i
    #                  0 <= $i <= 5,  0 <= $j <= 6


    # handle options:
    $w->{DAY}      = $received{"-day"}         if defined $received{"-day"};
    $w->{MONTH}    = $received{"-month"}       if defined $received{"-month"};
    $w->{YEAR}     = $received{"-year"}        if defined $received{"-year"};
    $w->{DAYNAME}  = $received{"-day_names"}   if defined $received{"-day_names"};
    $w->{MONNAME}  = $received{"-month_names"} if defined $received{"-month_names"};
    # check: 7 names for DAYNAME, 12 names for MONNAME
    if (defined $received{"-day_names"} and @{ $received{"-day_names"}} != 7){
      croak "error in names array for -day_names option: must provide 7 names";
    }
    if (defined $received{"-month_names"} and @{ $received{"-month_names"}} != 12){
      croak "error in names array for -month_names option: must provide 12 names";
    }
  } # %received goes out of scope and will be deleted ...
  croak "error in initial date: ", $w->{YEAR}, ", ", $w->{MONTH}, ", ", $w->{DAY}
    unless check_date($w->{YEAR}, $w->{MONTH}, $w->{DAY});

  $w->{YEAR_BAK}  = $w->{YEAR};
  # selected day: (need not be visible in current month)
  $w->{SEL_DAY}   = $w->{DAY};
  $w->{SEL_MONTH} = $w->{MONTH};
  $w->{SEL_YEAR}  = $w->{YEAR};

  $w->SUPER::Populate($args); # handle other widget options like -relief, -background, ...

  $w->ConfigSpecs(
    -day      => [METHOD => "day", "Day", $d],
    -month    => [METHOD => "month", "Month", $m],
    -year     => [METHOD => "year", "Year", $y],
    -day_names     => [PASSIVE => "day_names", "Day_names", \@{ $w->{DAYNAME} }],
    -month_names   => [PASSIVE => "month_names", "Month_names", \@{ $w->{MONNAME} }],
  );

  #
  # Contents of widget:
  # ===================

  my $frm1 = $w->Frame->pack();
  my $frm2 = $w->Frame()->pack();
  my $pfeil_ll = $w->Pixmap(-data => arrow_ppage_xpm);
  my $pfeil_nn = $w->Pixmap(-data => arrow_npage_xpm);
  my $pfeil_l  = $w->Pixmap(-data => arrow_prev_xpm);
  my $pfeil_n  = $w->Pixmap(-data => arrow_next_xpm);

  # Navigation
  my $bll = $frm1->Button(
   #-text => "<<",
    -image => $pfeil_ll,
    -command => sub{
      $w->{YEAR} --;
      display_month($w,  $w->{YEAR}, $w->{MONTH});
    },
   #-width => 2,
  )->pack(-side => "left");
  
  my $bl = $frm1->Button(
   #-text => "<",
    -image => $pfeil_l,
    -command => sub{
      $w->{YEAR} -- if $w->{MONTH} == 1;
      $w->{MONTH} --;
      $w->{MONTH} = 12 if $w->{MONTH} == 0;
      display_month($w,  $w->{YEAR}, $w->{MONTH});
    },
   #-width => 2,
  )->pack(-side => "left");


  $mtxt = $w->{MONNAME}[$w->{MONTH}-1];
  $w->{l_mm} = $frm1->BrowseEntry(
    -variable   => \$mtxt,
    -width      => 10,
    -background => "white",
    -listheight => 12,
    -browsecmd => sub {
        $w->{MONTH} = index_of($w, $mtxt);
        display_month($w,  $w->{YEAR}, $w->{MONTH});
     },
     -choices => $w->{MONNAME},
  )->pack(-side => "left");

  sub index_of {
    my $w = shift;
    my $m_name = shift;
    my $i = 0;
    foreach my $mnm ( @{ $w->{MONNAME} }){
      $i++;
      return $i if $mnm eq $m_name;
    }
    return $i;
  }


  my $e_yyyy = $frm1->Entry(
    -width => 6,
    -textvariable => \$w->{YEAR},
  )->pack(-side => "left");


  # Navigation
  my $br = $frm1->Button(
   #-text => ">",
    -image => $pfeil_n,
    -command => sub{
      $w->{YEAR} ++ if $w->{MONTH} == 12;
      $w->{MONTH} ++;
      $w->{MONTH} = 1 if $w->{MONTH} > 12;
      display_month($w,  $w->{YEAR}, $w->{MONTH});
    },
   #-width => 2,
  )->pack(-side => "left");
  
  my $brr = $frm1->Button(
   #-text => ">>",
    -image => $pfeil_nn,
    -command => sub{
      $w->{YEAR} ++;
      display_month($w,  $w->{YEAR}, $w->{MONTH});
    },
   #-width => 2,
  )->pack(-side => "left");


  # Calendar frame for month
  my $i = 0;
  foreach my $day ( @{$w->{DAYNAME}}){
    $frm2->Label(
        -text => $day,
        -width => 3,
      )->grid( -column => $i, -row => 0, -sticky => "w", -padx => 1, -pady => 2);
      $i++;
  }
  my $day = " ";
  for ($i=0; $i< 6; $i++){
    for (my $j=0; $j< 7; $j++){
      $w->{MON_ARR}->[$i][$j] = $frm2->Label(
        -text => $day,
        -width => 4,
        -background => "#FFFFFF",
      )->grid( -column => $j, -row => $i + 1, -sticky => "w", -padx => 0, -pady => 0);

      my($ii, $jj) = ($i, $j); # $ii and $jj are variables in a closure ...

      $w->{MON_ARR}->[$i][$j]->bind('<Button-1>', sub {
               _sel($w, $ii, $jj);
          }
       );
      $w->{MON_ARR}->[$i][$j]->bind('<Button-2>', sub {
               _b2($w, $ii, $jj);
          }
       );
      $w->{MON_ARR}->[$i][$j]->bind('<Button-3>', sub {
               _b3($w, $ii, $jj);
          }
       );

      $w->{MON_ARR}->[$i][$j]->bind('<Double-1>', sub {
               _d1($w, $ii, $jj);
          }
       );
      $w->{MON_ARR}->[$i][$j]->bind('<Double-2>', sub {
               _d2($w, $ii, $jj);
          }
       );
      $w->{MON_ARR}->[$i][$j]->bind('<Double-3>', sub {
               _d3($w, $ii, $jj);
          }
       );
    }
  }
  $e_yyyy->bind('<Key-Return>', sub {
       if ( $w->{YEAR} =~ /^\s*\d{1,4}\s*$/  and check_date($w->{YEAR}, $w->{MONTH}, 1)){
         display_month($w,  $w->{YEAR}, $w->{MONTH});
       } else {
         # restore old value
         $w->{YEAR} = $w->{YEAR_BAK};
       }
    }
  );
  display_month($w,  $w->{YEAR}, $w->{MONTH});

# print "-----\n";
# print Dumper $w;

} # Populate }}}

# Methods

sub day {
  my ($w, $d) = @_;
  if ($#_ > 0 ){
    $w->{SEL_DAY} = $d;
    display_month($w, $w->{SEL_YEAR}, $w->{SEL_MONTH});
  } else {
    $w->{SEL_DAY};
  }
}

sub month {
  my ($w, $m) = @_;
  if ($#_ > 0 ){
    $w->{SEL_MONTH} = $m;
    display_month($w, $w->{SEL_YEAR}, $w->{SEL_MONTH});
  } else {
    $w->{SEL_MONTH};
  }
}


sub year {
  my ($w, $y) = @_;
  if ($#_ > 0 ){
    $w->{SEL_YEAR} = $y;
    display_month($w, $w->{SEL_YEAR}, $w->{SEL_MONTH});
  } else {
    $w->{SEL_YEAR};
  }
}

sub date{ #{{{ -----------------------------------------------------

=head2 my ($year, $month, $day) = $minical->date()

Returns the selected date from Tk::MiniCalendar.
Day and month numbers are always two digits (with leading zeroes).

=cut

  my ($w) = @_;
  my $yyyy = sprintf("%4d",  $w->{SEL_YEAR});
  my $mm   = sprintf("%02d", $w->{SEL_MONTH});
  my $dd   = sprintf("%02d", $w->{SEL_DAY});
  return ($yyyy, $mm, $dd);
} # date }}}

sub select_date{ #{{{ ----------------------------------------------

=head2 $minical->select_date($year, $month, $day)

Selects a date and positions the MiniCalendar to the corresponding year
and month. The selected date is highlighted.

=cut

  my ($w, $yyyy, $mm, $dd) = @_;
  if (check_date($yyyy, $mm, $dd) ){
    $w->{SEL_YEAR} = $yyyy;
    $w->{SEL_MONTH} = $mm;
    $w->{SEL_DAY} = $dd;
    $w->configure(-day => $dd, -month => $mm, -year => $yyyy);
    display_month($w, $yyyy, $mm);
  } else {
    croak "Error in date: $yyyy, $mm, $dd";
  }
} # select_date }}}

sub prev_day{ #{{{ ----------------------------------------------

=head2 $minical->prev_day()

Sets the calendar to the previous day.
The selected date is highlighted.

=cut

  my ($w) = @_;
  my ($yyyy, $mm, $dd) = Add_Delta_Days($w->date, -1);
  if (check_date($yyyy, $mm, $dd) ){
    $w->{SEL_YEAR} = $yyyy;
    $w->{SEL_MONTH} = $mm;
    $w->{SEL_DAY} = $dd;
    display_month($w, $yyyy, $mm);
  } else {
    croak "Error in date: $yyyy, $mm, $dd";
  }
} # prev_day }}}

sub next_day{ #{{{ ----------------------------------------------

=head2 $minical->next_day()

Sets the calendar to the next day.
The selected date is highlighted.

=cut

  my ($w) = @_;
  my ($yyyy, $mm, $dd) = Add_Delta_Days($w->date, 1);
  if (check_date($yyyy, $mm, $dd) ){
    $w->{SEL_YEAR} = $yyyy;
    $w->{SEL_MONTH} = $mm;
    $w->{SEL_DAY} = $dd;
    display_month($w, $yyyy, $mm);
  } else {
    croak "Error in date: $yyyy, $mm, $dd";
  }
} # next_day }}}

sub display_month{ #{{{ --------------------------------------------

=head2 $minical->display_month($year, $month)

Displays the specified month.

=cut

  my ($w, $yyyy, $mm) = @_;

  croak "error in date:  $mm, $yyyy" unless check_date($yyyy, $mm, 1);

  $w->{YEAR}     = $yyyy;
  $w->{YEAR_BAK} = $yyyy;
  $w->{MONTH}     = $mm;

  $mtxt = $w->{MONNAME}[$mm-1],

  my $day = " ";
  my $dim = Days_in_Month($yyyy, $mm);
  my $dow = Day_of_Week($yyyy, $mm, 1);
  for (my $i=0; $i< 6; $i++){
    for (my $j=0; $j< 7; $j++){

      # Setzte $day auf 1, wenn in der ersten Zeile der
      # richtige Wochentag für den ersten Tag des Monats erreicht wird
      $day = 1 if  $day eq " " and $i == 0 and $j+1 == $dow ;
      $w->{MON_ARR}->[$i][$j] -> configure(
        -text => $day,
        -background => "white",
        -foreground => "black",
      );
      $day ++ if $day ne " ";
      $day = " " if $day =~ /\d/ and $day > $dim;
    }
  }

  # if current month contains selected day: highlight it
  _select_day($w, $w->{SEL_YEAR}, $w->{SEL_MONTH}, $w->{SEL_DAY});

} # display_month }}}

# Internal methods

sub _select_day { # {{{
  my ($w, $yyyy, $mm, $dd) = @_;
 #print $w, "\n";
  return if $yyyy != $w->{YEAR};
  return if $mm   != $w->{MONTH};

  # current year and month contains day which must be highlighted
  my $dow = Day_of_Week($yyyy, $mm, 1); # first day in month ...
  my $pos = $dow -2 + $dd;  # position (index) of $dd in linear mode
  #        +--- $dow -1   ($dow == 3)
  #        |
  #        v
  #  0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 .... (indices in linear mode)
  #  Mo Di Mi Do Fr Sa So Mo Di Mi Do Fr Sa So Mo Di Mi Do Fr Sa So ...
  #        1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 ...
  #                                ^
  #                                |
  #                         $dd ---+
  #
  # Example: Do, 9 has linear index 10, i. e. $dow -2 + 9
  # $pos determines $i and $j:
  #
  my $i = int($pos / 7);
  my $j = $pos % 7;
# print " yyyy: $yyyy  mm: $mm  dd: $dd   dow: $dow\npos: $pos, i: $i, j: $j\n";
  $w->{MON_ARR}->[$i][$j]->configure(
    -background => "blue",
    -foreground => "white",
  );

} # _select_day }}}

sub _sel { #{{{
  my ($w, $i, $j) = @_;
  $w->{SEL_YEAR} = $w->{YEAR};
  $w->{SEL_MONTH} = $w->{MONTH};
  my $dow = Day_of_Week($w->{YEAR}, $w->{MONTH}, 1);
  my $pos = $i*7 + $j + 2 - $dow;
#print "i: $i, j: $j  --> pos: $pos\n";
  return if $pos < 1;
  return if $pos > Days_in_Month($w->{YEAR}, $w->{MONTH});
  croak "error in selected date: ", $w->{SEL_YEAR}, ", ", $w->{SEL_MONTH}, ", ", $pos
    unless check_date($w->{SEL_YEAR}, $w->{SEL_MONTH}, $pos);
  $w->{SEL_DAY} = $pos; # ok to use it ...

  display_month($w,  $w->{YEAR}, $w->{MONTH});
  $w->{CALLBACK}->{'<Button-1>'}($w->{SEL_YEAR}, $w->{SEL_MONTH}, $w->{SEL_DAY}) if defined $w->{CALLBACK}->{'<Button-1>'};
} # _sel }}}

# Event Handling: {{{
#
sub register {# {{{
  my ($w, $event, $coderef) = @_;
  $w->{CALLBACK}->{$event} = $coderef;


} # register }}}

sub _b2 {
  my ($w, $i, $j) = @_;
  my ($yyyy, $mm, $dd) = _check_i_j($w, $i, $j);
  return unless defined $yyyy;
  $w->{CALLBACK}->{'<Button-2>'}($yyyy, $mm, $dd) if defined $w->{CALLBACK}->{'<Button-2>'};
}

sub _b3 {
  my ($w, $i, $j) = @_;
  my ($yyyy, $mm, $dd) = _check_i_j($w, $i, $j);
  return unless defined $yyyy;
  $w->{CALLBACK}->{'<Button-3>'}($yyyy, $mm, $dd) if defined $w->{CALLBACK}->{'<Button-3>'};
}

sub _d1 {
  my ($w, $i, $j) = @_;
  my ($yyyy, $mm, $dd) = _check_i_j($w, $i, $j);
  return unless defined $yyyy;
  $w->{CALLBACK}->{'<Double-1>'}($yyyy, $mm, $dd) if defined $w->{CALLBACK}->{'<Double-1>'};
}

sub _d2 {
  my ($w, $i, $j) = @_;
  my ($yyyy, $mm, $dd) = _check_i_j($w, $i, $j);
  return unless defined $yyyy;
  $w->{CALLBACK}->{'<Double-2>'}($yyyy, $mm, $dd) if defined $w->{CALLBACK}->{'<Double-2>'};
}

sub _d3 {
  my ($w, $i, $j) = @_;
  my ($yyyy, $mm, $dd) = _check_i_j($w, $i, $j);
  return unless defined $yyyy;
  $w->{CALLBACK}->{'<Double-3>'}($yyyy, $mm, $dd) if defined $w->{CALLBACK}->{'<Double-3>'};
}


# check, if $i, $j position is a valid date {{{
sub _check_i_j {
  my ($w, $i, $j) = @_;
  my $dow = Day_of_Week($w->{YEAR}, $w->{MONTH}, 1);
  my $pos = $i*7 + $j + 2 - $dow;
  if ($pos > 0 and $pos <= Days_in_Month($w->{YEAR}, $w->{MONTH})) {
    return ($w->{YEAR}, $w->{MONTH}, $pos);
  } else {
    return (undef, undef, undef);
  }
} # _check_i_j }}}
# }}}
1;

__END__

# POD {{{

=head1 AUTHOR

Lorenz Domke, E<lt>lorenz.domke@gmx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Lorenz Domke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

# end POD Section }}}

 vim:foldmethod=marker:foldcolumn=4

