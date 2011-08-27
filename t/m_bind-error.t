use strict;
use warnings;
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

my $f = sub {
	my @v = @_;

	my $cv = AE::cv;
	$cv->croak(join '', @v, "\n");
	return $m->new(cv => $cv);
};

my $g = sub { $m->unit(map {$_ * 2} @_) };

my $ret_cv = $cv213->flat_map($f)->flat_map($g);
eval { $ret_cv->recv };
like $@, qr/\b213\b/;

done_testing;
