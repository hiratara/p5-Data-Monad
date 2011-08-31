use strict;
use warnings;
use AnyEvent;
use Data::Monad::CondVar;
use Data::MonadSugar;
use Test::More;

sub cv {
    my @v = @_;
    my $cv = AE::cv;
    my $t; $t = AE::timer 1, 0 => sub { $cv->(@v); undef $t };
    return $cv;
}

is Data::MonadSugar::for {
    pick \my $x => sub { cv 10 / 2 };
    pick \my $y => sub { AnyEvent::CondVar->unit($x + 1) };
    pick \my $z => sub { AnyEvent::CondVar->unit($x - 1) };
    pick sub { AnyEvent::CondVar->unit($y * $z) };
}->recv, 24;

is_deeply [Data::MonadSugar::for {
    pick \my @x => sub { cv 1, 2, 3 };
    pick \my @y => sub { cv map {$_ + 1} @x };
    pick \my @z => sub { cv map {$_ - 1} @x };
    yield { @y, @z };
}->recv], [2, 3, 4, 0, 1, 2];

done_testing;
