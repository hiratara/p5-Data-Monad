use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

is_deeply [AnyEvent::CondVar->all(
    cv_unit(qw/a/)->sleep(.02),
    cv_unit(qw/b c/)->sleep(.01),
    cv_unit(qw/d e f/)->sleep(.03),
)->sleep(.03)->recv], [['a'], ['b', 'c'], ['d', 'e', 'f']];

{
    my $done;
    eval {
        AnyEvent::CondVar->all(
            cv_unit("NG")->sleep(.02)->flat_map(sub { cv_fail "NG" }),
            cv_unit("OK")->sleep(.01)->map(sub { $done++; @_ }),
            cv_unit("OK")->sleep(.03)->map(sub { $done++; @_ }),
        )->sleep(.03)->recv;
    };

    like $@, qr/^NG/;
    is $done, 1;
}

{
    eval { AnyEvent::CondVar->all(cv_fail "fail immediately")->recv };
    like $@, qr/\bimmediately\b/;
}

done_testing;
