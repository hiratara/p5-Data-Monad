package Data::Monad::AECV;
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


package Data::Monad::AECV::Base;
use strict;
use warnings;
use Carp ();
use Scalar::Util ();
use AnyEvent ();

# extends AE::cv directly
require Data::Monad;
push @AnyEvent::CondVar::ISA, __PACKAGE__, 'Data::Monad';

sub unit {
    my ($class, @v) = @_;

    my $cv = AE::cv;
    $cv->send(@v);
    return $cv;
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
