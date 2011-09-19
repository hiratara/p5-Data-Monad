package Data::Monad::State;
use strict;
use warnings;
use Data::Monad::StateT;
use Data::Monad::Identity;
use Exporter qw/import/;

our @ISA = Data::Monad::StateT->new_class("Data::Monad::Identity");
our @EXPORT = qw/state/;

sub state(&) { __PACKAGE__->new_state(@_) }

sub new_state {
    my $class = shift;
    my ($code) = @_;

    $class->new(sub {
        my @s = @_;
        $class->inner_monad->unit($code->(@s));
    });
}

sub run_state {
    my $self = shift;
    $self->(@_)->value;
};

sub eval_state {
    my ($self, @s) = @_;
    my ($vs, $ss) = $self->run_state(@s);
    wantarray ? @$vs : $vs->[0];
}

sub exec_state {
    my ($self, @s) = @_;
    my ($vs, $ss) = $self->run_state(@s);
    wantarray ? @$ss : $ss->[0];
}

1;

