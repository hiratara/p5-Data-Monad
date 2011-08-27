use strict;
use warnings;
use MonadUtil;
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

# naturality
my $f = sub { map {$_ * 2} @_ };
is_deeply [$m->unit(2, 1, 3)->map($f)->recv], [4, 2, 6];
is_deeply [$m->unit($f->(2, 1, 3))->recv], [4, 2, 6];

# unit
is_deeply [$m->unit($cv213)->join->recv], [2, 1, 3];
is_deeply [$cv213->map(sub { $m->unit(@_) })->join->recv], [2, 1, 3];

done_testing;
