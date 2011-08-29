use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent::HTTP;
use AnyEvent::Util;

print AnyEvent::CondVar->unit("http://www.google.com")->flat_map(sub {
    my $url = shift;
    http_get $url, (my $ret_cv = AE::cv);
    $ret_cv;
})->flat_map(sub {
    my $html = shift;

    my $ret;
    AnyEvent::Util::run_cmd(
        [qw/wc /], '<' => \$html, '>' => \$ret,
    )->flat_map(sub { AnyEvent::CondVar->unit($ret) });
})->recv, "\n";
