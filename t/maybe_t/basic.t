use strict;
use warnings;
use Data::Monad::MaybeT;
use Data::Monad::Maybe;
use Data::Monad::List;
use Data::Monad::Identity;
use Test::More;

subtest t_lift => sub {
    my $monad = Data::Monad::MaybeT->new_class('Data::Monad::Identity');

    my $m = $monad->t_lift(Data::Monad::Identity->new("ID"));
    isa_ok $m, 'Data::Monad::MaybeT';
    isa_ok $m->value, 'Data::Monad::Identity';
    isa_ok $m->value->value, 'Data::Monad::Maybe';
};

subtest with_id => sub {
    my $monad = Data::Monad::MaybeT->new_class('Data::Monad::Identity');
    my $m1 = $monad->unit(10, 4);
    isa_ok $m1, 'Data::Monad::MaybeT';
    isa_ok $m1->value, 'Data::Monad::Identity';
    isa_ok $m1->value->value, 'Data::Monad::Maybe';

    my $m2 = $m1->flat_map(sub {
        my @v = @_;
        $monad->new(
            Data::Monad::Identity->new(just $v[0] % $v[1])
        );
    });

    isa_ok $m2, 'Data::Monad::MaybeT';
    isa_ok $m2->value, 'Data::Monad::Identity';
    isa_ok $m2->value->value, 'Data::Monad::Maybe';
    is $m2->value->value->value, 2;
};

subtest with_list => sub {
    my $monad = Data::Monad::MaybeT->new_class('Data::Monad::List');
    my $m1 = $monad->new(scalar_list(just(1), nothing, just(2)));
    isa_ok $m1, 'Data::Monad::MaybeT';
    isa_ok $m1->value, 'Data::Monad::List';
    isa_ok +($m1->value->scalars)[0], 'Data::Monad::Maybe';

    my $m2 = $m1->map(sub { $_[0] + 1 });

    isa_ok $m2, 'Data::Monad::MaybeT';
    isa_ok $m2->value, 'Data::Monad::List';
    isa_ok +($m2->value->scalars)[0], 'Data::Monad::Maybe';
    is +($m2->value->scalars)[0]->value, 2;
    ok +($m2->value->scalars)[1]->is_nothing;
    is +($m2->value->scalars)[2]->value, 3;
};

done_testing;
