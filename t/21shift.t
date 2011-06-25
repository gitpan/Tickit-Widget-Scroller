#!/usr/bin/perl

use strict;

use Test::More tests => 15;

use Tickit::Test 0.07;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

my ( $term, $rootwin ) = mk_term_and_window cols => 20, lines => 8;
my $win = $rootwin->make_sub( 0, 0, 6, 20 );

$rootwin->focus( 7, 0 );

my $scroller = Tickit::Widget::Scroller->new;

$scroller->push(
   Tickit::Widget::Scroller::Item::Text->new( "Existing line $_" ),
) for 1 .. 15;

$scroller->set_window( $win );

flush_tickit;

is_termlog( [ ( map { GOTO($_-1,0),
                      SETPEN,
                      PRINT("Existing line $_"),
                      SETBG(undef),
                      ERASECH(5) } 1 .. 6 ),
              GOTO(7,0) ],
            'Termlog initially' );

is_display( [ map { "Existing line $_" } 1 .. 6 ],
            'Display initially' );

is_cursorpos( 7, 0, 'Cursor position intially' );

$scroller->shift;

flush_tickit;

is_termlog( [ SCROLLRECT(0,0,6,20, 1,0),
              GOTO(5,0),
              SETPEN,
              PRINT("Existing line 7"),
              SETBG(undef),
              ERASECH(5),
              GOTO(7,0) ],
            'Termlog after shift' );

is_display( [ map { "Existing line $_" } 2 .. 7 ],
            'Display after shift' );

is_cursorpos( 7, 0, 'Cursor position after shift' );

$scroller->shift( 3 );

flush_tickit;

is_termlog( [ SCROLLRECT(0,0,6,20, 3,0),
              GOTO(3,0),
              SETPEN,
              PRINT("Existing line 8"),
              SETBG(undef),
              ERASECH(5),
              GOTO(4,0),
              SETPEN,
              PRINT("Existing line 9"),
              SETBG(undef),
              ERASECH(5),
              GOTO(5,0),
              SETPEN,
              PRINT("Existing line 10"),
              SETBG(undef),
              ERASECH(4),
              GOTO(7,0) ],
            'Termlog after shift 3' );

is_display( [ map { "Existing line $_" } 5 .. 10 ],
            'Display after shift 3' );

is_cursorpos( 7, 0, 'Cursor position after shift 3' );

$scroller->scroll_to_bottom;
flush_tickit;
$term->methodlog; # ignore the method log

is_display( [ map { "Existing line $_" } 10 .. 15 ],
            'Display after scroll_to_bottom' );

$scroller->shift;

flush_tickit;

is_termlog( [],
            'Termlog empty after shift at bottom' );

is_display( [ map { "Existing line $_" } 10 .. 15 ],
            'Display unchanged after shift at bottom' );

$scroller->scroll_to_top;
flush_tickit;
$term->methodlog; # ignore the method log

is_display( [ map { "Existing line $_" } 6 .. 11 ],
            'Display after scroll_to_top' );

$scroller->shift( 6 );

flush_tickit;

is_termlog( [ ( map { GOTO($_-12,0),
                      SETPEN,
                      PRINT("Existing line $_"),
                      SETBG(undef),
                      ERASECH(4) } 12 .. 15 ),
              ( map { GOTO($_,0),
                      SETBG(undef),
                      ERASECH(20) } 4 .. 5 ),
              GOTO(7,0) ],
            'Termlog after shift 6 at top' );

is_display( [ map { "Existing line $_" } 12 .. 15 ],
            'Display after shift 6 at top' );
