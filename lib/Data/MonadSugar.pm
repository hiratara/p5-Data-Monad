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

    # XXX special pattern. Capture multiple values.
    if (ref $ref eq 'HASH') {
        for my $k (keys %$ref) {
            _capture(@{$_[0]->{$k}} => $ref->{$k});
        }
        return;
    }

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
            die "satisfy() should be called after pick()." unless @blocks;

            my $orig_block = $blocks[$#blocks]->{block};
            my $orig_ref   = $blocks[$#blocks]->{ref};
            $blocks[$#blocks]->{block} = sub {
                $orig_block->()->filter(sub {
                    _capture @_ => $orig_ref;
                    $predicate->(@_);
                });
            };
        };

        local $_LET = sub {
            my ($ref, $block) = @_;

            unless (@blocks) {
                # eval immediately because we aren't in any lambdas.
                _capture $block->() => $ref;
                return;
            }

            my $orig_block = $blocks[$#blocks]->{block};
            my $orig_ref   = $blocks[$#blocks]->{ref};

            # XXX Special pattern. Capture multiple values.
            #     A tupple is used in "p <- e; p' = e'" pattern.
            #     See: http://www.scala-lang.org/docu/files/ScalaReference.pdf
            $blocks[$#blocks]->{ref} = {ref => $orig_ref, let => $ref};
            $blocks[$#blocks]->{block} = sub {
                $orig_block->()->map(sub {
                    _capture @_ => $orig_ref;
                    return {ref => [@_], let => [$block->()]};
                });
            };
        };
        $code->();
    }

    my $loop; $loop = sub {
        my @blocks = @_;

        my $info = shift @blocks;
        my $m = $info->{block}->();
        my $ref = $info->{ref};

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
