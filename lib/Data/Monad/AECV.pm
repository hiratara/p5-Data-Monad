package Data::Monad::AECV;
use strict;
use warnings;
use AnyEvent;
use Class::Accessor::Lite (new => 1, rw => [qw/cv/]);
use parent qw/Data::Monad/;

sub _warp($) { __PACKAGE__->new(cv => $_[0]) }

sub unit {
    my ($class, @v) = @_;

    my $cv = AE::cv;
    $cv->send(@v);
    return _warp $cv;
}

sub call_cc {
    my ($class, $f) = @_;
    my $ret_cv = AE::cv;

    my $skip = sub {
        my @v = @_;
        $ret_cv->send(@v);

        return _warp AE::cv; # nop
    };

    $f->($skip)->cb(sub {
        my @v = eval { $_[0]->recv };
        $@ ? $ret_cv->croak($@) : $ret_cv->send(@v);
    });

    return _warp $ret_cv;
}

sub bind {
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

    return _warp $cv_bound;
}

sub recv { shift->cv->recv(@_) }
sub cb   { shift->cv->cb(@_)   }

1;
