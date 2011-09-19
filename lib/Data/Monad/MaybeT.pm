package Data::Monad::MaybeT;
use strict;
use warnings;
use parent qw/Data::Monad::Base::MonadZero Data::Monad::Base::Transformer/;
use Data::Monad::Maybe ();

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
