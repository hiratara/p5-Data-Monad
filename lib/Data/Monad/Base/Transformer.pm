package Data::Monad::Base::Transformer;
use strict;
use warnings;

sub _safe_name($) {
    my $name = shift;
    $name =~ s|::|__|g;
    return "__$name";
}

sub new_class {
    my $class = shift;
    my ($inner_monad) = @_;

    my $class_name = "$class\::" . _safe_name($inner_monad);
    unless ($class_name->isa($class)) {
        no strict qw/refs/;
        @{"$class_name\::ISA"} = ($class);
        *{"$class_name\::inner_monad"} = sub { $inner_monad };
    }

    return $class_name;
}

sub inner_monad { die "Implement this method in sub classes" }

sub t_lift { die "Implement this method in sub classes" }

1;

