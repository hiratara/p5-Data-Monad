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

is_deeply [m_binds($cv213 => sub {
	my @values = @_;
	m_unit map {$_ * 2} @values;
}, sub {
	my @values = @_;
	m_unit map {$_ - 1} @values;
})->recv], [3, 1, 5];

done_testing;
