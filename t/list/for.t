use strict;
use warnings;
use Data::Monad::List;
use Data::MonadSugar;
use Test::More;

ok eq_array(Data::MonadSugar::for {
    pick \my $x => sub { list [2, 4] };
    pick \my $y => sub { list [$x + 1] };
    pick \my $z => sub { list [$x - 1] };
    yield { $y * $z };
}, [3, 15]);

ok eq_set(Data::MonadSugar::for {
    pick \my $x => sub { list [1, 2] };
    pick \my $y => sub { list [3, 4, 5] };
    yield { "$x-$y" };
}, ["1-3", "2-3", "1-4", "2-4", "1-5", "2-5"]);

ok eq_set(Data::MonadSugar::for {
    pick \my $x => sub { list [1, 2] };
    pick \my $y => sub { list [3, 4, 5] };
    satisfy { ($x + $y) % 2 == 0 };
    yield { "$x-$y" };
}, ["1-3", "2-4", "1-5"]);


done_testing;
