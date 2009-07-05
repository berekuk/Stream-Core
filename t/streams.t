#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use lib 'lib';

BEGIN {
    $ENV{STORAGE_CATALOG_DIR} = 't/storage.d';
    $ENV{CURSOR_CATALOG_DIR} = 't/cursor.d';
}

use Streams;

is(stream('something.cursor')->read, "qqq\n");

# TODO - check other exported functions from Streams

