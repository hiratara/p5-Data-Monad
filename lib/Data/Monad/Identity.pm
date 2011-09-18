package Data::Monad::Identity;
use strict;
use base;
use parent qw/Data::Monad::Base::Monad/;

sub new {
    my $class = shift;
    bless [@_], $class;
}

sub unit {
    my $class = shift;
    $class->new(@_);
}

sub flat_map {
    my ($m, $f) = @_;
    $f->($m->value);
}

sub value { wantarray ? @{$_[0]} : $_[0][0] }

1;
