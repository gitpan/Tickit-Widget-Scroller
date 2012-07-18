#!/usr/bin/perl

use strict;

use Test::More tests => 6;

use Tickit::Test;

use String::Tagged;
use Tickit::Widget::Scroller::Item::RichText;

my ( $term, $win ) = mk_term_and_window;

my $str = String::Tagged->new( "My message here" );
$str->apply_tag(  3, 7, b => 1 );
$str->apply_tag( 11, 4, u => 1 );

my $item = Tickit::Widget::Scroller::Item::RichText->new( $str );

isa_ok( $item, "Tickit::Widget::Scroller::Item::Text", '$item' );

is_deeply( [ $item->chunks ],
           [ [ "My ",     3, pen => Tickit::Pen->new() ],
             [ "message", 7, pen => Tickit::Pen->new( b => 1 ) ],
             [ " ",       1, pen => Tickit::Pen->new() ],
             [ "here",    4, pen => Tickit::Pen->new( u => 1 ) ] ],
           '$item->chunks' );

is( $item->height_for_width( 80 ), 1, 'height_for_width 80' );

$item->render( $win, top => 0, firstline => 0, lastline => 0, width => 80, height => 25 );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("My "),
              SETPEN(b => 1),
              PRINT("message"),
              SETPEN,
              PRINT(" "),
              SETPEN(u => 1),
              PRINT("here"),
              SETBG(undef),
              ERASECH(65) ],
            'Termlog for render fullwidth' );

is_display( [ [TEXT("My "), TEXT("message",b=>1), BLANK(1), TEXT("here",u=>1)] ],
            'Display for render fullwidth' );

# Linefeeds
{
   $win->clear;
   $term->methodlog; # clear log

   my $str = String::Tagged->new( "Another message\nwith linefeeds" );
   $str->apply_tag( 8, 12, b => 1 );

   my $item = Tickit::Widget::Scroller::Item::RichText->new( $str );

   is_deeply( [ $item->chunks ],
              [ [ "Another ",    8, pen => Tickit::Pen->new() ],
                [ "message",     7, pen => Tickit::Pen->new( b => 1 ), linebreak => 1 ],
                [ "with",        4, pen => Tickit::Pen->new( b => 1 ) ], 
                [ " linefeeds", 10, pen => Tickit::Pen->new() ] ],
              '$item->chunks with linefeeds' );
}
