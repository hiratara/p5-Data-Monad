use strict;
use warnings;
use Data::Monad::State;
use Test::More;

subtest sugars => sub {
    my $good = state {
        my @s = @_;
        ["GOOD"], \@s;
    };

    is_deeply [$good->("state")], [["GOOD"], ["state"]];
    is +$good->eval("state"), "GOOD";
    is +$good->exec("state"), "state";
};

subtest flat_map => sub {
    my $good = state {
        my @s = @_;
        ["s1"], \@s;
    };

    my $pop = sub {
        my @v = @_;
        state {
            my @s = @_;
            [@v, shift @s], \@s;
        };
    };

    my $good_popper = $good->flat_map($pop);

    is_deeply [$good_popper->eval("s2", "s3")], [qw/s1 s2/];
    is_deeply [$good_popper->exec("s2", "s3")], [qw/s3/];
};

subtest set_get => sub {
    my $m_set = Data::Monad::State->set("Hello", "StateT");

    my $m_get = Data::Monad::State->get;

    my $m_set_get = $m_set->flat_map(sub { $m_get });
    is_deeply [$m_set_get->eval('dummy state')], [qw/Hello StateT/];
    is_deeply [$m_set_get->exec('dummy state')], [qw/Hello StateT/];
};

done_testing;
