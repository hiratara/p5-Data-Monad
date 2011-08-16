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

# naturality
my $f = sub { map {$_ * 2} @_ };

my $unit_f = composition(m_map $f, \&m_unit);
my $f_unit = composition(\&m_unit, $f);
is_deeply [$unit_f->(2, 1, 3)->recv], [4, 2, 6];
is_deeply [$f_unit->(2, 1, 3)->recv], [4, 2, 6];

# unit
my $unit_map_join = composition(\&m_join, \&m_unit);
my $map_unit_join = composition(\&m_join, m_map \&m_unit);
is_deeply [$unit_map_join->($cv213)->recv], [2, 1, 3];
is_deeply [$map_unit_join->($cv213)->recv], [2, 1, 3];

done_testing;
