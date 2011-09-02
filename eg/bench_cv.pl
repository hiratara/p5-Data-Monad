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
   bare_ae: 0.919773 wallclock secs ( 0.88 usr +  0.04 sys =  0.92 CPU) @ 21739.13/s (n=20000)
      coro: 0.965312 wallclock secs ( 0.92 usr +  0.04 sys =  0.96 CPU) @ 20833.33/s (n=20000)
     monad: 1.36842 wallclock secs ( 1.33 usr +  0.04 sys =  1.37 CPU) @ 14598.54/s (n=20000)
 monad_for: 2.07753 wallclock secs ( 2.02 usr +  0.05 sys =  2.07 CPU) @ 9661.84/s (n=20000)
             Rate monad_for     monad      coro   bare_ae
monad_for  4813/s        --      -34%      -54%      -56%
monad      7308/s       52%        --      -29%      -33%
coro      10359/s      115%       42%        --       -5%
bare_ae   10872/s      126%       49%        5%        --
