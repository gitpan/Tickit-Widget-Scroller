#!/usr/bin/perl

use strict;

use Test::More tests => 30;

use Tickit::Test 0.07;

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

is( $scroller->item2line( 0,  0 ), 0, 'item2line 0, 0 initially' );
is( $scroller->item2line( 0, -1 ), 1, 'item2line 0, -1 initially' );
is( $scroller->item2line( 1,  0 ), 2, 'item2line 1, 0 initially' );
is( $scroller->item2line( 1, -1 ), 3, 'item2line 1, -1 initially' );
is( $scroller->item2line( 2,  0 ), 4, 'item2line 2, 0 initially' );
is( $scroller->item2line( 2, -1 ), undef, 'item2line 2, -1 initially offscreen' );

is_deeply( [ $scroller->item2line( 2, -1 ) ], [ undef, "below" ], 'list item2line 2, -1 initially below screen' );

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

is( $scroller->item2line( 0,  0 ), undef, 'item2line 0, 0 offscreen after scroll +10' );
is( $scroller->item2line( 0, -1 ), undef, 'item2line 0, -1 offscreen after scroll +10' );
is( $scroller->item2line( 5,  0 ), 0, 'item2line 5, 0 after scroll +10' );
is( $scroller->item2line( 5, -1 ), 1, 'item2line 5, -1 after scroll +10' );
is( $scroller->item2line( 8,  0 ), undef, 'item2line 8, 0 offscreen after scroll +10' );

is_deeply( [ $scroller->item2line( 0, 0 ) ], [ undef, "above" ], 'list item2line 0, 0 above screen after scroll +10' );
is_deeply( [ $scroller->item2line( 8, 0 ) ], [ undef, "below" ], 'list item2line 8, 0 below screen after scroll +10' );

$scroller->scroll( -1 );

flush_tickit;

is_termlog( [ SCROLLRECT(0,0,5,15, -1,0),
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

is_termlog( [ SCROLLRECT(0,0,5,15, +1,0),
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
