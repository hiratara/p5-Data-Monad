use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

sub cv_after($$) {
    my ($v, $after) = @_;

    my $cv = AE::cv;
    my $t; $t = AE::timer $after, 0, sub {
        $cv->($v);
        undef $t;
    };

    return $cv;
}

is_deeply [cv_sequence(
    cv_after(2 => 0.3), cv_after(3 => 0.1), cv_after(4 => 0.2)
)->recv], [2, 3, 4];

done_testing;
