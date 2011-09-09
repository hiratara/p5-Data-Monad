use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

{
    is +cv_unit('X')->sleep(.02)
    ->timeout(.01)->map(sub {
        ok ! $_[0];
        'DONE';
    })->recv, 'DONE';
}

{
    is +cv_unit('X')->sleep(.02)
    ->timeout(.03)->map(sub {
        is $_[0], 'X';
        'DONE';
    })->recv, 'DONE';
}

{
    my $not_timeouted = cv_unit('X')->sleep(.01)->timeout(.02);
    is +cv_unit->sleep(.03)->flat_map(sub {
        $not_timeouted;
    })->recv, "X", 'timeout() timer should be canceled.';
}

{
    my $timeouted = cv_unit('X')->sleep(.02)->timeout(.01);
    isnt +cv_unit->sleep(.03)->flat_map(sub {
        $timeouted;
    })->recv, "X", 'should be timeouted.';
}

done_testing;
