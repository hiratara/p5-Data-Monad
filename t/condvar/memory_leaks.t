use strict;
use warnings;
use Test::Requires qw/Test::LeakTrace/;
use Data::Monad::CondVar;
use Test::More;

no_leaks_ok { cv_unit->sleep(.001)->recv };

done_testing;
