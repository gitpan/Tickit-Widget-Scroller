#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2012 -- leonerd@leonerd.org.uk

package Tickit::Widget::Scroller;

use strict;
use warnings;
use base qw( Tickit::Widget );
Tickit::Widget->VERSION( '0.06' );

our $VERSION = '0.04';

use Carp;

=head1 NAME

C<Tickit::Widget::Scroller> - a widget displaying a scrollable collection of
items

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Scroller;
 use Tickit::Widget::Scroller::Item::Text;
 
 my $tickit = Tickit->new;
 
 my $scroller = Tickit::Widget::Scroller->new;

 $scroller->push(
    Tickit::Widget::Scroller::Item::Text->new( "Hello world" ),
    Tickit::Widget::Scroller::Item::Text->new( "Here are some lines" ),
    map { Tickit::Widget::Scroller::Item::Text->new( "<Line $_>" ) } 1 .. 50,
 );
 
 $tickit->set_root_widget( $scroller );
 
 $tickit->run

=head1 DESCRIPTION

This class provides a widget which displays a scrollable list of items. The
view of the items is scrollable, able to display only a part of the list.

A Scroller widget stores a list of instances implementing the
C<Tickit::Widget::Scroller::Item> interface.

=cut

=head1 KEYBINDINGS

The following keys are bound

=over 2

=item * Down

Scroll one line down

=item * Up

Scroll one line up

=item * PageDown

Scroll half a window down

=item * PageUp

Scroll half a window up

=item * Ctrl-Home

Scroll to the top

=item * Ctrl-End

Scroll to the bottom

=back

=cut

=head1 CONSTRUCTOR

=cut

=head2 $scroller = Tickit::Widget::Scroller->new( %args )

Constructs a new C<Tickit::Widget::Scroller> object. The new object will start
with an empty list of items.

Takes the following named arguments:

=over 8

=item gravity => STRING

Optional. If given the value C<bottom>, resize events will attempt to preserve
the item at the bottom of the screen. Otherwise, will preserve the top.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $gravity = delete $args{gravity} || "top";

   my $self = $class->SUPER::new( %args );

   # We're going to cache window height because we need pre-resize height
   # during resize event
   $self->{window_lines} = undef;

   $self->{items} = [];

   $self->{start_item} = 0;
   $self->{start_partial} = 0;

   $self->{gravity_bottom} = $gravity eq "bottom";

   return $self;
}

=head1 METHODS

=cut

sub cols  { 1 }
sub lines { 1 }

sub _item
{
   my $self = shift;
   my ( $idx ) = @_;
   return $self->{items}[$idx];
}

sub _itemheight
{
   my $self = shift;
   my ( $idx ) = @_;
   return $self->{itemheights}[$idx] if defined $self->{itemheights}[$idx];
   return $self->{itemheights}[$idx] = $self->_item( $idx )->height_for_width( $self->window->cols );
}

sub reshape
{
   my $self = shift;

   my ( $itemidx, $itemline ) = $self->line2item( $self->{gravity_bottom} ? -1 : 0 );
   $itemline -= $self->_itemheight( $itemidx ) if $self->{gravity_bottom} and defined $itemidx;

   $self->SUPER::reshape;

   $self->{window_lines} = $self->window->lines;

   undef $self->{itemheights};

   if( defined $itemidx ) {
      $self->scroll_to( $self->{gravity_bottom} ? -1 : 0, $itemidx, $itemline );
   }
}

sub window_lost
{
   my $self = shift;
   $self->SUPER::window_lost( @_ );

   my ( $line, $offscreen ) = $self->item2line( -1, -1 );

   $self->{pending_scroll_to_bottom} = 1 if defined $line;

   undef $self->{window_lines};
}

sub window_gained
{
   my $self = shift;
   my ( $win ) = @_;

   $self->{window_lines} = $win->lines;

   $self->SUPER::window_gained( $win );

   if( delete $self->{pending_scroll_to_bottom} ) {
      $self->scroll_to_bottom;
   }
}

=head2 $scroller->push( @items )

Append the given items to the end of the list.

