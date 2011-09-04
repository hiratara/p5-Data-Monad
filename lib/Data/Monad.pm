package Data::Monad;
use strict;
use warnings;
use Data::MonadSugar;

sub unit {
    my ($class, @v) = @_;
    die "You should override this method.";
}

sub lift {
    my ($class, $f) = @_;

    sub {
        my @ms = @_;

        Data::MonadSugar::for {
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

Data::Monad -

=head1 SYNOPSIS

  use Data::Monad;

=head1 DESCRIPTION

Data::Monad is

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

