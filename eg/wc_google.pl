use strict;
use warnings;
use MonadUtil;
use AnyEvent::HTTP;
use AnyEvent::Util;

print m_binds(m_unit("http://www.google.com") => sub {
	my $url = shift;
	my $ret_cv = AE::cv;
	http_get $url, sub {
		$ret_cv->send($_[0]);
	};
	return $ret_cv;
}, sub {
	my $html = shift;

	my $ret;
	m_bind AnyEvent::Util::run_cmd(
		[qw/wc /], '<' => \$html, '>' => \$ret,
	) => sub {m_unit $ret};
})->recv, "\n";
