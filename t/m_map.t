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

# preserve identity
my $id = sub { @_ };
my $cv_id = m_map $id;
is_deeply [$cv_id->($cv213)->recv], [2, 1, 3];

# preserve associative
my $f = sub { reverse @_ };
my $g = sub { sort @_ };

my $fg1 = m_map composition($g, $f);
my $fg2 = composition(m_map $g, m_map $f);

is_deeply [$fg1->($cv213)->recv], [1, 2, 3];
is_deeply [$fg2->($cv213)->recv], [1, 2, 3];

done_testing;