If the Scroller is already at the tail (that is, the last line of the last
item is on display), the newly added items will be displayed, possibly by
scrolling downward if required. While the scroller isn't adjusted, by using
any of the C<scroll> methods, it will remain following the tail of the items,
scrolling itself upwards as more are added.

=cut

sub push
{
   my $self = shift;

   my $items = $self->{items};

   my $oldsize = @$items;

   push @$items, @_;

   if( my $win = $self->window ) {
      my $lines = $self->{window_lines};

      my $oldlast = $oldsize ? $self->item2line( $oldsize-1, -1 ) : -1;

      # Previous tail is on screen if $oldlast is defined and less than $lines
      # If not, don't bother drawing or scrolling
      return unless defined $oldlast and $oldlast < $lines;

      my $firstblank = $oldlast + 1;
      my $spare = $lines - $firstblank;

      my $added = 0;
      $added += $self->_itemheight( $_ ) for $oldsize .. $#$items;

      if( $added > $spare ) {
         $self->render_lines( $lines - $spare, $lines ) if $added < $lines;
         $self->scroll( $added - $spare );
         # ->scroll already did $win->restore
      }
      else {
         $self->render_lines( $firstblank, $firstblank + $added );
         $win->restore;
      }
   }
}

=head2 $scroller->shift( $count )

Remove the given number of items from the start of the list.

If any of the items are on display, the Scroller will be scrolled upwards an
amount sufficient to close the gap, ensuring the first remaining item is now
at the top of the display.

=cut

sub shift :method
{
   my $self = shift;
   my ( $count ) = @_;

   defined $count or $count = 1;

   my $items = $self->{items};

   croak '$count out of bounds' if $count <= 0;
   croak '$count out of bounds' if $count > @$items;

   my ( $lastline, $offscreen ) = $self->item2line( $count - 1, -1 );

   if( defined $lastline ) {
      $self->scroll( $lastline + 1);
      # ->scroll implies $win->restore
   }

   splice @$items, 0, $count;
   splice @{ $self->{itemheights} }, 0, $count;
   $self->{start_item} -= $count;

   if( !defined $lastline and $offscreen eq "below" ) {
      $self->scroll_to_top;
      # ->scroll implies $win->restore
   }
}

=head2 $scroller->scroll( $delta )

Move the display up or down by the given C<$delta> amount; with positive
moving down. This will be a physical count of displayed lines; if some items
occupy multiple lines, then fewer items may be scrolled than lines.

=cut

sub scroll
{
   my $self = shift;
   my ( $delta ) = @_;

   return unless $delta;

   my $window = $self->window;
   my $items = $self->{items};
   @$items or return;

   my $itemidx = $self->{start_item};
   my $partial = $self->{start_partial};
   my $scroll_amount = 0;

   if( $partial > 0 ) {
      $delta += $partial;
      $scroll_amount -= $partial;
      $partial = 0;
   }

   while( $delta ) {
      my $itemheight = $self->_itemheight( $itemidx );

      if( $delta >= $itemheight ) {
         $partial = $itemheight - 1, last if $itemidx == $#$items;

         $delta -= $itemheight;
         $scroll_amount += $itemheight;

         $itemidx++;
      }
      elsif( $delta < 0 ) {
         $partial = 0, last if $itemidx == 0;
         $itemidx--;

         $itemheight = $self->_itemheight( $itemidx );

         $delta += $itemheight;
         $scroll_amount -= $itemheight;
      }
      else {
         $partial = $delta;
         $scroll_amount += $delta;

         $delta = 0;
      }
   }

   if( $itemidx != $self->{start_item} or
       $partial != $self->{start_partial} ) {
      $self->{start_item}    = $itemidx;
      $self->{start_partial} = $partial;

      my $lines = $self->{window_lines};

      if( abs( $scroll_amount ) < $lines and 
          $window->scroll( $scroll_amount, 0 ) ) {

         if( $scroll_amount > 0 ) {
            $self->render_lines( $lines - $scroll_amount, $lines );
         }
         else {
            $self->render_lines( 0, -$scroll_amount );
         }

         $self->window->restore;
      }
      else {
         $self->redraw;
      }
   }
}

=head2 $scroller->scroll_to( $line, $itemidx, $itemline )

