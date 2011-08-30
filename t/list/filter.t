use strict;
use warnings;
use Data::Monad::List;
use Test::More;

my ($x, $y, $z);
ok eq_array(
    (list [1,2,3,4])->filter(sub { $_[0] % 2 == 0 }),
    [2, 4]
);

done_testing;
