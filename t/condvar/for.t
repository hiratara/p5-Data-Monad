use strict;
use warnings;
use AnyEvent;
use Data::Monad::CondVar;
use Test::More;

sub cv($) {
    my $v = shift;
    my $cv = AE::cv;
    my $t; $t = AE::timer 1, 0 => sub { $cv->($v); undef $t };
    return $cv;
}

my ($x, $y, $z);
is +AnyEvent::CondVar->for(
    sub { cv 10 / 2 }   => \$x,
    sub { AnyEvent::CondVar->unit($x + 1) } => \$y,
    sub { AnyEvent::CondVar->unit($x - 1) } => \$z,
    sub { AnyEvent::CondVar->unit($y * $z) },
)->recv, 24;

done_testing;
