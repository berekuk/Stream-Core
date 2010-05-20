#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use lib 'lib';

BEGIN {
    $ENV{STREAM_OUT_DIR} = 't/storage.d';
    $ENV{STREAM_CURSOR_DIR} = 't/cursor.d';
}

use Stream::Catalog;
use Stream::File::Cursor;

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

my $catalog = Stream::Catalog->new;

# catalog->storage (1)
{
    my $storage = $catalog->storage('something');
    my $stream = $storage->stream(Stream::File::Cursor->new('tfiles/pos'));
    is($stream->read, "qqq\n", "stream 'something' is readable");
}

# catalog->cursor (1)
{
    my $stream = $catalog->cursor('something.cursor')->stream;
    is($stream->read, "qqq\n", "stream something.cursor is readable too");
    $stream->commit;
}

# catalog->cursor (1)
{
    my $stream = $catalog->in('something.cursor');
    is($stream->read, "www\n", 'in method constructs stream from cursor if neccesary');
}

# catalog->bind_in (3)
{
    dies_ok { $catalog->in('aaa') } "can't get not existing yet stream";
    $catalog->bind_in(aaa => $catalog->in('something.cursor'));
    ok($catalog->in('aaa')->isa('Stream::In'), "now 'something.cursor' is binded as 'aaa' too");

    $catalog->bind_in('something.cursor' => (bless { a => 'b' } => 'Stream::In'));
    is($catalog->in('something.cursor')->{a}, 'b', "bind_in overrides configs");
}

