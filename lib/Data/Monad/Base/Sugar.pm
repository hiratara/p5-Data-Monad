package Data::Monad::Base::Sugar;
use strict;
use warnings;
use Scalar::Util qw/blessed/;
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

    return $ref->capture(@_) if blessed $ref && $ref->can('capture');

    ref $ref eq 'ARRAY' ? (@$ref = @_) : ($$ref = $_[0]);
}

sub _tuple { bless [@_], 'Data::Monad::Base::Sugar::Tuple' }
sub Data::Monad::Base::Sugar::Tuple::capture {
    my ($self, $result) = @_;
    blessed $result && $result->isa(ref $self)
                                            or die "[BUG]result is not tuple";

    _capture @{$result->[$_]} => $self->[$_] for 0 .. $#$self;
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

            # Capture multiple values.
            # A tupple is used in "p <- e; p' = e'" pattern.
            # See: http://www.scala-lang.org/docu/files/ScalaReference.pdf
            $blocks[$#blocks]->{ref} = _tuple $orig_ref, $ref;
            $blocks[$#blocks]->{block} = sub {
                $orig_block->()->map(sub {
                    _capture @_ => $orig_ref;
                    return _tuple [@_], [$block->()];
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
