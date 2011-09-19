package Data::Monad::State;
use strict;
use warnings;
use overload '&{}' => sub {
    my $self = shift;
    sub { $$self->(@_)->value };
}, fallback => 1;

use Data::Monad::StateT;
use Data::Monad::Identity;
use parent qw/Data::Monad::Base::Monad/;
use Exporter qw/import/;

our @EXPORT = qw/state/;

my $delegate = Data::Monad::StateT->new_class("Data::Monad::Identity");

sub state(&) {
    my ($code) = @_;

    my $state_t = $delegate->new(sub {
        my @s = @_;
        $delegate->inner_monad->unit($code->(@s));
    });

    __PACKAGE__->wrap($state_t);
}

sub wrap {
    my $class = shift;
    my ($state_t) = @_;
    bless \$state_t, $class;
}

sub unit {
    my $class = shift;
    $class->wrap($delegate->unit(@_));
}

sub get {
    my $class = shift;
    $class->wrap($delegate->get(@_));
}

sub set {
    my $class = shift;
    $class->wrap($delegate->set(@_));
}

sub flat_map {
    my ($self, $f) = @_;
    my $state_t = $$self->flat_map(sub { ${$f->(@_)} });
    (ref $self)->wrap($state_t);
}

sub eval {
    my ($self, @s) = @_;
    my ($vs, $ss) = $self->(@s);
    wantarray ? @$vs : $vs->[0];
}

sub exec {
    my ($self, @s) = @_;
    my ($vs, $ss) = $self->(@s);
    wantarray ? @$ss : $ss->[0];
}

1;

