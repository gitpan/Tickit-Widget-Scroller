#!/usr/bin/perl

use strict;

use Test::More tests => 4;

use Tickit::Test;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

my $rootwin = mk_window;
my $win = $rootwin->make_sub( 0, 0, 5, 40 );

my $scroller = Tickit::Widget::Scroller->new(
   gravity => "bottom",
);

$scroller->push( Tickit::Widget::Scroller::Item::Text->new( "A line of content at line $_" ) ) for 1 .. 10;

$scroller->set_window( $win );

$scroller->scroll( +3 );

flush_tickit;

is_display( [ "A line of content at line 4",
              "A line of content at line 5",
              "A line of content at line 6",
              "A line of content at line 7",
              "A line of content at line 8", ],
            'Display initially' );

$rootwin->clear;
$win->resize( 7, 40 );

flush_tickit;

is_display( [ "A line of content at line 2",
              "A line of content at line 3",
              "A line of content at line 4",
              "A line of content at line 5",
              "A line of content at line 6",
              "A line of content at line 7",
              "A line of content at line 8", ],
            'Display after resize more lines' );

$rootwin->clear;
$win->resize( 5, 40 );

flush_tickit;

is_display( [ "A line of content at line 4",
              "A line of content at line 5",
              "A line of content at line 6",
              "A line of content at line 7",
              "A line of content at line 8", ],
            'Display after resize fewer lines' );

$rootwin->clear;
$win->resize( 5, 20 );

flush_tickit;

is_display( [ "line 6",
              "A line of content at",
              "line 7",
              "A line of content at",
              "line 8", ],
            'Display after resize fewer columns' );
