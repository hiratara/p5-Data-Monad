use strict;
use warnings;
use Data::Monad::CondVar qw/as_cv/;
use AnyEvent;
use Test::More;

sub async_add {
    my $cb = pop;
    my ($x, $y) = @_;
    $cb->($x + $y);
}

is as_cv { async_add 3, 2 => $_[0] }->recv, 5;

done_testing;
