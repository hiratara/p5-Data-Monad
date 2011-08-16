use strict;
use warnings;
use MonadUtil;
use AnyEvent::HTTP;
use AnyEvent::Util;

sub m_after_n {
	my $n = pop @_;
	my @m = @_;

	my $cv = AE::cv;
	my $t; $t = AE::timer $n, 0, sub {
		$cv->send(@m);
		undef $t;
	};
	return $cv;
}

my $ret_cv = (m_lift2 {map {$_ * 2} @_})->(
	m_after_n(2, 4, 5 => 4), m_after_n(1, 3, 5 => 5)
);

my $ret_cv2 = m_bind $ret_cv => sub {
	my @values = @_;
	m_after_n +(map { chr(ord('a') + $_) } @values) => 2;
};
print $ret_cv2->recv, "\n";
