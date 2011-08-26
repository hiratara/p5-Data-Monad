use strict;
use warnings;
use MonadUtil;
use Data::Monad::AECV;
use AnyEvent;
use Test::More;

my $m = Data::Monad::AECV->monad;
my $cv213 = do {
	my $cv = AE::cv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send(2, 1, 3);
		undef $t;
	};
	$m->new(cv => $cv);
};

# naturality
my $f = sub { map {$_ * 2} @_ };

my $unit_f = composition($m->map($f), sub { $m->unit(@_) });
my $f_unit = composition(sub { $m->unit(@_) }, $f);
is_deeply [$unit_f->(2, 1, 3)->recv], [4, 2, 6];
is_deeply [$f_unit->(2, 1, 3)->recv], [4, 2, 6];

# unit
my $unit_map_join = composition(sub { $_[0]->join }, sub { $m->unit(@_) });
my $map_unit_join = composition(
	sub { $_[0]->join }, $m->map(sub { $m->unit(@_) })
);
is_deeply [$unit_map_join->($cv213)->recv], [2, 1, 3];
is_deeply [$map_unit_join->($cv213)->recv], [2, 1, 3];

done_testing;
