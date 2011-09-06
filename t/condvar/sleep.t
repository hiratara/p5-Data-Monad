use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

is +AnyEvent::CondVar->unit('X')->sleep(.3)->recv, 'X';

done_testing;
