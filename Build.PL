use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::Scroller',
   requires => {
      'String::Tagged' => 0,
      'Tickit::Test' => '0.12',
      'Tickit::Widget' => '0.11',
      'Tickit::Window' => '0.22',
      'Tickit::Pen' => '0.19',
   },
   build_requires => {
      'Test::More' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
