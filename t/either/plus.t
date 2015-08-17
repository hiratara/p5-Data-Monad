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

subtest 'or_else' => sub {
    is_deeply left('failure')->or_else(right('else')), right('else');
    is_deeply right(10)->or_else(right('else')), right(10);
};

subtest 'get_or_else' => sub {
    is left('failure')->get_or_else('else'), 'else';
    is right(10)->get_or_else('else'), 10;
    is_deeply [ right(10, 20, 30)->get_or_else('else') ], [ 10, 20, 30 ];
};

done_testing;
