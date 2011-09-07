package Data::Monad::CondVar;
use strict;
use warnings;
use AnyEvent;
use Exporter qw/import/;

our @EXPORT = qw/as_cv call_cc/;

sub _assert_cv($) {
    $_[0]->ready and die "[BUG]It already has been ready";
    $_[0];
}

sub as_cv(&) {
    my $code = shift;
    $code->(my $cv = AE::cv);
    $cv;
}

sub call_cc(&) {
    my $f = shift;
    my $ret_cv = AE::cv;

    my $skip = sub {
        my @v = @_;
        _assert_cv $ret_cv;
        $ret_cv->send(@v);

        return AE::cv; # nop
    };

    $f->($skip)->cb(sub {
        my @v = eval { $_[0]->recv };
        _assert_cv $ret_cv;
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

*_assert_cv = \&Data::Monad::CondVar::_assert_cv;

sub unit {
    my $class = shift;
    (my $cv = AE::cv)->send(@_);
    return $cv;
}

sub fail {
    my $class = shift;
    (my $cv = AE::cv)->croak(@_);
    return $cv;
}

sub zero { $_[0]->fail($ZERO) }

sub cancel {
    my $self = shift;
    $self->ready and return;

    my $canceler = delete $self->{_monad_canceler};
    $canceler and $canceler->();

    _assert_cv $self;
    $self->croak("canceled");
}

sub canceler {
    my $cv = shift;
    @_ and $cv->{_monad_canceler} = shift;
    $cv->{_monad_canceler};
}

sub flat_map {
    my ($self, $f) = @_;

    my $cv_bound = AE::cv;
    my $cv_current = $self;
    $self->cb(sub {
        my ($cv) = ($cv_current) = eval { $f->($_[0]->recv) };

        if ($@) {
            _assert_cv $cv_bound;
            return $cv_bound->croak($@);
        }
        $cv->cb(sub {
            my @v = eval { $_[0]->recv };
            _assert_cv $cv_bound;
            $@ ? $cv_bound->croak($@) : $cv_bound->send(@v);
        });
    });
    $cv_bound->canceler(sub {
        $cv_current->cb(sub {}); # remove the callback
        $cv_current->cancel;
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
                _assert_cv $cv_mixed;
                $@ ? $cv_mixed->croak($@) : $cv_mixed->(@v);
            });
        } else {
            _assert_cv $cv_mixed;
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
        $@ and return (_assert_cv $result_cv)->croak($@);

        $cv->cb(sub {
            my @v = eval { $_[0]->recv };
            _assert_cv $result_cv;
            $@ ? $result_cv->croak($@) : $result_cv->send(@v);
        });
    });

    return $result_cv;
}

sub sleep {
    my ($self, $sec) = @_;
    $self->flat_map(sub {
        my @v = @_;
        my $cv = AE::cv;
        my $t; $t = AE::timer $sec, 0, sub { $cv->(@v) };
        $cv->canceler(sub { undef $t });
        return $cv;
    });
}

sub timeout {
    my ($self, $sec) = @_;

    my $cv = AE::cv;
    my $timeout_timer = AE::timer $sec, 0, sub {
        # XXX Seems that AE::timer pass some arguments. Ignore them.
        _assert_cv $cv;
        $cv->();
        undef $cv;
    };

    $self->map(sub {
        $cv and (_assert_cv $cv)->(@_);
        undef $timeout_timer;
        return;  # void
    });

    return $cv;
}

1;
