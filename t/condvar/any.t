use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

{
    my $done;
    is +AnyEvent::CondVar->any(
        cv_unit("NG")->sleep(.2)->map(sub { $done++; @_ }),
        cv_unit("OK")->sleep(.1)->map(sub { $done++; @_ }),
        cv_unit("NG")->sleep(.3)->map(sub { $done++; @_ }),
    )->sleep(.3)->recv, "OK";

    is $done, 1;
}

{
    eval { AnyEvent::CondVar->any(cv_fail "fail immediately")->recv };
    like $@, qr/\bimmediately\b/;
}

done_testing;
