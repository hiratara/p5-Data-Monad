use strict;
use warnings;
use Test::More;

use Data::Monad::Either qw(right left);

subtest 'fold' => sub {
    is left('failure')->fold(
        sub { $_[0] . '!' },
        sub { $_[0] * 2 },
    ), 'failure!';
    is right(10)->fold(
        sub { $_[0] . '!' },
        sub { $_[0] * 2 },
    ), 20;
};

done_testing;
