use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

sub _after_dot_4(&) {
    my $code = shift;
    return AnyEvent::CondVar->unit->sleep(.2)->flat_map(sub {
        AnyEvent::CondVar->unit->sleep(.2)->map($code);
    });
}

{
    my $shouldnt_reach;
    my $cv = _after_dot_4 { $shouldnt_reach++ };

    # cancel when it sleeps to the first time
    AnyEvent::CondVar->unit->sleep(.1)->map(sub {
        $cv->cancel;
    })->sleep(.4)->recv;

    eval { $cv->recv };
    like $@, qr/canceled/;
    ok ! $shouldnt_reach;
}

{
    my $shouldnt_reach;
    my $cv = _after_dot_4 { $shouldnt_reach++ };

    # cancel when it sleeps to the second time
    AnyEvent::CondVar->unit->sleep(.3)->map(sub {
        $cv->cancel;
    })->sleep(.2)->recv;

    eval { $cv->recv };
    like $@, qr/canceled/;
    ok ! $shouldnt_reach;
}

{
    my $shouldnt_reach;
    my $cv = _after_dot_4 { $shouldnt_reach++ };

    # cancel after it was finished
    AnyEvent::CondVar->unit->sleep(.5)->map(sub {
        $cv->cancel;
    })->recv;

    eval { $cv->recv };
    ok ! $@;
    ok $shouldnt_reach;
}

done_testing;