Moves the display up or down so that display line C<$line> contains line
C<$itemline> of item C<$itemidx>. Any of these counts may be negative to count
backwards from the display lines, items, or lines within the item.

=cut

sub scroll_to
{
   my $self = shift;
   my ( $line, $itemidx, $itemline ) = @_;

   my $window = $self->window or return;
   my $lines = $self->{window_lines};

   my $items = $self->{items};
   @$items or return;

   if( $line < 0 ) {
      $line += $lines;

      croak '$line out of bounds' if $line < 0;
   }
   else {
      croak '$line out of bounds' if $line >= $lines;
   }

   if( $itemidx < 0 ) {
      $itemidx += @$items;

      croak '$itemidx out of bounds' if $itemidx < 0;
   }
   else {
      croak '$itemidx out of bounds' if $itemidx >= @$items;
   }

   my $itemheight = $self->_itemheight( $itemidx );

   if( $itemline < 0 ) {
      $itemline += $itemheight;

      croak '$itemline out of bounds' if $itemline < 0;
   }
   else {
      croak '$itemline out of bounds' if $itemline >= $itemheight;
   }

   $line -= $itemline;

   while( $line > 0 ) {
      if( $itemidx == 0 ) {
         $line = 0;
         last;
      }

      $itemheight = $self->_itemheight( --$itemidx );

      $line -= $itemheight;
   }

   $self->{start_item}    = $itemidx;
   $self->{start_partial} = -$line;

   # TODO: Work out if this is doable by delta scrolling
   $self->redraw;
}

=head2 $scroller->scroll_to_top( $itemidx, $itemline )

Shortcut for C<scroll_to> to set the top line of display; where C<$line> is 0.
If C<$itemline> is undefined, it will be passed as 0. If C<$itemidx> is also
undefined, it will be passed as 0. Calling this method with no arguments,
therefore scrolls to the very top of the display.

=cut

sub scroll_to_top
{
   my $self = shift;
   my ( $itemidx, $itemline ) = @_;

   defined $itemidx  or $itemidx = 0;
   defined $itemline or $itemline = 0;

   $self->scroll_to( 0, $itemidx, $itemline );
}

=head2 $scroller->scroll_to_bottom( $itemidx, $itemline )

Shortcut for C<scroll_to> to set the bottom line of display; where C<$line> is
-1. If C<$itemline> is undefined, it will be passed as -1. If C<$itemidx> is
also undefined, it will be passed as -1. Calling this method with no
arguments, therefore scrolls to the very bottom of the display.

=cut

sub scroll_to_bottom
{
   my $self = shift;
   my ( $itemidx, $itemline ) = @_;

   defined $itemidx  or $itemidx = -1;
   defined $itemline or $itemline = -1;

   $self->scroll_to( -1, $itemidx, $itemline );
}

=head2 $itemidx = $scroller->line2item( $line )

=head2 ( $itemidx, $itemline ) = $scroller->line2item( $line )

Returns the item index currently on display at the given line of the window.
In list context, also returns the line number within item. If no window has
been set, or there is no item on display at that line, C<undef> or an empty
list are returned. C<$line> may be negative to count backward from the last
line on display; the last line taking C<-1>.

=cut

sub line2item
{
   my $self = shift;
   my ( $line ) = @_;

   my $window = $self->window or return;
   my $lines = $self->{window_lines};

   my $items = $self->{items};

   if( $line < 0 ) {
      $line += $lines;

      croak '$line out of bounds' if $line < 0;
   }
   else {
      croak '$line out of bounds' if $line >= $lines;
   }

   my $itemidx = $self->{start_item};
   $line += $self->{start_partial};

   while( $itemidx < @$items ) {
      my $itemheight = $self->_itemheight( $itemidx );
      if( $line < $itemheight ) {
         return $itemidx, $line if wantarray;
         return $itemidx;
      }

      $line -= $itemheight;
      $itemidx++;
   }

   return;
}

=head2 $line = $scroller->item2line( $itemidx, $itemline )

=head2 ( $line, $offscreen ) = $scroller->item2line( $itemidx, $itemline )

Returns the display line in the window of the given line of the item at the
given index. C<$itemidx> may be given negative, to count backwards from the
last item. C<$itemline> may be negative to count backward from the last line
of the item.

