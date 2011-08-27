use strict;
use warnings;
use Data::Monad::AECV;
use AnyEvent;
use Test::More;

my $m = Data::Monad::AECV->monad;

my $cv213 = do {
	my $cv = AE::cv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send(2, 1, 3);
		undef $t;
	};
	$m->new(cv => $cv);
};

is_deeply [$cv213->bind(sub {
	my @values = @_;
	$m->unit(map {$_ * 2} @values);
})->bind(sub {
	my @values = @_;
	$m->unit(map {$_ - 1} @values);
})->recv], [3, 1, 5];

done_testing;
