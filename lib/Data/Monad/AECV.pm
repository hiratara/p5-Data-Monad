package Data::Monad::AECV;
use strict;
use warnings;
use Carp ();
use Scalar::Util ();
use AnyEvent ();
use parent qw/Data::Monad/;

# extends AE::cv directly
push @AnyEvent::CondVar::ISA, __PACKAGE__;

sub unit {
    my ($class, @v) = @_;

    my $cv = AE::cv;
    $cv->send(@v);
    return $cv;
}

sub call_cc {
    my ($class, $f) = @_;
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

sub flat_map {
    my ($self, $f) = @_;

    my $cv_bound = AE::cv;
    $self->cb(sub {
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

1;
