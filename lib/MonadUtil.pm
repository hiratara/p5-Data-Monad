package MonadUtil;
use AnyEvent;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/composition/;

sub composition($$) {
	my ($g, $f) = @_;
	sub { $g->($f->(@_)) };
}

1;
