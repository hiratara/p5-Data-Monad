package Data::Monad::MaybeT;
use strict;
use warnings;
use parent qw/Data::Monad::Base::MonadZero/;
use Data::Monad::Maybe ();

sub _safe_name($) {
    my $name = shift;
    $name =~ s|::|__|g;
    return "__$name";
}

sub new_class {
    my $class = shift;
    my ($inner_monad) = @_;

    my $class_name = __PACKAGE__ . '::' . _safe_name($inner_monad);
    {
        no strict qw/refs/;
        @{"$class_name\::ISA"} = (__PACKAGE__);
        *{"$class_name\::inner_monad"} = sub { $inner_monad };
    }

    return $class_name;
}

sub inner_monad { die "Implement this method in sub classes" }

sub t_lift {
    my $class = shift;
    my ($m) = @_;
    $class->new($m->map(\&Data::Monad::Maybe::just));
}

sub new {
    my $class = shift;
    my ($m) = @_;
    bless \$m, $class;
}

sub unit {
    my $class = shift;
    $class->t_lift($class->inner_monad->unit(@_));
}

sub zero {
    my $class = shift;
    $class->new(
        $class->inner_monad->unit(Data::Monad::Maybe::nothing)
    );
}

sub flat_map {
    my ($self, $f) = @_;
    (ref $self)->new(
        $$self->flat_map(sub {
            my ($maybe) = @_;
            $maybe->is_nothing ? (ref $self)->inner_monad->unit(
                                     Data::Monad::Maybe::nothing
                                 ) : ${$f->($maybe->value)};
        })
    );
}

sub value { ${$_[0]} }

1;
