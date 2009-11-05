#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use lib 'lib';

use Yandex::X;

use Stream::File;
use Stream::File::Cursor;

xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

xsystem("cp t/storage/file tfiles/file");

my $storage = Stream::File->new("tfiles/file");

# first reading iteration
{
    my $stream = $storage->stream(Stream::File::Cursor->new("tfiles/pos"));
    is($stream->read, "123456789\n");
    is($stream->read, "asdf\n");
    is($stream->read, "zxcv\n");
    $stream->commit;
}

# reading without commit
{
    my $stream = $storage->stream(Stream::File::Cursor->new("tfiles/pos"));
    is($stream->read, "qwer\n");
    $stream = $storage->stream(Stream::File::Cursor->new("tfiles/pos"));
    is($stream->read, "qwer\n");
}

# another reading iteration
{
    my $stream = $storage->stream(Stream::File::Cursor->new("tfiles/pos"));
    is($stream->read, "qwer\n");
    is($stream->read, undef);
    $stream->commit;
}

# writing
{
    $storage->write("xxx\n");
    $storage->write("yyy\n");
    $storage->write_chunk(["zzz1\n", "zzz2\n"]);
    $storage->commit;
    my $stream = $storage->stream(Stream::File::Cursor->new("tfiles/pos"));
    is($stream->read, "xxx\n");
    is_deeply(scalar($stream->read_chunk(2)), ["yyy\n", "zzz1\n"]);
    is($stream->read, "zzz2\n");
}

