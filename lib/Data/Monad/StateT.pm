package Data::Monad::StateT;
use strict;
use warnings;
use parent qw/Data::Monad::Base::Monad/;

sub _safe_name($) {
    my $name = shift;
    $name =~ s|::|__|g;
    return "__$name";
}

sub new_class {
    my $class = shift;
    my ($inner_monad) = @_;

    my $class_name = __PACKAGE__ . '::' . _safe_name($inner_monad);
    unless ($class_name->isa(__PACKAGE__)) {
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

    $class->new(sub {
        my @s = @_;
        $m->map(sub {
            my @v = @_;
            return \@v, \@s;
        });
    });
}

sub new {
    my $class = shift;
    my ($code) = @_;
    bless $code, $class;
}

sub unit {
    my $class = shift;
    my @v = @_;

    $class->new(sub {
        my @s = @_;
        $class->inner_monad->unit(\@v, \@s);
    });
}

sub zero {
    my $class = shift;
    $class->new(sub { $class->inner_monad->zero });
}

sub get {
    my $class = shift;

    $class->new(sub {
        my @s = @_;
        $class->inner_monad->unit(\@s, \@s);
    });
}

sub set {
    my ($class, @s) = @_;

    $class->new(sub {
        $class->inner_monad->unit([], \@s);
    });
}

sub flat_map {
    my ($self, $f) = @_;

    (ref $self)->new(sub {
        my @s = @_;
        $self->(@s)->flat_map(sub {
            my ($v, $s) = @_;
            $f->(@$v)->(@$s);
        });
    });
}

sub eval {
    my ($self, @s) = @_;

    $self->(@s)->map(sub {
        my ($v, $s) = @_;
        @$v;
    });
}

sub exec {
    my ($self, @s) = @_;

    $self->(@s)->map(sub {
        my ($v, $s) = @_;
        @$s;
    });
}

1;
