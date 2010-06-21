#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

use lib 'lib';

BEGIN {
    $ENV{STREAM_PATH} = 't/catalog';
}

use Stream::Catalog;
use Stream::File::Cursor;

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

my $catalog = Stream::Catalog->new;

# catalog->storage (3)
{
    my $storage = $catalog->storage('something');
    my $stream = $storage->stream(Stream::File::Cursor->new('tfiles/pos'));
    is($stream->read, "qqq\n", "stream 'something' is readable");

    my $storage2 = $catalog->storage('something');
    is(ref $storage, 'Stream::Catalog::Out::something', 'catalog object package');
    is(ref $storage2, 'Stream::Catalog::Out2::something', 'different ->storage calls construct new packages');
}

# lazy definitions (4)
{
    my $lazy_storage = $catalog->storage('lazy_something');
    ok($lazy_storage->isa('Stream::File'), 'anonimous subs in catalog files work too');
    my $lazy_storage2 = $catalog->storage('lazy_something');

    is(ref $lazy_storage, 'Stream::Catalog::Out::lazy_something', 'catalog object package when definition is lazy');
    is(ref $lazy_storage2, 'Stream::Catalog::Out::lazy_something', 'lazy definitions are loaded only once');
    isnt($lazy_storage, $lazy_storage2, 'lazy sub is cached, not object itself');
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

