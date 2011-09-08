use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

sub _after_dot_4(&) {
    my $code = shift;
    return cv_unit->sleep(.2)->flat_map(sub {
        cv_unit->sleep(.2)->map($code);
    });
}

subtest 'flat_map_and_sleep' => sub {
    {
        my $shouldnt_reach;
        my $cv = _after_dot_4 { $shouldnt_reach++ };

        # cancel when it sleeps to the first time
        cv_unit->sleep(.1)->map(sub {
            $cv->cancel;
        })->sleep(.4)->recv;

        eval { $cv->recv };
        like $@, qr/canceled/;
        ok ! $shouldnt_reach;
    };

    {
        my $shouldnt_reach;
        my $cv = _after_dot_4 { $shouldnt_reach++ };

        # cancel when it sleeps to the second time
        cv_unit->sleep(.3)->map(sub {
            $cv->cancel;
        })->sleep(.2)->recv;

        eval { $cv->recv };
        like $@, qr/canceled/;
        ok ! $shouldnt_reach;
    };

    {
        my $shouldnt_reach;
        my $cv = _after_dot_4 { $shouldnt_reach++ };

        # cancel after it was finished
        cv_unit->sleep(.5)->map(sub {
            $cv->cancel;
        })->recv;

        eval { $cv->recv };
        ok ! $@;
        ok $shouldnt_reach;
    }
};

subtest 'flat_map_restriction' => sub {
    my $should_be_canceled;
    my $shouldnt_be_canceled;
    my $outer_cv = _after_dot_4 { $shouldnt_be_canceled++ };
    _after_dot_4 { $should_be_canceled++ }
        ->flat_map(sub { $outer_cv })
        ->cancel;
    cv_unit->sleep(.9)->recv;

    ok ! $should_be_canceled;
    ok $shouldnt_be_canceled, "flat_map() can't cancel outer cv.";

};

done_testing;
