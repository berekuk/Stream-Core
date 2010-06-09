use 5.008008;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Stream',
    PREREQ_PM         => {},
    AUTHOR         => 'Vyacheslav Matjukhin <mmcleric@yandex-team.ru>',
    clean => { FILES => 'tfiles' },
);

