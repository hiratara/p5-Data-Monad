package Data::Monad::Maybe;
use strict;
use warnings;
use parent qw/Data::Monad::Base::MonadZero/;
use Scalar::Util qw/reftype/;
use Exporter qw/import/;

our @EXPORT = qw/just nothing/;

sub just { bless [@_], __PACKAGE__ }
sub nothing() { bless \(my $d = undef), __PACKAGE__ }

sub unit {
    my $class = shift;
    just @_;
}

sub zero {
    my $class = shift;
    nothing;
}

sub flat_map {
    my ($self, $f) = @_;
    $self->is_nothing ? $self : $f->($self->value);
}

sub is_nothing { reftype $_[0] ne 'ARRAY' }
sub value { wantarray ? @{$_[0]} : $_[0][0] }

1;
