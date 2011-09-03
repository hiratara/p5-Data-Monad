use inc::Module::Install;
name 'Data-Monad';
all_from 'lib/Data/Monad.pm';

requires 'AnyEvent';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
