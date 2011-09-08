use strict;
use warnings;
use AnyEvent;
use Data::Monad::CondVar;
use Test::More;

eval { cv_fail("FAIL")->recv };
like $@, qr/^FAIL/;

done_testing;
