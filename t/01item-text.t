#!/usr/bin/perl

use strict;

use Test::More tests => 18;

use Tickit::Test 0.12;

use Tickit::Widget::Scroller::Item::Text;

my ( $term, $win ) = mk_term_and_window;

my $item = Tickit::Widget::Scroller::Item::Text->new( "My message here" );

isa_ok( $item, "Tickit::Widget::Scroller::Item::Text", '$item' );

is_deeply( [ $item->chunks ],
           [ [ "My message here", 15 ] ],
           '$item->chunks' );

is( $item->height_for_width( 80 ), 1, 'height_for_width 80' );

$item->render( $win, top => 0, firstline => 0, lastline => 0, width => 80, height => 25 );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("My message here"),
              SETBG(undef),
              ERASECH(65) ],
            'Termlog for render fullwidth' );

is_display( [ [TEXT("My message here")] ],
            'Display for render fullwidth' );

$win->clear;
$term->methodlog; # clear log

my $subwin = $win->make_sub( 0, 0, 10, 12 );

is( $item->height_for_width( 12 ), 2, 'height_for_width 12' );

$item->render( $subwin, top => 0, firstline => 0, lastline => 1, width => 12, height => 10 );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("My message "),
              SETBG(undef),
              ERASECH(1),
              GOTO(1,0),
              SETPEN,
              PRINT("here"),
              SETBG(undef),
              ERASECH(8) ],
            'Termlog for render width 12' );

is_display( [ [TEXT("My message")],
              [TEXT("here")] ],
            'Display for render width 12' );

my $indenteditem = Tickit::Widget::Scroller::Item::Text->new( "My message here", indent => 4 );

is( $indenteditem->height_for_width( 12 ), 2, 'height_for_width 12 with indent' );

$indenteditem->render( $subwin, top => 0, firstline => 0, lastline => 1, width => 12, height => 10 );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("My message "),
              SETBG(undef),
              ERASECH(1),
              GOTO(1,0),
              SETBG(undef),
              ERASECH(4,1),
              SETPEN,
              PRINT("here"),
              SETBG(undef),
              ERASECH(4) ],
            'Termlog for render width 12 with indent' );

is_display( [ [TEXT("My message")],
              [TEXT("    here")] ],
            'Display for render width 12 with indent' );

# Boundary condition in whitespace splitting
{
   $win->clear;
   $term->methodlog; # clear log

   my $item = Tickit::Widget::Scroller::Item::Text->new( "AAAA BBBB CCCC DDDD" );

   is( $item->height_for_width( 9 ), 2, 'height_for_width 2 for splitting boundary' );

   $item->render( $win, top => 0, firstline => 0, lastline => 1, width => 9, height => 2 );

   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("AAAA BBBB"),
                 GOTO(1,0),
                 SETPEN,
                 PRINT("CCCC DDDD") ],
               'Termlog for render splitting boundary' );

   is_display( [ [TEXT("AAAA BBBB")],
                 [TEXT("CCCC DDDD")] ],
               'Display for render splitting boundary' );
}

# Linefeeds
{
   $win->clear;
   $term->methodlog; # clear log

   my $item = Tickit::Widget::Scroller::Item::Text->new( "Some more text\nwith linefeeds" );

   is_deeply( [ $item->chunks ],
              [ [ "Some more text", 14, linebreak => 1 ],
                [ "with linefeeds", 14 ] ],
              '$item->chunks with linefeeds' );

   is( $item->height_for_width( 80 ), 2, 'height_for_width 2 with linefeeds' );

   $item->render( $win, top => 0, firstline => 0, lastline => 1, width => 80, height => 2 );

   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("Some more text"),
                 SETPEN,
                 ERASECH(66),
                 GOTO(1,0),
                 SETPEN,
                 PRINT("with linefeeds"),
                 SETPEN,
                 ERASECH(66) ],
               'Termlog for render with linefeeds' );

   is_display( [ [TEXT("Some more text")],
                 [TEXT("with linefeeds")] ],
               'Display for render with linefeeds' );
}
