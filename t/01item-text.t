#!/usr/bin/perl

use strict;

use Test::More tests => 12;

use Tickit::Test;

use Tickit::Widget::Scroller::Item::Text;

my $win = mk_window;

my $item = Tickit::Widget::Scroller::Item::Text->new( "My message here" );

isa_ok( $item, "Tickit::Widget::Scroller::Item::Text", '$item' );

is( $item->text, "My message here" );

is( $item->height_for_width( 80 ), 1, 'height_for_width 80' );

$item->render( $win, top => 0, firstline => 0, lastline => 0, width => 80, height => 25 );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("My message here"),
              SETBG(undef),
              ERASECH(65) ],
            'Termlog for render fullwidth' );

is_display( [ "My message here" ],
            'Display for render fullwidth' );

$win->clear;
is_termlog( [ SETPEN, CLEAR ] );

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

is_display( [ "My message", "here" ],
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
              ERASECH(8) ],
            'Termlog for render width 12 with indent' );

is_display( [ "My message", "    here" ],
            'Display for render width 12 with indent' );
