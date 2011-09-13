use strict;
use warnings;
use Data::Monad::Maybe qw/just nothing/;
use Data::Monad::Base::Sugar;
use Test::More;

my $data = just { hage => { debu => { me => 1 } } };

sub get_key($) {
    my ($key) = @_;
    sub {
        my $data = shift;
        return nothing unless ref $data eq 'HASH';
        exists $data->{$key} ? just $data->{$key} : nothing;
    };
}

{
    my $maybe = $data->flat_map(get_key 'hage')
                     ->flat_map(get_key 'debu')
                     ->flat_map(get_key 'me');
    ok ! $maybe->is_nothing;
    is $maybe->value, 1;
}

{
    my $maybe = $data->flat_map(get_key 'hage')
                     ->flat_map(get_key 'yase')
                     ->flat_map(get_key 'me');
    ok $maybe->is_nothing;
}

{
    ok just(1, 2, 3)->flat_map(sub {
        is_deeply [@_], [1, 2, 3];
        nothing;
    })->map(sub { "DUMMY" })->is_nothing;
}

done_testing;
