use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

is_deeply [AnyEvent::CondVar->all(
    cv_unit(qw/a/)->sleep(.2),
    cv_unit(qw/b c/)->sleep(.1),
    cv_unit(qw/d e f/)->sleep(.3),
)->sleep(.3)->recv], [['a'], ['b', 'c'], ['d', 'e', 'f']];

{
    my $done;
    eval {
        AnyEvent::CondVar->all(
            cv_unit("NG")->sleep(.2)->flat_map(sub { cv_fail "NG" }),
            cv_unit("OK")->sleep(.1)->map(sub { $done++; @_ }),
            cv_unit("OK")->sleep(.3)->map(sub { $done++; @_ }),
        )->sleep(.3)->recv;
    };

    like $@, qr/^NG/;
    is $done, 1;
}

{
    eval { AnyEvent::CondVar->all(cv_fail "fail immediately")->recv };
    like $@, qr/\bimmediately\b/;
}

done_testing;
