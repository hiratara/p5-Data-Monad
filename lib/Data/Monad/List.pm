package Data::Monad::List;
use strict;
use warnings;
use Exporter qw/import/;
use base qw/Data::Monad/;

our @EXPORT = qw/list/;

sub list($) { __PACKAGE__->new(@_) }

sub new { bless $_[1], $_[0] }

sub unit {
    my ($class, $v) = @_;

    return list [$v];
}

sub flat_map {
    my ($self, $f) = @_;

    list [map { @{$f->($_)} } @$self];
}

1;
