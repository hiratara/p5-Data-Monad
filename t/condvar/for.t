use strict;
use warnings;
use AnyEvent;
use Data::Monad::CondVar;
use Test::More;

sub cv {
    my @v = @_;
    my $cv = AE::cv;
    my $t; $t = AE::timer 1, 0 => sub { $cv->(@v); undef $t };
    return $cv;
}

my ($x, $y, $z);
is +AnyEvent::CondVar->for(
    sub { cv 10 / 2 }   => \$x,
    sub { AnyEvent::CondVar->unit($x + 1) } => \$y,
    sub { AnyEvent::CondVar->unit($x - 1) } => \$z,
    sub { AnyEvent::CondVar->unit($y * $z) },
)->recv, 24;

my (@x, @y, @z);
is_deeply [AnyEvent::CondVar->for(
    sub { cv 1, 2, 3 } => \@x,
    sub { cv map {$_ + 1} @x } => \@y,
    sub { cv map {$_ - 1} @x } => \@z,
    sub { AnyEvent::CondVar->unit(@y, @z) },
)->recv], [2, 3, 4, 0, 1, 2];

done_testing;
