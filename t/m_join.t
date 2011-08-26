use strict;
use warnings;
use Data::Monad::AECV;
use MonadUtil;
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
my $cvcv213 = do {
	my $cv = AE::cv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send($cv213);
		undef $t;
	};
	$m->new(cv => $cv);
};
my $cvcvcv213 = do {
	my $cv = AE::cv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send($cvcv213);
		undef $t;
	};
	$m->new(cv => $cv);
};

# naturality
my $f = sub { map {$_ * 2} @_ };
my $cvf = $m->map($f);
my $cvcvf = $m->map($cvf);

my $join_cvf = composition($cvf, sub { $_[0]->join });
my $cvcvf_join = composition(sub { $_[0]->join }, $cvcvf);
is_deeply [$join_cvf->($cvcv213)->recv], [4, 2, 6];
is_deeply [$cvcvf_join->($cvcv213)->recv], [4, 2, 6];

# associative law
my $join_map_join = composition(sub { $_[0]->join }, sub { $_[0]->join });
my $map_join_join = composition(
	sub { $_[0]->join }, $m->map(sub { $_[0]->join })
);
is_deeply [$join_map_join->($cvcvcv213)->recv], [2, 1, 3];
is_deeply [$map_join_join->($cvcvcv213)->recv], [2, 1, 3];


done_testing;
