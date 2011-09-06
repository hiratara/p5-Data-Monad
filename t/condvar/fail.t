use strict;
use warnings;
use AnyEvent;
use Data::Monad::CondVar;
use Test::More;

eval { AnyEvent::CondVar->fail("FAIL")->recv };
like $@, qr/^FAIL/;

done_testing;
