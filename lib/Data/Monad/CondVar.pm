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
require Data::Monad::Base::MonadZero;
for my $mixin (__PACKAGE__, 'Data::Monad::Base::MonadZero') {
    next if grep { $_ eq $mixin } @AnyEvent::CondVar::ISA;
    push @AnyEvent::CondVar::ISA, $mixin;
}

our $ZERO = "[ZERO of ${\ __PACKAGE__}]";

sub unit {
    my $class = shift;
    (my $cv = AE::cv)->send(@_);
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

sub catch {
    my ($self, $f) = @_;

    my $result_cv = AE::cv;
    $self->cb(sub {
        my @v = eval { $_[0]->recv };
        my $exception = $@ or return $result_cv->(@v);

        my $cv = eval { $f->($exception) };
        $@ and return $result_cv->croak($@);

        $cv->cb(sub {
            my @v = eval { $_[0]->recv };
            $@ ? $result_cv->croak($@) : $result_cv->send(@v);
        });
    });

    return $result_cv;
}

1;
