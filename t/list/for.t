use strict;
use warnings;
use Data::Monad::List;
use Test::More;

my ($x, $y, $z);
ok eq_array(Data::Monad::List->for(
    sub { list [2, 4] }   => \$x,
    sub { list [$x + 1] } => \$y,
    sub { list [$x - 1] } => \$z,
    sub { Data::Monad::List->unit($y * $z) },
), [3, 15]);

done_testing;
