package Data::Monad::Base::Monad;
use strict;
use warnings;
use Data::Monad::Base::Sugar;

sub unit {
    my ($class, @v) = @_;
    die "You should override this method.";
}

sub lift {
    my ($class, $f) = @_;

    sub {
        my @ms = @_;

        Data::Monad::Base::Sugar::for {
            my @args;
            for my $i (0 .. $#ms) {
                # capture each value in each slot of @args
                pick +(my $slot = []) => sub { $ms[$i] };
                push @args, $slot;
            }
            yield { $f->(map { @$_ } @args) };
        };
    };
}

sub sequence {
    my $class = shift;
    $class->lift(sub { @_ })->(@_);
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

sub ap { (ref $_[0])->lift(sub { my $c = shift; $c->(@_) })->(@_) }

1;

__END__

=head1 NAME

Data::Monad::Base::Monad - The base class of any monads.

=head1 SYNOPSIS

  package YourMonadClass;
  use base qw/Data::Monad::Base::Monad/;

  sub unit {
      my ($class, @v) = @_;
      ...
  }

  sub flat_map {
      my ($self, $f) = @_;
      ...
  }

=head1 DESCRIPTION

Data::Monad::Base::Monad provides some useful functions for any monads.

You must implement unit() and flat_map() according to monad laws.

This module is marked B<EXPERIMENTAL>. API could be changed without any notice.
I'll drop many unuseful stuffs in the future.

=head1 METHODS

=over 4

=item $m = SomeMonad->unit(@vs);

A natural transformation, which is known as "return" in Haskell.

You must implement this method in sub classes.

=item $f = SomeMonad->lift(sub { ... });

Changes the type of function from (v1, v2, ...) -> v0
to (m(v1), m(v2), ...) -> m(v0).

=item $m = SomeMonad->sequence($m1, $m2, $m3, ...);

Packs monads into the new monad.

=item $m2 = $m1->flat_map(sub { ... });

The composition of Kleisli category, which knwon as ">>=" in Haskell.

You must implement this method in sub classes.

=item $m2 = $m1->map(sub { ... });

The morphism map of the monad, which is known as "fmap" in Haskell.

=item $m = $mm->flatten;

A natural transformation, which is known as "join" in Haskell.

=item $m = $mf->ap($m1, $m2,...);

Executes the function which wrapped by the monad.

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::MonadZero>, L<Data::Monad::Base::Sugar>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

