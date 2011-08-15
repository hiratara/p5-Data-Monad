use strict;
use warnings;
use MonadUtil;
use AnyEvent::HTTP;
use AnyEvent::Util;

sub m_after_n($$) {
	my ($m, $n) = @_;

	my $cv = AE::cv;
	my $t; $t = AE::timer $n, 0, sub {
		$cv->send($m);
		undef $t;
	};
	return $cv;
}

my $ret_cv = (m_lift2 {$_[0] + $_[1]})->(m_after_n(2 => 4), m_after_n(5 => 5));
print $ret_cv->recv, "\n";
