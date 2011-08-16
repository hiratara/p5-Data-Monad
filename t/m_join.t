use strict;
use warnings;
use MonadUtil;
use AnyEvent;
use Test::More;

my $cv213 = do {
	my $cv = AE::cv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send(2, 1, 3);
		undef $t;
	};
	$cv;
};
my $cvcv213 = do {
	my $cv = AE::cv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send($cv213);
		undef $t;
	};
	$cv;
};
my $cvcvcv213 = do {
	my $cv = AE::cv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send($cvcv213);
		undef $t;
	};
	$cv;
};

# naturality
my $f = sub { map {$_ * 2} @_ };
my $cvf = m_map $f;
my $cvcvf = m_map $cvf;

my $join_cvf = composition($cvf, \&m_join);
my $cvcvf_join = composition(\&m_join, $cvcvf);
is_deeply [$join_cvf->($cvcv213)->recv], [4, 2, 6];
is_deeply [$cvcvf_join->($cvcv213)->recv], [4, 2, 6];

# associative law
my $join_map_join = composition(\&m_join, \&m_join);
my $map_join_join = composition(\&m_join, m_map \&m_join);
is_deeply [$join_map_join->($cvcvcv213)->recv], [2, 1, 3];
is_deeply [$map_join_join->($cvcvcv213)->recv], [2, 1, 3];


done_testing;
