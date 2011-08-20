use strict;
use warnings;
use MonadUtil;
use AnyEvent;
use Test::More;

my $cv213 = do {
	my $cv = AE::cv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send(2, 1, 3);
		undef $t;
	};
	$cv;
};

sub create_cv($) {
	my $should_skip = shift;
	my $cv1 = m_bind $cv213 => sub {
		my @v = @_;

		m_call_cc {
			my $skip = shift;

			my $cv213 = m_unit @v;
			my $cv426 = m_bind $cv213 => sub { m_unit map { $_ * 2 } @_ };
			my $cv_skipped = m_bind $cv426 => sub {
				$should_skip ? $skip->(@_) : m_unit @_
			};

			return m_bind $cv_skipped => sub { m_unit map { $_ * 2 } @_ };
		};
	};
	return m_bind $cv1 => sub { m_unit map { $_ * 3 } @_ };
}


is_deeply [(create_cv 1)->recv], [12, 6, 18];
is_deeply [(create_cv 0)->recv], [24, 12, 36];

done_testing;
