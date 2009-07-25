#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use lib 'lib';

BEGIN {
    $ENV{STREAM_OUT_DIR} = 't/storage.d';
    $ENV{STREAM_CURSOR_DIR} = 't/cursor.d';
}

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

use Stream::Utils qw(process catalog);
use Stream::Out qw(processor);

my @data;
my $catcher = processor(sub { push @data, shift });

process(
    catalog->in('something.cursor') => $catcher
);
is_deeply(\@data, ["qqq\n", "www\n", "eee\n"], 'process processes all data when limit is not specified');

@data = ();
process(
    catalog->in('something.cursor') => $catcher
);
is_deeply(\@data, [], 'process probably commits position');
# there can be other reasons why process breaks on second invocation; but we'll double check later

xsystem("rm tfiles/something.pos");

@data = ();
process(
    catalog->in('something.cursor') => $catcher, 2
);
is_deeply(\@data, ["qqq\n", "www\n"], 'process respects limit');

@data = ();
process(
    catalog->in('something.cursor') => $catcher
);
is_deeply(\@data, ["eee\n"], 'process really commits position');

xsystem("rm tfiles/something.pos");

@data = ();
process(
    'something.cursor' => $catcher, 2
);
is_deeply(\@data, ["qqq\n", "www\n"], 'process searches for input stream by name');

# TODO - check searching of output stream by name too
