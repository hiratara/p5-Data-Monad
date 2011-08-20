package MonadUtil;
use AnyEvent;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/composition m_unit m_join m_map m_bind m_lift2 m_call_cc/;

sub composition($$) {
	my ($g, $f) = @_;
	sub { $g->($f->(@_)) };
}

sub m_unit {
	my @v = @_;
	my $cv = AE::cv;
	$cv->send(@v);

	return $cv;
}

sub m_bind($$) {
	my ($cv, $f) = @_;

	my $cv_bound = AE::cv;
	$cv->cb(sub {
		my @v = eval { $_[0]->recv };
		if ($@) {
			$cv_bound->croak($@);
			return
		}
		my ($cv) = $f->(@v);
		$cv->cb(sub {
			my @v = eval { $_[0]->recv };
			$@ ? $cv_bound->croak($@) : $cv_bound->send(@v);
		});
	});

	return $cv_bound;
}

sub m_join($) {
	my $cv2 = shift;

	m_bind $cv2 => sub { @_ };
}

sub m_map($) {
	my $f = shift;

	sub {
		my $cv = shift;
		m_bind $cv => composition(\&m_unit, $f);
	};
}

sub m_lift2(&) {
	my $f = shift;
	sub {
		my ($cv_a, $cv_b) = @_;
		m_bind $cv_a => sub {
			my @v_a = @_;
			m_bind $cv_b => sub {
				my @v_b = @_;
				m_unit $f->(@v_a, @v_b);
			};
		};
	};
}

sub m_call_cc(&) {
	my $f = shift;
	my $ret_cv = AE::cv;

	my $skip = sub {
		my @v = @_;
		$ret_cv->send(@v);

		return AE::cv; # nop
	};

	$f->($skip)->cb(sub {
		my @v = eval { $_[0]->recv };
		$@ ? $ret_cv->croak($@) : $ret_cv->send(@v);
	});

	return $ret_cv;
}

1;
