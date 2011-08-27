use strict;
use warnings;
use Data::Monad::AECV;
use Test::More;

my $cv = AE::cv;
$cv->send("ABCDE");
is AE::to_mcv($cv)->map(sub { length $_[0] })->recv, 5;

done_testing;
