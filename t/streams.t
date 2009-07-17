#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use lib 'lib';

BEGIN {
    $ENV{STREAM_OUT_DIR} = 't/storage.d';
    $ENV{STREAM_CURSOR_DIR} = 't/cursor.d';
}

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

use Streams;

is(stream('something.cursor')->read, "qqq\n", 'streams export stream function');

# TODO - check other exported functions from Streams

