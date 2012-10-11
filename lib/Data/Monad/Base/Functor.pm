package Data::Monad::Base::Functor;
use strict;
use warnings;

sub map {
    my ($self, $f) = @_;
    die "Implement in subclasses";
}

1;
