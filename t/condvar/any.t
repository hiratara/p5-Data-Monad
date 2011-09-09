use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

{
    my $done;
    is +AnyEvent::CondVar->any(
        cv_unit("NG")->sleep(.02)->map(sub { $done++; @_ }),
        cv_unit("OK")->sleep(.01)->map(sub { $done++; @_ }),
        cv_unit("NG")->sleep(.03)->map(sub { $done++; @_ }),
    )->sleep(.03)->recv, "OK";

    is $done, 1;
}

{
    eval { AnyEvent::CondVar->any(cv_fail "fail immediately")->recv };
    like $@, qr/\bimmediately\b/;
}

done_testing;
