#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use lib 'lib';

BEGIN {
    $ENV{STORAGE_CATALOG_DIR} = 't/storage.d';
    $ENV{CURSOR_CATALOG_DIR} = 't/cursor.d';
}

use Stream::Catalog;
use Stream::File::Cursor;

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

my $catalog = new Stream::Catalog;

# catalog->storage
{
    my $storage = $catalog->storage('something');
    my $stream = $storage->stream(new Stream::File::Cursor('tfiles/pos'));
    is($stream->read, "qqq\n");
}

# catalog->cursor
{
    my $stream = $catalog->cursor('something.cursor')->stream;
    is($stream->read, "qqq\n");
    $stream->commit;
    $stream = $catalog->cursor('something.cursor')->stream;
    is($stream->read, "www\n");
}

