#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use lib 'lib';

BEGIN {
    $ENV{YANDEX_SANDBOX_DB} = 'stream';
}

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

use Yandex::DB;
use Stream::DB;
use Stream::DB::Cursor;

my $db = connectdb('stream');
$db->do(q{
    CREATE TABLE Links (
        id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
        link VARCHAR(255) NOT NULL,
        weight DOUBLE NOT NULL
    )
});

my $storage = Stream::DB->new({
    db => 'stream',
    fields => [qw/link weight/],
    table => 'Links',
});

# write
{
    $storage->write({link => 'http://tema.livejournal.com', weight => 0.5});
    $storage->write({link => 'http://avva.livejournal.com', weight => 1});
    $storage->write({link => 'http://drugoi.livejournal.com', weight => 0.1});
    $storage->commit;

    is(join(',', $db->selectrow_array(q{SELECT link, weight FROM Links WHERE id = 2})), 'http://avva.livejournal.com,1');
}

# stream, read
{
    my $stream = $storage->stream(Stream::DB::Cursor->new('tfiles/pos'));
    is_deeply($stream->read, {link => 'http://tema.livejournal.com', weight => 0.5});
    $stream->commit;
    $stream = $storage->stream(Stream::DB::Cursor->new('tfiles/pos'));
    is_deeply($stream->read, {link => 'http://avva.livejournal.com', weight => 1});
    $stream = $storage->stream(Stream::DB::Cursor->new('tfiles/pos'));
    is_deeply($stream->read, {link => 'http://avva.livejournal.com', weight => 1});
    is_deeply($stream->read, {link => 'http://drugoi.livejournal.com', weight => 0.1});
    is($stream->read, undef);
}

