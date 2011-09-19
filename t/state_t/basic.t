use strict;
use warnings;
use Data::Monad::StateT;
use Data::Monad::Maybe;
use Test::More;

subtest t_lift => sub {
    my $monad = Data::Monad::StateT->new_class('Data::Monad::Maybe');
    my $m = $monad->t_lift(just 1);
    isa_ok $m, 'Data::Monad::StateT';
    isa_ok $m->('dummy state'), 'Data::Monad::Maybe';
    is $m->eval("dummy state")->value, 1;
    is $m->exec("dummy state")->value, "dummy state";
};

subtest with_maybe => sub {
    my $monad = Data::Monad::StateT->new_class('Data::Monad::Maybe');

    my $m1 = $monad->unit("M1");
    isa_ok $m1, 'Data::Monad::StateT';
    isa_ok $m1->('dummy state'), 'Data::Monad::Maybe';

    my $m2 = $m1->flat_map(sub {
        my @v = @_;
        $monad->new(sub {
            my @s = @_;
            @s ? just([@v, shift @s], [@s]) : nothing;
        });
    });
    isa_ok $m2, 'Data::Monad::StateT';
    isa_ok $m2->('dummy state'), 'Data::Monad::Maybe';

    is_deeply [$m2->eval('M2', 'M3')->value], ['M1', 'M2'];
    is_deeply [$m2->exec('M2', 'M3')->value], ['M3'];
    ok $m2->eval()->is_nothing;
    ok $m2->exec()->is_nothing;
};

subtest set_get => sub {
    my $monad = Data::Monad::StateT->new_class('Data::Monad::Maybe');
    my $m_set = $monad->set("Hello", "StateT");
    isa_ok $m_set, 'Data::Monad::StateT';
    isa_ok $m_set->('dummy state'), 'Data::Monad::Maybe';

    my $m_get = $monad->get;
    isa_ok $m_get, 'Data::Monad::StateT';
    isa_ok $m_get->('dummy state'), 'Data::Monad::Maybe';

    my $m_set_get = $m_set->flat_map(sub { $m_get });
    isa_ok $m_set_get, 'Data::Monad::StateT';
    isa_ok $m_set_get->('dummy state'), 'Data::Monad::Maybe';
    is_deeply [$m_set_get->eval('dummy state')->value], [qw/Hello StateT/];
    is_deeply [$m_set_get->exec('dummy state')->value], [qw/Hello StateT/];
};

done_testing;

