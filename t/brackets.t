#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use lib 'lib';

BEGIN {
    $ENV{STREAM_PATH} = 't/catalog';
}

diag('testing aaa[bbb] syntax');

use Stream::Catalog;
my $catalog = Stream::Catalog->new;
$catalog->bind_in('aaa[bbb]', bless([5] => 'Stream::In'));
is_deeply($catalog->in('aaa[bbb]'), [5], 'bind is checked for bracket syntax');

my $in = $catalog->in('custom[aaa]');
is_deeply($in, ["aaa-in"], 'bracket syntax works - got input stream from storage "custom"');

dies_ok(sub {
    $catalog->in('custom[ccc]')
}, "exception from storage method propagated to 'in' caller");

$catalog->bind_in('custom[aaa]', bless([6] => 'Stream::In'));
is_deeply($catalog->in('custom[aaa]'), [6], 'bind has higher priority than bracket syntax');