In list context, also returns a value describing the offscreen nature of the
item. For items fully on display, this value is C<undef>. If the given line of
the given item is not on display because it is scrolled off either the top or
bottom of the window, this value will be either C<"above"> or C<"below">
respectively.

=cut

sub item2line
{
   my $self = shift;
   my ( $want_itemidx, $want_itemline ) = @_;

   my $window = $self->window or return;
   my $lines = $self->{window_lines};

   my $items = $self->{items};
   @$items or return;

   if( $want_itemidx < 0 ) {
      $want_itemidx += @$items;

      croak '$itemidx out of bounds' if $want_itemidx < 0;
   }
   else {
      croak '$itemidx out of bounds' if $want_itemidx >= @$items;
   }

   my $itemheight = $self->_itemheight( $want_itemidx );

   defined $want_itemline or $want_itemline = 0;
   if( $want_itemline < 0 ) {
      $want_itemline += $itemheight;

      croak '$itemline out of bounds' if $want_itemline < 0;
   }
   else {
      croak '$itemline out of bounds' if $want_itemline >= $itemheight;
   }

   if( $want_itemidx < $self->{start_item} ) {
      return ( undef, "above" ) if wantarray;
      return;
   }

   my $itemidx = $self->{start_item};

   my $line = -$self->{start_partial};

   while( $itemidx < @$items and $line < $lines ) {
      my $itemheight = $self->_itemheight( $itemidx );
      if( $want_itemidx == $itemidx ) {
         $line += $want_itemline;

         last if $line >= $lines;
         return $line;
      }

      $line += $itemheight;
      $itemidx++;
   }

   return ( undef, "below" ) if wantarray;
   return;
}

sub render
{
   my $self = shift;
   my %args = @_;

   my $rect = $args{rect};

   my $win = $self->window or return;

   $self->render_lines( $rect->top, $rect->bottom );
}

sub render_lines
{
   my $self = shift;
   my ( $startline, $endline ) = @_;

   my $win = $self->window or return;
   my $cols = $win->cols;

   my $items = $self->{items};

   my $line = 0;
   my $itemidx = $self->{start_item};

   if( my $partial = $self->{start_partial} ) {
      $line -= $partial;
   }

   while( $line < $endline and $itemidx < @$items ) {
      my $item       = $self->_item( $itemidx );
      my $itemheight = $self->_itemheight( $itemidx );

      my $top = $line;
      my $firstline = ( $startline > $line ) ? $startline - $top : 0;

      $itemidx++;
      $line += $itemheight;

      next if $firstline >= $itemheight;

      my $lastline =  ( $endline < $line ) ? $endline - $top : $itemheight;

      $item->render( $win,
         top       => $top,
         firstline => $firstline,
         lastline  => $lastline - 1,
         width     => $cols,
         height    => $itemheight,
      );
   }

   while( $line < $endline ) {
      $win->goto( $line, 0 );
      $win->erasech( $cols );
      $line++;
   }
}

my %bindings = (
   Down => sub { $_[0]->scroll( +1 ) },
   Up   => sub { $_[0]->scroll( -1 ) },

   PageDown => sub { $_[0]->scroll( +int( $_[0]->window->lines / 2 ) ) },
   PageUp   => sub { $_[0]->scroll( -int( $_[0]->window->lines / 2 ) ) },

   'C-Home' => sub { $_[0]->scroll_to_top },
   'C-End'  => sub { $_[0]->scroll_to_bottom },
);

sub on_key
{
   my $self = shift;
   my ( $type, $str ) = @_;

   if( $type eq "key" and my $code = $bindings{$str} ) {
      $code->( $self, $str );
      return 1;
   }

   return 0;
}

sub on_mouse
{
   my $self = shift;
   my ( $ev, $button_dir, $line, $col ) = @_;

   return unless $ev eq "wheel";

   $self->scroll( $button_dir eq "down" ? 5 : -5 );
}

=head1 TODO

=over 4

=item *

Abstract away the "item storage model" out of the actual widget. Implement
more storage models, such as database-driven ones.. more dynamic.

=item *

Keybindings

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
