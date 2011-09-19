use strict;
use warnings;
use Data::Monad::Base::Transformer;
use Test::More;

{
    package SubTransformer;
    use parent qw/Data::Monad::Base::Transformer/;
}

my $sub_class = eval { SubTransformer->new_class('Data::Monad::Base::Monad') };
ok ! $@, "There are no errrors.";
isa_ok $sub_class, 'SubTransformer';

my $sub_sub_class = eval { $sub_class->new_class('Data::Monad::Base::Monad') };
ok $@, "Shouldn't call the new_class() method from sub classes.";

done_testing;
