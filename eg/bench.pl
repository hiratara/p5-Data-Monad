use strict;
use warnings;
use Data::Monad::List;
use Data::MonadSugar;
use Benchmark;

sub normal_99 {
    my @ret;
    for my $x (1 .. 9) {
        for my $y (1 .. 9) {
            push @ret, [$x, $y => $x * $y];
        }
    }
    return \@ret
}

sub blessed_99 {
    my @ret;
    my $range = bless [1 .. 9], 'SlowList';
    sub SlowList::list { @{shift()} }

    for my $x ($range->list) {
        for my $y ($range->list) {
            push @ret, [$x, $y => $x * $y];
        }
    }
    return \@ret
}

sub monad_99 {
    return Data::MonadSugar::for {
        pick \my $x, sub { list [1 .. 9] };
        pick \my $y, sub { list [1 .. 9] };
        yield { [$x, $y => $x * $y] }
    };
}

Benchmark::cmpthese(10000 => {
    normal_99 => \&normal_99,
    blessed_99 => \&blessed_99,
    monad_99  => \&monad_99,
});

__END__

% perl -Ilib eg/bench.pl
              Rate   monad_99 blessed_99  normal_99
monad_99    1724/s         --       -89%       -91%
blessed_99 15625/s       806%         --       -16%
normal_99  18519/s       974%        19%         --
