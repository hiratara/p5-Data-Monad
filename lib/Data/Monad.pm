package Data::Monad;
use strict;
use warnings;

sub unit {
    my ($class, @v) = @_;
    die "You should override this method.";
}

sub lift {
    my ($class, $f) = @_;

    my $loop; $loop = sub {
        my ($m_list, $arg_list) = @_;

        if (@$m_list) {
            my $car = $m_list->[0];
            my @cdr = @{$m_list}[1 .. $#{$m_list}];

            return $car->flat_map(sub { $loop->(\@cdr, [@$arg_list, @_]) });
        } else {
            return $class->unit($f->(@$arg_list));
        }
    };

    sub { $loop->(\@_, []) };
}

sub flat_map {
    my ($self, $f) = @_;
    die "You should override this method.";
}

sub map {
    my ($self, $f) = @_;

    $self->flat_map(sub { (ref $self)->unit($f->(@_)) });
}

sub flatten {
    my $self_duplexed = shift;

    $self_duplexed->flat_map(sub { @_ });
}

1;
