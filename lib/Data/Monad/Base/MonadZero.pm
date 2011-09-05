package Data::Monad::Base::MonadZero;
use strict;
use warnings;
use parent qw/Data::Monad::Base::Monad/;

sub zero {
    my $class = shift;
    die "You should override this method.";
}

sub filter {
    my ($self, $predicate) = @_;
    $self->flat_map(sub {
        $predicate->(@_) ? (ref $self)->unit(@_) : (ref $self)->zero;
    });
}

1;

