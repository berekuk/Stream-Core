#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use lib 'lib';

use Yandex::X;

use Stream::Log;
use Stream::Log::Cursor;

xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

xsystem("echo aaa >>tfiles/log");
xsystem("echo bbb >>tfiles/log");
xsystem("echo ccc >>tfiles/log");


my $storage = Stream::Log->new("tfiles/log");

# first reading iteration (1)
{
    my $stream = $storage->stream(Stream::Log::Cursor->new({PosFile => "tfiles/pos"}));
    is($stream->read, "aaa\n");
    $stream->commit;
}

xsystem("mv tfiles/log tfiles/log.1");
xsystem("echo ddd >>tfiles/log");
xsystem("echo eee >>tfiles/log");
xsystem("echo fff >>tfiles/log");

# second reading iteration (3)
{
    my $stream = Stream::Log::Cursor->new({PosFile => "tfiles/pos"})->stream({LogFile => "tfiles/log"});
    is($stream->read, "bbb\n");
    is($stream->read, "ccc\n");
    is($stream->read, "ddd\n");
    $stream->commit;
}

# reading without commit (2)
{
    my $stream = $storage->stream(Stream::Log::Cursor->new({PosFile => "tfiles/pos"}));
    is($stream->read, "eee\n");
    $stream = $storage->stream(Stream::Log::Cursor->new({PosFile => "tfiles/pos"}));
    is($stream->read, "eee\n");
}


__END__
1) create stream

Stream::Log::Stream->new({
    LogFile => "/var/log/file",
    PosFile => "/var/log/file.pos",
});
# + one call
# + unrotate options
# - named log
# - named pos

2) create stream from storage
Stream::Log->new("/var/log/file")->stream(Stream::Log::Cursor->new("/var/log/file.pos"));
# or:
storage("file")->stream(Stream::Log::Cursor->new("/var/log/file.pos"));
# or:
storage("file")->stream(cursor("file.pos"))
# or:
stream("file.pos")

(in catalog:
# storage.d/file:
Stream::Log->new("/var/log/file");
# cursor.d/file.pos:
Stream::Log::Cursor->new("/var/log/file.pos");

# + can be really short
# + catalog names
# - no unrotate options
# - many different files
# - not so easy for unrotate users

