#!/usr/bin/perl

use strict;

use Test::More tests => 5;

use Tickit::Test;

use String::Tagged;
use Tickit::Widget::Scroller::Item::RichText;

my $win = mk_window;

my $str = String::Tagged->new( "My message here" );
$str->apply_tag(  3, 7, b => 1 );
$str->apply_tag( 11, 4, u => 1 );

my $item = Tickit::Widget::Scroller::Item::RichText->new( $str );

isa_ok( $item, "Tickit::Widget::Scroller::Item::Text", '$item' );

is( $item->text, "My message here" );

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

is_display( [ "My message here" ],
            'Display for render fullwidth' );
