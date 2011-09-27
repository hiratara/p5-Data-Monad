use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

sub say_hello($) {
    my $success = shift;
    my $failure = 0;
    sub {
        my $name = shift;
        ++$failure < $success ? cv_fail : cv_unit "Hello, $name";
    };
}

ok cv_unit("Gaishi Takeuchi")->retry(3, say_hello 2)->recv;
ok cv_unit("Gaishi Takeuchi")->retry(3, say_hello 3)->recv;
eval { cv_unit("Gaishi Takeuchi")->retry(3, say_hello 4)->recv };
ok $@;

done_testing;
