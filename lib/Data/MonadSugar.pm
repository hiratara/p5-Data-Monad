package Data::MonadSugar;
use strict;
use warnings;
use Exporter qw/import/;

our @EXPORT = qw/pick satisfy yield let/;

our $_PICK = our $_SATISFY = 
    our $_YIELD = our $_LET = sub { die "called outside for()." };
sub pick($;$)  { $_PICK->(@_)    }
sub satisfy(&) { $_SATISFY->(@_) }
sub yield(&)   { $_YIELD->(@_)   }
sub let($$)    { $_LET->(@_)     }

sub _capture {
    my $ref = pop;
    ref $ref eq 'ARRAY' ? (@$ref = @_) : ($$ref = $_[0]);
}

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

        local $_LET = sub {
            my ($ref, $block) = @_;

            push @blocks, {ref => $ref, block => $block, is_let => 1};
        };
        $code->();
    }

    my $loop; $loop = sub {
        my @blocks = @_;

        my $info = shift @blocks;
        my $m = $info->{block}->();
        my $ref = $info->{ref};

        if ($info->{is_let}) {
            _capture $m => $ref;
            return $loop->(@blocks);
        }

        if ($info->{satisfy}) {
            $m = $m->filter(sub {
                _capture @_ => $ref;
                $info->{satisfy}->(@_);
            });
        }

        if ($info->{yield}) {
            return $m->map(sub {
                _capture @_ => $ref;
                $info->{yield}->();
            });
        } elsif (@blocks) {
            return $m->flat_map(sub {
                _capture @_ => $ref;
                $loop->(@blocks);
            });
        } else {
            return $m;
        }
    };

    return $loop->(@blocks);
}

1;
