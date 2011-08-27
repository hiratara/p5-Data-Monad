package Data::Monad::AECV;
use strict;
use warnings;
use AnyEvent;
use parent qw/Data::Monad/;
use parent -norequire => qw/AnyEvent::CondVar/;

sub AE::mcv(;&) {
    bless &AE::cv(@_), __PACKAGE__; # skip the prototype check
}

sub unit {
    my ($class, @v) = @_;

    my $cv = AE::mcv;
    $cv->send(@v);
    return $cv;
}

sub call_cc {
    my ($class, $f) = @_;
    my $ret_cv = AE::mcv;

    my $skip = sub {
        my @v = @_;
        $ret_cv->send(@v);

        return AE::mcv; # nop
    };

    $f->($skip)->cb(sub {
        my @v = eval { $_[0]->recv };
        $@ ? $ret_cv->croak($@) : $ret_cv->send(@v);
    });

    return $ret_cv;
}

sub flat_map {
    my ($self, $f) = @_;

    my $cv_bound = AE::mcv;
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
