package Data::Monad::List;
use strict;
use warnings;
use Exporter qw/import/;
use base qw/Data::MonadZero/;

our @EXPORT = qw/list/;

sub list($) { bless $_[0], __PACKAGE__ }

sub unit { bless [$_[1]], __PACKAGE__ }

sub zero { bless [], __PACKAGE__ }

sub flat_map {
    bless [map { @{$_[1]->($_)} } @{$_[0]}], __PACKAGE__;
}

1;
