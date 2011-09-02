use strict;
use warnings;
use Data::Monad::CondVar;
use Data::MonadSugar;
use AnyEvent;
use Coro;
use Coro::AnyEvent;
use Benchmark qw(:hireswallclock);

my ($delay, $count) = @ARGV;
$delay //= 0;
$count //= 20000;
sub cv($) {
    my $v = shift;
    my $cv = AE::cv;
    my $t; $t = AE::timer $delay, 0, sub {
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

sub coro($$) {
    my ($cv1, $cv2) = @_;
    async {
        my $x = $cv1->recv;
        my $y = $cv2->recv;
        $x * $y;
    }->join;
}

my $r = Benchmark::timethese($count => {
    bare_ae => sub { bare_ae(cv 5, cv 4) },
    monad   => sub { monad(cv 5, cv 4)   },
    coro    => sub { coro(cv 5, cv 4)    },
});
for my $v (values %$r) {
    $v->[1] = $v->[3] = $v->[0];
    $v->[2] = $v->[4] = 0;
}
Benchmark::cmpthese($r);

__END__

% perl -Ilib eg/bench_cv.pl .0001 10000
Benchmark: timing 10000 iterations of bare_ae, coro, monad...
   bare_ae: 1.15208 wallclock secs ( 0.70 usr +  0.06 sys =  0.76 CPU) @ 13157.89/s (n=10000)
      coro: 1.15202 wallclock secs ( 0.70 usr +  0.06 sys =  0.76 CPU) @ 13157.89/s (n=10000)
     monad: 1.23461 wallclock secs ( 1.20 usr +  0.03 sys =  1.23 CPU) @ 8130.08/s (n=10000)
          Rate   monad bare_ae    coro
monad   4050/s      --     -7%     -7%
bare_ae 4340/s      7%      --     -0%
coro    4340/s      7%      0%      --

% perl -Ilib eg/bench_cv.pl 0 20000
% perl -Ilib eg/bench_cv.pl 0 20000
Benchmark: timing 20000 iterations of bare_ae, coro, monad...
   bare_ae: 1.01343 wallclock secs ( 0.97 usr +  0.05 sys =  1.02 CPU) @ 19607.84/s (n=20000)
      coro: 1.10839 wallclock secs ( 1.06 usr +  0.05 sys =  1.11 CPU) @ 18018.02/s (n=20000)
     monad: 2.72715 wallclock secs ( 2.65 usr +  0.08 sys =  2.73 CPU) @ 7326.01/s (n=20000)
          Rate   monad    coro bare_ae
monad   3667/s      --    -59%    -63%
coro    9022/s    146%      --     -9%
bare_ae 9867/s    169%      9%      --
