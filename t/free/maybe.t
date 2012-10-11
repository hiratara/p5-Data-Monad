use strict;
use warnings;
use Data::Monad::Free;
use Data::Monad::Maybe;
use Test::More;

my $m = Data::Monad::Free->new(1, just 3);
my $m2 = $m->flat_map(sub {
    my $x = shift;
    return Data::Monad::Free->new(1, just $x * 2);
});

is $m2->{n}, 2;
is $m2->{values}[0]->flatten->value, 6;

done_testing;
