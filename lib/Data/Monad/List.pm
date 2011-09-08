package Data::Monad::List;
use strict;
use warnings;
use Exporter qw/import/;
use base qw/Data::Monad::Base::MonadZero/;

our @EXPORT = qw/scalar_list list_unit list_zero list_lift list_sequence/;

sub scalar_list(@) { __PACKAGE__->new(map { [$_] } @_) }

sub list_unit { __PACKAGE__->unit(@_) }
sub list_zero { __PACKAGE__->zero(@_) }
sub list_lift { __PACKAGE__->lift(@_) }
sub list_sequence { __PACKAGE__->sequence(@_) }

sub new {
    my $class = shift;
    bless [@_], $class;
}

sub unit {
    my $class = shift;
    $class->new([@_]);
}

sub zero {
    my $class = shift;
    $class->new();
}

sub flat_map {
    my ($self, $f) = @_;
    (ref $self)->new(map { @{$f->(@$_)} } @$self);
}

sub scalars {
    my $self = shift;
    map {
        @$_ == 1 or die "contained multiple values.";
        @$_;
    } @$self;
}

1;
