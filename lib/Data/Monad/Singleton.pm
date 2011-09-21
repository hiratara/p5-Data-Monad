package Data::Monad::Singleton;
use strict;
use warnings;
use parent qw/Data::Monad::Base::Monad/;
use Exporter qw/import/;

our @EXPORT = qw/singleton/;

sub singleton { __PACKAGE__->new }

my $instance = bless \(my $x = '*'), __PACKAGE__;
sub new { $instance }

sub unit { singleton }

sub flat_map { singleton }

1;
