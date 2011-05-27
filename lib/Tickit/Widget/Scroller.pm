#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package Tickit::Widget::Scroller;

use strict;
use warnings;
use base qw( Tickit::Widget );

our $VERSION = '0.01';

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

=head1 CONSTRUCTOR

=cut

=head2 $scroller = Tickit::Widget::Scroller->new

Constructs a new C<Tickit::Widget::Scroller> object. The new object will start
with an empty list of items.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{items} = [];

   $self->{start_item} = 0;
   $self->{start_partial} = 0;

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
   $self->SUPER::reshape;

   undef $self->{itemheights};
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
      my $lines = $win->lines;

      my $oldlast = $oldsize ? ( $self->item2line( $oldsize-1 ) )[1] : -1;

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
      }
      else {
         $self->render_lines( $firstblank, $firstblank + $added );
      }
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
         last if $itemidx == $#$items;

         $delta -= $itemheight;
         $scroll_amount += $itemheight;

         $itemidx++;
      }
      elsif( $delta < 0 ) {
         last if $itemidx == 0;
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

      my $lines = $window->lines;

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
   my $lines = $window->lines;

   my $items = $self->{items};

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
   my $lines = $window->lines;

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

=head2 $firstline = $scroller->item2line( $itemidx )

=head2 ( $firstline, $lastline ) = $scroller->item2line( $itemidx )

Returns the first display line in the window of the item at the given index.
In list context also returns the last line. If no window has been set, or the
item is not visible, C<undef> or an empty list are returned. If the item is
partially on display, then C<$firstline> may be negative, or C<$lastline> may
be higher than there are lines in the window. C<$itemidx> may be given
negative, to count backwards from the last item.

=cut

sub item2line
{
   my $self = shift;
   my ( $want_itemidx ) = @_;

   my $window = $self->window or return;
   my $lines = $window->lines;

   my $items = $self->{items};

   if( $want_itemidx < 0 ) {
      $want_itemidx += @$items;

      croak '$itemidx out of bounds' if $want_itemidx < 0;
   }
   else {
      croak '$itemidx out of bounds' if $want_itemidx >= @$items;
   }

   return if $want_itemidx < $self->{start_item};
   my $itemidx = $self->{start_item};

   my $firstline = -$self->{start_partial};

   while( $itemidx < @$items and $firstline < $lines ) {
      my $itemheight = $self->_itemheight( $itemidx );
      if( $want_itemidx == $itemidx ) {
         return $firstline, $firstline + $itemheight - 1 if wantarray;
         return $firstline;
      }

      $firstline += $itemheight;
      $itemidx++;
   }

   return;
}

sub render
{
   my $self = shift;

   my $win = $self->window or return;

   $self->render_lines( 0, $win->lines );
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

=head1 TODO

=over 4

=item *

Item::RichText - will depend on L<String::Tagged>

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
