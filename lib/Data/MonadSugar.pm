package Data::MonadSugar;
use strict;
use warnings;
use Exporter qw/import/;

our @EXPORT = qw/pick satisfy yield/;

our $_PICK = our $_SATISFY = our $_YIELD = sub { die "called outside for()." };
sub pick($;$)  { $_PICK->(@_)    }
sub satisfy(&) { $_SATISFY->(@_) }
sub yield(&)   { $_YIELD->(@_)   }

sub for(&) {
    my $code = shift;

    my @blocks;
    {
        local $_PICK = sub {
            my ($ref, $block) = @_;
            $block = $ref, $ref = undef unless defined $block;

            push @blocks, {ref => $ref, block => $block};
        };

        local $_YIELD = sub {
            my $block = shift;

            $blocks[$#blocks]->{yield} = $block;
        };

        local $_SATISFY = sub {
            my $predicate = shift;

            $blocks[$#blocks]->{satisfy} = $predicate;
        };
        $code->();
    }

    my $loop; $loop = sub {
        my @blocks = @_;

        my $info = shift @blocks;
        my $m = $info->{block}->();
        my $ref = $info->{ref};

        if ($info->{satisfy}) {
            $m = $m->filter(sub {
                ref $ref eq 'ARRAY' ? (@$ref = @_) : ($$ref = $_[0]);
                $info->{satisfy}->(@_);
            });
        }

        if ($info->{yield}) {
            return $m->map(sub {
                ref $ref eq 'ARRAY' ? (@$ref = @_) : ($$ref = $_[0]);
                $info->{yield}->();
            });
        } elsif (@blocks) {
            return $m->flat_map(sub {
                # capture values for nested blocks.
                ref $ref eq 'ARRAY' ? (@$ref = @_) : ($$ref = $_[0]);
                $loop->(@blocks);
            });
        } else {
            return $m;
        }
    };

    return $loop->(@blocks);
}

1;
