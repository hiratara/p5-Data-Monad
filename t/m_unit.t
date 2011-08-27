use strict;
use warnings;
use MonadUtil;
use Data::Monad::AECV;
use AnyEvent;
use Test::More;

my $cv213 = do {
	my $cv = AE::mcv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send(2, 1, 3);
		undef $t;
	};
	$cv;
};

# naturality
my $f = sub { map {$_ * 2} @_ };
is_deeply [Data::Monad::AECV->unit(2, 1, 3)->map($f)->recv], [4, 2, 6];
is_deeply [Data::Monad::AECV->unit($f->(2, 1, 3))->recv], [4, 2, 6];

# unit
is_deeply [Data::Monad::AECV->unit($cv213)->flatten->recv], [2, 1, 3];
is_deeply [$cv213->map(sub {
	Data::Monad::AECV->unit(@_);
})->flatten->recv], [2, 1, 3];

done_testing;
