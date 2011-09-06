use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

{
    is +AnyEvent::CondVar->unit('X')->sleep(.2)
    ->timeout(.1)->map(sub {
        ok ! $_[0];
        'DONE';
    })->recv, 'DONE';
}

{
    is +AnyEvent::CondVar->unit('X')->sleep(.2)
    ->timeout(.3)->map(sub {
        is $_[0], 'X';
        'DONE';
    })->recv, 'DONE';
}

{
    my $not_timeouted = AnyEvent::CondVar->unit('X')->sleep(.1)->timeout(.2);
    is +AnyEvent::CondVar->unit->sleep(.3)->flat_map(sub {
        $not_timeouted;
    })->recv, "X", 'timeout() timer should be canceled.';
}

{
    my $timeouted = AnyEvent::CondVar->unit('X')->sleep(.2)->timeout(.1);
    isnt +AnyEvent::CondVar->unit->sleep(.3)->flat_map(sub {
        $timeouted;
    })->recv, "X", 'should be timeouted.';
}

done_testing;
