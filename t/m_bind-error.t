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

my $f = sub {
	my @v = @_;

	my $cv = AE::cv;
	$cv->croak(join '', @v, "\n");
	return $cv;
};

my $g = sub {
	m_unit map {$_ * 2} @_
};

my $ret_cv = m_bind +(m_bind $cv213 => $f) => $g;
eval { $ret_cv->recv };
like $@, qr/\b213\b/;

done_testing;
