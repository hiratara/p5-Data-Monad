package Data::Monad;
use strict;
use warnings;

sub unit {
    my ($class, @v) = @_;
    die "You should override this method.";
}

sub lift {
    my ($class, $f) = @_;

    sub {
        my @ms = @_;
        my @args = (undef) x @ms;

        $class->for(
            (map {
                my $i = $_;
                # capture each value in each slot of @args
                sub { $ms[$i] } => ($args[$i] = []);
            } 0 .. $#ms),
            sub { $class->unit($f->(map { @$_ } @args)) }
        );
    };
}

sub for {
    my ($class, @blocks) = @_;

    my $loop; $loop = sub {
        my @blocks = @_;
        my $block = shift @blocks;

        my $m;
        if (! ref $block and $block eq 'yield') {
            $block = shift @blocks;
            $m = $class->unit($block->());
        } else {
            $m = $block->();
        }

        my $ref = shift @blocks if ref($blocks[0]) =~ /^(ARRAY|SCALAR)$/;

        if (@blocks) {
            return $m->flat_map(sub {
                # capture values for nested blocks.
                ref $ref eq 'ARRAY' ? (@$ref = @_) : ($$ref = shift);
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
