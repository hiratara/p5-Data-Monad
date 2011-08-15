use strict;
use warnings;
use AnyEvent;
use AnyEvent::HTTP;
use AnyEvent::Util;

sub m_unit($) {
	my $v = shift;
	my $cv = AE::cv;
	$cv->send($v);

	return $cv;
}

sub m_join($) {
	my $cv2 = shift;

	my $cv_mixed = AE::cv;
	$cv2->cb(sub {
		my $cv = $_[0]->recv;
		$cv->cb(sub {
			my $v = $_[0]->recv;
			$cv_mixed->send($v);
		});
	});

	return $cv_mixed;
}

sub m_map($) {
	my $f = shift;
	return sub {
		my $cv = shift;
		my $cv_result = AE::cv;
		$cv->cb(sub {
			my $v = $_[0]->recv;
			$cv_result->send($f->($v));
		});

		return $cv_result;
	};
}

sub m_bind($$) {
	my ($cv, $f) = @_;
	my $cv2 = (m_map $f)->($cv);
	return m_join $cv2;
}

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
