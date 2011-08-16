use strict;
use warnings;
use MonadUtil;
use AnyEvent::HTTP;
use AnyEvent::Util;

sub get_url($) {
	my $url = shift;
	my $ret_cv = AE::cv;
	http_get $url, sub {
		$ret_cv->send($_[0]);
	};
	return $ret_cv;
}

sub count_line($) {
	my $html = shift;

	my $cv = AnyEvent::Util::run_cmd(
		[qw/wc /], '<' => \$html, '>' => \my $ret,
	);
	return m_bind $cv => sub {m_unit $ret};
}

my $ret_cv = m_bind get_url("http://www.google.com")
                    => \&count_line;
$ret_cv->cb(sub {
	print $_[0]->recv, "\n";
});

$ret_cv->recv;
