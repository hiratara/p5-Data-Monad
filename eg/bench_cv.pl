use strict;
use warnings;
use Data::Monad::CondVar;
use Data::MonadSugar;
use AnyEvent;
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


my $r = Benchmark::timethese($count => {
    bare_ae => sub { bare_ae(cv 5, cv 4) },
    monad   => sub { monad(cv 5, cv 4)   },
});
for my $v (values %$r) {
    $v->[1] = $v->[3] = $v->[0];
    $v->[2] = $v->[4] = 0;
}
Benchmark::cmpthese($r);

__END__

% perl -Ilib eg/bench_cv.pl .0001 10000
Benchmark: timing 10000 iterations of bare_ae, monad...
   bare_ae: 1.14857 wallclock secs ( 0.65 usr +  0.06 sys =  0.71 CPU) @ 14084.51/s (n=10000)
     monad: 1.12756 wallclock secs ( 1.09 usr +  0.03 sys =  1.12 CPU) @ 8928.57/s (n=10000)
          Rate bare_ae   monad
bare_ae 4353/s      --     -2%
monad   4434/s      2%      --

% perl -Ilib eg/bench_cv.pl 0 20000
Benchmark: timing 20000 iterations of bare_ae, monad...
   bare_ae: 0.793745 wallclock secs ( 0.76 usr +  0.04 sys =  0.80 CPU) @ 25000.00/s (n=20000)
     monad: 2.20375 wallclock secs ( 2.14 usr +  0.06 sys =  2.20 CPU) @ 9090.91/s (n=20000)
           Rate   monad bare_ae
monad    4538/s      --    -64%
bare_ae 12599/s    178%      --
