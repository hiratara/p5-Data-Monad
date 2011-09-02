package Data::Monad::CondVar;
use strict;
use warnings;
use AnyEvent;
use Exporter qw/import/;

our @EXPORT = qw/call_cc/;

sub call_cc(&) {
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


package Data::Monad::CondVar::Mixin;
use strict;
use warnings;
use Carp ();
use Scalar::Util ();
use AnyEvent ();

# extends AE::cv directly
require Data::MonadZero;
for my $mixin (__PACKAGE__, 'Data::MonadZero') {
    next if grep { $_ eq $mixin } @AnyEvent::CondVar::ISA;
    push @AnyEvent::CondVar::ISA, $mixin;
}

our $ZERO = "[ZERO of ${\ __PACKAGE__}]";

sub unit {
    my ($class, @v) = @_;

    my $cv = AE::cv;
    $cv->send(@v);
    return $cv;
}

sub zero {
    my $class = shift;
    (my $cv = AE::cv)->croak($ZERO);
    return $cv;
}

sub flat_map {
    my ($self, $f) = @_;

    my $cv_bound = AE::cv;
    $self->cb(sub {
        my ($cv) = eval { $f->($_[0]->recv) };
        if ($@) {
            $cv_bound->croak($@);
            return
        }
        $cv->cb(sub {
            my @v = eval { $_[0]->recv };
            $@ ? $cv_bound->croak($@) : $cv_bound->send(@v);
        });
    });

    return $cv_bound;
}

# Overridden (for performance)
sub map {
    my ($self, $f) = @_;

    my $done = AE::cv;
    $self->cb(sub {
        my @v = eval { $f->($_[0]->recv) };
        $@ ? $done->croak($@) : $done->send(@v);
    });

    return $done;
}

sub or {
    my ($self, $alter) = @_;

    my $cv_mixed = AE::cv;
    $self->cb(sub {
        my @v = eval { $_[0]->recv };
        unless ($@) {
            $cv_mixed->(@v);
        } elsif ($@ =~ /\Q$ZERO\E/) {
            $alter->cb(sub {
                my @v = eval { $_[0]->recv };
                $@ ? $cv_mixed->croak($@) : $cv_mixed->(@v);
            });
        } else {
            $cv_mixed->croak($@);
        }
    });

    $cv_mixed;
}

1;
