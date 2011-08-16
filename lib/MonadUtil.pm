package MonadUtil;
use AnyEvent;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/composition m_unit m_join m_map m_bind m_lift2/;

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

sub m_join($) {
	my $cv2 = shift;

	my $cv_mixed = AE::cv;
	$cv2->cb(sub {
		my $cv = $_[0]->recv;
		$cv->cb(sub {
			my @v = $_[0]->recv;
			$cv_mixed->send(@v);
		});
	});

	return $cv_mixed;
}

sub m_map($) {
	my $f = shift;
	return sub {
		my $cv = shift;
		my $cv_result = AE::cv;
		$cv->cb(sub {
			my @v = $_[0]->recv;
			$cv_result->send($f->(@v));
		});

		return $cv_result;
	};
}

sub m_bind($$) {
	my ($cv, $f) = @_;
	my $cv2 = (m_map $f)->($cv);
	return m_join $cv2;
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

1;
