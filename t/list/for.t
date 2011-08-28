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

ok eq_set(Data::Monad::List->for(
    sub { list [1, 2] }   => \$x,
    sub { list [3, 4, 5] } => \$y,
    sub { Data::Monad::List->unit("$x-$y") },
), ["1-3", "2-3", "1-4", "2-4", "1-5", "2-5"]);

done_testing;
