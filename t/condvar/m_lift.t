use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

sub sleep_and_send($@) {
    my ($sec, @values) = @_;
    my $cv = AE::cv;
    my $t; $t = AE::timer $sec, 0, sub {
        $cv->send(@values);
        undef $t;
    };
    $cv;
}

is +cv_lift(sub { my $n = 0; $n += $_ for @_; $n })->(
    sleep_and_send(.02 => 2),
    sleep_and_send(.0 => 3),
    sleep_and_send(.01 => 4),
)->recv, 9;


done_testing;
