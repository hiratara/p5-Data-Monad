use strict;
use warnings;
use Data::Monad::AECV;
use AnyEvent;
use Test::More;

my $m = Data::Monad::AECV->monad;

sub sleep_and_send($@) {
	my ($sec, @values) = @_;
	my $cv = AE::cv;
	my $t; $t = AE::timer $sec, 0, sub {
		$cv->send(@values);
		undef $t;
	};
	$m->new(cv => $cv);
}

is $m->lift(sub { my $n = 0; $n += $_ for @_; $n })->(
	sleep_and_send(2 => 2),
	sleep_and_send(0 => 3),
	sleep_and_send(1 => 4),
)->recv, 9;


done_testing;
