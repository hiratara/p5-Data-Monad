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
        my $x = eval {$_[0]->recv};
        $@ and $cv->croak($@);
        $cv2->cb(sub {
            my $y = eval {$_[0]->recv};
            $@ and $cv->croak($@);
            $cv->send($x * $y);
        });
    });
    $cv->recv;
}

sub monad($$) {
    my ($cv1, $cv2) = @_;
    $cv1->flat_map(sub {
        my $x = shift;
        $cv2->map(sub {
            my $y = shift;
            $x * $y;
        });
    })->recv;
}

sub monad_lift($$) {
    my ($cv1, $cv2) = @_;
    AnyEvent::CondVar->lift(sub {$_[0] * $_[1]})->($cv1, $cv2)->recv;
}

sub monad_for($$) {
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
    bare_ae   => sub { bare_ae(cv 5, cv 4)   },
    monad_for => sub { monad_for(cv 5, cv 4) },
    monad     => sub { monad(cv 5, cv 4)     },
    monad_lift=> sub { monad_lift(cv 5, cv 4)},
    coro      => sub { coro(cv 5, cv 4)      },
});
for my $v (values %$r) {
    $v->[1] = $v->[3] = $v->[0];
    $v->[2] = $v->[4] = 0;
}
Benchmark::cmpthese($r);

__END__

% perl -Ilib eg/bench_cv.pl .0001 10000
Benchmark: timing 10000 iterations of bare_ae, coro, monad, monad_for...
   bare_ae: 1.14658 wallclock secs ( 0.71 usr +  0.06 sys =  0.77 CPU) @ 12987.01/s (n=10000)
      coro: 1.1488 wallclock secs ( 0.71 usr +  0.06 sys =  0.77 CPU) @ 12987.01/s (n=10000)
     monad: 1.07258 wallclock secs ( 0.83 usr +  0.05 sys =  0.88 CPU) @ 11363.64/s (n=10000)
 monad_for: 1.21419 wallclock secs ( 1.18 usr +  0.03 sys =  1.21 CPU) @ 8264.46/s (n=10000)
            Rate monad_for      coro   bare_ae     monad
monad_for 4118/s        --       -5%       -6%      -12%
coro      4352/s        6%        --       -0%       -7%
bare_ae   4361/s        6%        0%        --       -6%
monad     4662/s       13%        7%        7%        --

% perl -Ilib eg/bench_cv.pl 0 20000
Benchmark: timing 20000 iterations of bare_ae, coro, monad, monad_for, monad_lift...
   bare_ae: 0.967884 wallclock secs ( 0.93 usr +  0.04 sys =  0.97 CPU) @ 20618.56/s (n=20000)
      coro: 0.967329 wallclock secs ( 0.93 usr +  0.04 sys =  0.97 CPU) @ 20618.56/s (n=20000)
     monad: 1.34422 wallclock secs ( 1.30 usr +  0.04 sys =  1.34 CPU) @ 14925.37/s (n=20000)
 monad_for: 2.04411 wallclock secs ( 1.99 usr +  0.05 sys =  2.04 CPU) @ 9803.92/s (n=20000)
monad_lift: 2.2946 wallclock secs ( 2.24 usr +  0.06 sys =  2.30 CPU) @ 8695.65/s (n=20000)
              Rate monad_lift  monad_for      monad    bare_ae       coro
monad_lift  4358/s         --       -11%       -41%       -58%       -58%
monad_for   4892/s        12%         --       -34%       -53%       -53%
monad       7439/s        71%        52%         --       -28%       -28%
bare_ae    10332/s       137%       111%        39%         --        -0%
coro       10338/s       137%       111%        39%         0%         --
