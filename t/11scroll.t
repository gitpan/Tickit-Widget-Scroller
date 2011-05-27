#!/usr/bin/perl

use strict;

use Test::More tests => 16;

use Tickit::Test;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

# Tests are simpler if the terminal is much smaller
my ( $term, $win ) = mk_term_and_window lines => 5, cols => 15;

my $scroller = Tickit::Widget::Scroller->new;

$scroller->push(
   map { Tickit::Widget::Scroller::Item::Text->new( "Item of text $_ which is long" ) } 1 .. 9
);

$scroller->set_window( $win );

flush_tickit;

is_termlog( [ SETPEN,
              CLEAR,
              GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 1 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 2 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 3 ") ],
            'Termlog initially' );

is_display( [ "Item of text 1 ",
              "which is long",
              "Item of text 2 ",
              "which is long",
              "Item of text 3 " ],
            'Display initially' );

$scroller->scroll( +10 );

flush_tickit;

is_termlog( [ SETPEN,
              CLEAR,
              GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 6 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 7 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 8 ") ],
            'Termlog after scroll +10' );

is_display( [ "Item of text 6 ",
              "which is long",
              "Item of text 7 ",
              "which is long",
              "Item of text 8 " ],
            'Display after scroll +10' );

$scroller->scroll( -1 );

flush_tickit;

is_termlog( [ SCROLL(0,4,-1),
              GOTO(0,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2) ],
            'Termlog after scroll -1' );

is_display( [ "which is long",
              "Item of text 6 ",
              "which is long",
              "Item of text 7 ",
              "which is long" ],
            'Display after scroll -1' );

$scroller->scroll( +1 );

flush_tickit;

is_termlog( [ SCROLL(0,4,+1),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 8 ") ],
            'Termlog after scroll +1' );

is_display( [ "Item of text 6 ",
              "which is long",
              "Item of text 7 ",
              "which is long",
              "Item of text 8 " ],
            'Display after scroll +1' );

$scroller->scroll( -10 );

flush_tickit;

is_termlog( [ SETPEN,
              CLEAR,
              GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 1 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 2 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 3 ") ],
            'Termlog after scroll -10' );

is_display( [ "Item of text 1 ",
              "which is long",
              "Item of text 2 ",
              "which is long",
              "Item of text 3 " ],
            'Display after scroll -10' );

$scroller->scroll_to_bottom;

flush_tickit;

is_termlog( [ SETPEN,
              CLEAR,
              GOTO(0,0),
              SETPEN, 
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(1,0),
              SETPEN, 
              PRINT("Item of text 8 "),
              GOTO(2,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(3,0),
              SETPEN,
              PRINT("Item of text 9 "),
              GOTO(4,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2) ],
            'Termlog after scroll_to_bottom' );

is_display( [ "which is long",
              "Item of text 8 ",
              "which is long",
              "Item of text 9 ",
              "which is long" ],
            'Display after scroll_to_bottom' );

$scroller->scroll_to_top;

flush_tickit;

is_termlog( [ SETPEN,
              CLEAR,
              GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 1 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 2 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 3 ") ],
            'Termlog after scroll_to_top' );

is_display( [ "Item of text 1 ",
              "which is long",
              "Item of text 2 ",
              "which is long",
              "Item of text 3 " ],
            'Display after scroll_to_top' );

$scroller->scroll_to( 2, 4, 0 ); # About halfway

flush_tickit;

is_termlog( [ SETPEN,
              CLEAR,
              GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 4 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 5 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 6 ") ],
            'Termlog after scroll_to middle' );

is_display( [ "Item of text 4 ",
              "which is long",
              "Item of text 5 ",
              "which is long",
              "Item of text 6 " ],
            'Display after scroll_to middle' );
