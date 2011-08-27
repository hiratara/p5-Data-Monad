use strict;
use warnings;
use Data::Monad::List;
use Test::More;

ok eq_set(
    (list [1 ,2, 3])->flat_map(sub {[$_[0] + 1, $_[0] - 1]}),
    [0, 2, 1, 3, 2, 4]
);

done_testing;
