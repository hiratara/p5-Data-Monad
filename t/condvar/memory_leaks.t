use strict;
use warnings;
use Test::Requires qw/Test::LeakTrace/;
use Data::Monad::CondVar;
use Data::Monad::Base::Sugar;
use Test::More;

no_leaks_ok { cv_unit->sleep(.001)->recv };
no_leaks_ok { cv_unit->sleep(0)->flat_map(sub { cv_unit })->recv };
no_leaks_ok { cv_unit->flat_map(sub { cv_unit->sleep(0) })->recv };
no_leaks_ok {
    cv_unit->sleep(.0002)->timeout(.0003);
    cv_unit->sleep(.001)->recv;
};
no_leaks_ok {
    Data::Monad::Base::Sugar::for { pick sub { cv_unit } }->recv;
};
no_leaks_ok {
    Data::Monad::Base::Sugar::for { pick sub { cv_unit }; yield {} }->recv;
};

TODO: {
    local $TODO = "Haven't fixed yet";

    no_leaks_ok {
        Data::Monad::Base::Sugar::for {
            pick \my $x => sub { cv_unit(10 / 2)->sleep(0) };
            let \my $m => sub { cv_unit($x + 1) };
            pick \my $y => sub { $m };
            pick \my $z => sub { cv_unit($x - 1) };
            pick sub { cv_unit($y * $z) };
        }->recv;
    };
}

done_testing;
