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
Benchmark: timing 20000 iterations of bare_ae, coro, monad, monad_for...
   bare_ae: 0.982566 wallclock secs ( 0.94 usr +  0.04 sys =  0.98 CPU) @ 20408.16/s (n=20000)
      coro: 0.946208 wallclock secs ( 0.90 usr +  0.04 sys =  0.94 CPU) @ 21276.60/s (n=20000)
     monad: 1.64958 wallclock secs ( 1.60 usr +  0.05 sys =  1.65 CPU) @ 12121.21/s (n=20000)
 monad_for: 2.42338 wallclock secs ( 2.36 usr +  0.06 sys =  2.42 CPU) @ 8264.46/s (n=20000)
             Rate monad_for     monad   bare_ae      coro
monad_for  4126/s        --      -32%      -59%      -61%
monad      6062/s       47%        --      -40%      -43%
bare_ae   10177/s      147%       68%        --       -4%
coro      10568/s      156%       74%        4%        --
