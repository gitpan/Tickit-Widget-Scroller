#!/usr/bin/perl

use strict;

use Test::More tests => 13;

use Tickit::Test;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

my ( $term, $win ) = mk_term_and_window cols => 20, lines => 6;

my $scroller = Tickit::Widget::Scroller->new;

$scroller->set_window( $win );

flush_tickit;

is_termlog( [ SETPEN,
              CLEAR,
              map { GOTO($_,0), SETBG(undef), ERASECH(20) } 0 .. 5 ],
            'Termlog initially' );

is_display( [ ],
            'Display initially' );

$scroller->push(
   Tickit::Widget::Scroller::Item::Text->new( "A line of text" ),
);

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("A line of text"),
              SETBG(undef),
              ERASECH(6) ],
            'Termlog after push' );

is_display( [ "A line of text" ],
            'Display after push' );

$scroller->push(
   map { Tickit::Widget::Scroller::Item::Text->new( "Another line $_" ) } 1 .. 4,
);

flush_tickit;

is_termlog( [ GOTO(1,0),
              SETPEN,
              PRINT("Another line 1"),
              SETBG(undef),
              ERASECH(6),
              GOTO(2,0),
              SETPEN,
              PRINT("Another line 2"),
              SETBG(undef),
              ERASECH(6),
              GOTO(3,0),
              SETPEN,
              PRINT("Another line 3"),
              SETBG(undef),
              ERASECH(6),
              GOTO(4,0),
              SETPEN,
              PRINT("Another line 4"),
              SETBG(undef),
              ERASECH(6) ],
            'Termlog after push 4' );

is_display( [ "A line of text",
              "Another line 1",
              "Another line 2",
              "Another line 3",
              "Another line 4" ],
            'Display after push 4' );

$scroller->push( Tickit::Widget::Scroller::Item::Text->new( "An item of text that wraps" ) );

flush_tickit;

is_termlog( [ GOTO(5,0),
              SETPEN,
              PRINT("An item of text "),
              SETBG(undef),
              ERASECH(4),
              SCROLL(0,5,1),
              GOTO(5,0),
              SETPEN,
              PRINT("that wraps"),
              SETBG(undef),
              ERASECH(10) ],
            'Termlog after push scroll' );

is_display( [ "Another line 1",
              "Another line 2",
              "Another line 3",
              "Another line 4",
              "An item of text",
              "that wraps" ],
            'Display after push scroll' );

$scroller->push(
   map { Tickit::Widget::Scroller::Item::Text->new( "Another line $_" ) } 5 .. 10,
);

flush_tickit;

is_termlog( [ SETPEN,
              CLEAR,
              GOTO(0,0),
              SETPEN,
              PRINT("Another line 5"),
              SETBG(undef),
              ERASECH(6),
              GOTO(1,0),
              SETPEN,
              PRINT("Another line 6"),
              SETBG(undef),
              ERASECH(6),
              GOTO(2,0),
              SETPEN,
              PRINT("Another line 7"),
              SETBG(undef),
              ERASECH(6),
              GOTO(3,0),
              SETPEN,
              PRINT("Another line 8"),
              SETBG(undef),
              ERASECH(6),
              GOTO(4,0),
              SETPEN,
              PRINT("Another line 9"),
              SETBG(undef),
              ERASECH(6),
              GOTO(5,0),
              SETPEN,
              PRINT("Another line 10"),
              SETBG(undef),
              ERASECH(5) ],
            'Termlog after push 6' );

is_display( [ "Another line 5",
              "Another line 6",
              "Another line 7",
              "Another line 8",
              "Another line 9",
              "Another line 10" ],
            'Display after push 6' );

$scroller->scroll_to_top;

flush_tickit;
$term->methodlog; # flush it

is_display( [ "A line of text",
              "Another line 1",
              "Another line 2",
              "Another line 3",
              "Another line 4",
              "An item of text" ],
            'Display after scroll_to_top' );

$scroller->push(
   Tickit::Widget::Scroller::Item::Text->new( "Unseen line" ),
);

is_termlog( [],
            'Termlog empty after push at head' );

is_display( [ "A line of text",
              "Another line 1",
              "Another line 2",
              "Another line 3",
              "Another line 4",
              "An item of text" ],
            'Display after push at head' );
