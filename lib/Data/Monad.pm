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

sub for {
    my ($class, @blocks) = @_;

    my $loop; $loop = sub {
        my @blocks = @_;
        my $m = (shift @blocks)->();
        my $ref = shift @blocks unless ref $blocks[0] eq 'CODE';

        if (@blocks) {
            return $m->flat_map(sub {
                # capture values for nested blocks.
                ref $ref eq 'ARRAY' ? @$ref = @_ : $$ref = shift;
                $loop->(@blocks)
            });
        } else {
            return $m;
        }
    };

    return $loop->(@blocks);
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
