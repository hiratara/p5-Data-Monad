package Data::MonadZero;
use strict;
use warnings;
use parent qw/Data::Monad/;

sub zero {
    my $class = shift;
    die "You should override this method.";
}

sub filter {
    my ($self, $predicate) = @_;
    $self->flat_map(sub { $predicate->(@_) ? $self->unit(@_) : $self->zero });
}

1;

