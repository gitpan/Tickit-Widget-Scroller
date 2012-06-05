#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package Tickit::Widget::Scroller::Item::Text;

use strict;
use warnings;

our $VERSION = '0.04';

use Tickit::Utils qw( textwidth cols2chars );

=head1 NAME

C<Tickit::Widget::Scroller::Item::Text> - add static text to a Scroller

=head1 SYNOPSIS

 use Tickit::Widget::Scroller;
 use Tickit::Widget::Scroller::Item::Text;

 my $scroller = Tickit::Widget::Scroller->new;

 $scroller->push(
    Tickit::Widget::Scroller::Item::Text->new( "Hello world" )
 );

=head1 DESCRIPTION

This implementation of L<Tickit::Widget::Scroller::Item> displays a simple
static piece of text. It will be wrapped on whitespace (characters matching
the C</\s/> regexp pattern).

=cut

=head1 CONSTRUCTOR

=cut

=head2 $item = Tickit::Widget::Scroller::Item::Text->new( $text, %opts )

Constructs a new text item, containing the given string of text. Once
constructed, the item is immutable.

The following options are recognised in C<%opts>:

=over 4

=item indent => INT

If the text item needs to wrap, indent the second and subsequent lines by this
amount. Does not apply to the first line.

=back

=cut

sub new
{
   my $class = shift;
   my ( $text, %opts ) = @_;

   my $self = bless {
      text => $text,
      chunks => [],
   }, $class;

   $self->{indent} = $opts{indent} if defined $opts{indent};

   return $self;
}

=head1 METHODS

=cut

=head2 $text = $item->text

Returns the text string displayed by this item.

=cut

sub text
{
   my $self = shift;
   return $self->{text};
}

sub height_for_width
{
   my $self = shift;
   my ( $width ) = @_;

   $self->{width} = $width;

   my $text = $self->text;
   $self->{chunks} = \my @chunks;

   my $pos_ch = 0;

   while( length $text ) {
      my $indent = ( @chunks && $self->{indent} ) ? $self->{indent} : 0;
      my $eol_ch = cols2chars $text, $width - $indent;

      if( $eol_ch < length $text ) {
         # TODO: This surely must be possible without substr()ing a temporary
         substr( $text, 0, $eol_ch ) =~ m/\S+$/ and $-[0] > 0 and $eol_ch = $-[0];
      }

      push @chunks, [ $pos_ch, $eol_ch ];

      my $bol_ch = pos $text = $eol_ch;
      $text =~ m/\G\s+/g and $bol_ch = $+[0];

      substr $text, 0, $bol_ch, "";
      $pos_ch += $bol_ch;
   }

   return scalar @chunks;
}

sub render
{
   my $self = shift;
   my ( $win, %args ) = @_;

   my $cols = $args{width};

   # Rechunk if width changed
   $self->height_for_width( $cols ) if $cols != $self->{width};

   my $text = $self->text;
   my $chunks = $self->{chunks};

   foreach my $lineidx ( $args{firstline} .. $args{lastline} ) {
      my $indent = ( $lineidx && $self->{indent} ) ? $self->{indent} : 0;
      my $chunk = substr $text, $chunks->[$lineidx][0], $chunks->[$lineidx][1];

      $win->goto( $args{top} + $lineidx, 0 );
      $win->erasech( $indent, 1 ) if $indent;
      $win->print( $chunk );

      my $spare = $cols - textwidth $chunk;
      $win->erasech( $spare ) if $spare > 0;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
