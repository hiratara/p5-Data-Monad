use inc::Module::Install;
name 'Data-Monad';
all_from 'lib/Data/Monad.pm';
readme_from 'lib/Data/Monad.pm';

requires 'AnyEvent';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Requires';
auto_set_repository;
auto_include;

resources
    homepage => 'https://github.com/hiratara/p5-Data-Monad',
    bugtracker => 'https://github.com/hiratara/p5-Data-Monad/issues';

WriteAll;
