package Data::Monad::CondVar;
use strict;
use warnings;
use AnyEvent;
use Exporter qw/import/;

our @EXPORT = qw/as_cv cv_unit cv_zero cv_fail cv_lift cv_sequence call_cc/;

sub _assert_cv($) {
    $_[0]->ready and die "[BUG]It already has been ready";
    $_[0];
}

sub as_cv(&) {
    my $code = shift;
    $code->(my $cv = AE::cv);
    $cv;
}

sub cv_unit { AnyEvent::CondVar->unit(@_) }
sub cv_zero { AnyEvent::CondVar->zero(@_) }
sub cv_fail { AnyEvent::CondVar->fail(@_) }
sub cv_lift { AnyEvent::CondVar->lift(@_) }
sub cv_sequence { AnyEvent::CondVar->sequence(@_) }

sub call_cc(&) {
    my $f = shift;
    my $ret_cv = AE::cv;

    my $skip = sub {
        my @v = @_;
        _assert_cv $ret_cv;
        $ret_cv->send(@v);

        return AE::cv; # nop
    };

    my $branch_cv = $f->($skip)->map(sub {
        _assert_cv $ret_cv;
        $ret_cv->send(@_);
    })->catch(sub {
        _assert_cv $ret_cv;
        $ret_cv->croak(@_);
        cv_unit; # void
    });
    $ret_cv->canceler(sub { $branch_cv->cancel });

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

sub _cv_or_die($) {
    Scalar::Util::blessed $_[0] && $_[0]->isa('AnyEvent::CondVar')
        or Carp::croak "You must use CondVar object here.";
}

sub unit {
    my $class = shift;
    (my $cv = AE::cv)->send(@_);
    return $cv;
}

sub fail {
    my $class = shift;

    # XXX cv's croak doesn't throw the error if the message is empty.
    my $msg = $_[0] || $ZERO;
    (my $cv = AE::cv)->croak($msg);

    return $cv;
}

sub zero { $_[0]->fail($ZERO) }

sub any {
    my ($class, @cvs) = @_;

    my $result_cv = AE::cv;
    for (@cvs) {
        $_->map(sub {
            _assert_cv $result_cv;
            $result_cv->send(@_);
            $result_cv->cancel;
        })->catch(sub {
            _assert_cv $result_cv;
            $result_cv->croak(@_);
            $result_cv->cancel;
            return $class->unit;
        });
    }
    $result_cv->canceler(sub { $_->cancel for @cvs });

    $result_cv;
}

sub all {
    my ($class, @cvs) = @_;

    my @result;
    (my $result_cv = AE::cv)->begin(sub {
        my ($cv) = @_;
        _assert_cv $cv;
        $cv->send(@result);
    });
    for my $i (0 .. $#cvs) {
        $result_cv->begin;

        $cvs[$i]->map(sub {
            $result[$i] = [@_];
            $result_cv->end;
        })->catch(sub {
            _assert_cv $result_cv;
            $result_cv->croak(@_);
            $result_cv->cancel;
            return $class->unit;
        });
    }
    $result_cv->end;

    $result_cv->canceler(sub { $_->cancel for @cvs });

    $result_cv;
}

sub cancel { (delete $_[0]->{_monad_canceler} || sub {})->() }

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
        my $cv = $cv_current = eval {
            my ($cv) = $f->($_[0]->recv);
            _cv_or_die $cv;
            $cv;
        };

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
    $cv_bound->canceler(sub { $cv_current->cancel });

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
    $cv_mixed->canceler(sub { $_->cancel for $self, $alter });

    $cv_mixed;
}

sub catch {
    my ($self, $f) = @_;

    my $result_cv = AE::cv;
    my $active_cv = $self;
    $self->cb(sub {
        my @v = eval { $_[0]->recv };
        my $exception = $@ or return $result_cv->(@v);

        my $cv = $active_cv = eval {
            my $cv = $f->($exception);
            _cv_or_die $cv;
            $cv;
        };
        $@ and return (_assert_cv $result_cv)->croak($@);

        $cv->cb(sub {
            my @v = eval { $_[0]->recv };
            _assert_cv $result_cv;
            $@ ? $result_cv->croak($@) : $result_cv->send(@v);
        });
    });
    $result_cv->canceler(sub { $active_cv->cancel });

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
    my $class = ref $self;

    $class->any($class->unit->sleep($sec), $self);
}

1;
