use strict;
use warnings;
use Data::Monad::CondVar;
use Data::MonadSugar;
use AnyEvent;
use Benchmark;

sub cv($) {
    my $v = shift;
    my $cv = AE::cv;
    my $t; $t = AE::timer .001, 0, sub {
        $cv->($v);
        undef $t;
    };
    return $cv;
}

sub bare_ae($$) {
    my ($cv1, $cv2) = @_;
    my $cv = AE::cv;
    $cv1->cb(sub {
        my $x = $_[0]->recv;
        $cv2->cb(sub {
            my $y = $_[0]->recv;
            $cv->send($x * $y);
        });
    });
    $cv->recv;
}

sub monad($$) {
    my ($cv1, $cv2) = @_;
    Data::MonadSugar::for {
        pick \my $x => sub { $cv1 };
        pick \my $y => sub { $cv2 };
        yield {$x * $y};
    }->recv;
}

Benchmark::cmpthese(5000 => {
    bare_ae => sub { bare_ae(cv 5, cv 4) },
    monad   => sub { monad(cv 5, cv 4)   },
});

__END__

% perl -Ilib eg/bench_cv.pl
          Rate   monad bare_ae
monad   5556/s      --    -40%
bare_ae 9259/s     67%      --
