use strict;
use warnings;
use Data::Monad::Free;
use Data::Monad::List;
use Test::More;

my $m = Data::Monad::Free->new(1, scalar_list 3, 4);
my $m2 = $m->flat_map(sub {
    my $x = shift;
    return Data::Monad::Free->new(1, scalar_list $x * 2, $x * 10);
});

is $m2->{n}, 2;
ok eq_set [$m2->{values}[0]->flatten->scalars], [6, 30, 8, 40];

done_testing;
