use strict;
use warnings;
use Data::Monad::AECV;
use AnyEvent::HTTP;
use AnyEvent::Util;

print Data::Monad::AECV->unit("http://www.google.com")->flat_map(sub {
	my $url = shift;
	my $ret_cv = AE::cv;
	http_get $url, sub {
		$ret_cv->send($_[0]);
	};
	$ret_cv;
})->flat_map(sub {
	my $html = shift;

	my $ret;
	AnyEvent::Util::run_cmd(
		[qw/wc /], '<' => \$html, '>' => \$ret,
	)->flat_map(sub { Data::Monad::AECV->unit($ret) });
})->recv, "\n";
