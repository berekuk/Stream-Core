#!/usr/bin/perl

use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;
use Test::Exception;

use lib 'lib';

use Yandex::X;

use Stream::Log;
use Stream::Log::Cursor;

sub setup :Test(setup) {
    xsystem("rm -rf tfiles");
    xsystem("mkdir tfiles");
}


sub reading :Test(4) {
    xsystem("echo aaa >>tfiles/log");
    xsystem("echo bbb >>tfiles/log");
    xsystem("echo ccc >>tfiles/log");

    my $storage = Stream::Log->new("tfiles/log");

    my $stream = $storage->stream(Stream::Log::Cursor->new({PosFile => "tfiles/pos"}));
    is($stream->read, "aaa\n");
    $stream->commit;

    xsystem("mv tfiles/log tfiles/log.1");
    xsystem("echo ddd >>tfiles/log");
    xsystem("echo eee >>tfiles/log");
    xsystem("echo fff >>tfiles/log");

    $stream = Stream::Log::Cursor->new({PosFile => "tfiles/pos"})->stream({LogFile => "tfiles/log"});
    is($stream->read, "bbb\n");
    is($stream->read, "ccc\n");
    is($stream->read, "ddd\n");
    $stream->commit;
}


sub reading_without_commit :Test(2) {
    xsystem("echo eee >>tfiles/log");
    xsystem("echo fff >>tfiles/log");

    my $storage = Stream::Log->new("tfiles/log");
    my $stream = $storage->stream(Stream::Log::Cursor->new({PosFile => "tfiles/pos"}));
    is($stream->read, "eee\n");
    $stream = $storage->stream(Stream::Log::Cursor->new({PosFile => "tfiles/pos"}));
    is($stream->read, "eee\n");
}


sub commit :Test(2) {
    my $out = Stream::Log->new("tfiles/out");
    lives_ok(sub { $out->commit() }, "commit of an empty log");
    ok(! -e "tfiles/out", "empty commit does not create a log");
}


sub stream_by_name :Test(7) {
    xsystem("echo ".($_ x 3)." >>tfiles/log") for 'd'..'g';

    $ENV{STREAM_LOG_POSDIR} = 'tfiles';
    my $storage = Stream::Log->new("tfiles/log");

    my $first = $storage->stream_by_name('first');
    is($first->read, "ddd\n");
    is($first->read, "eee\n");
    $first->commit;
    my $second = $storage->stream_by_name('second');
    is($second->read, "ddd\n");
    $second->commit;
    $first = $storage->stream_by_name('first');
    is($first->read, "fff\n");
    $first->commit;
    is($first->read, "ggg\n");
    $first = $storage->stream_by_name('first');
    is($first->read, "ggg\n");
    $first = $storage->stream('first');
    is($first->read, "ggg\n");
}


sub clients :Test(3) {
    xsystem("echo ".($_ x 3)." >>tfiles/log") for 'd'..'g';

    $ENV{STREAM_LOG_POSDIR} = 'tfiles';
    my $storage = Stream::Log->new("tfiles/log");

    is_deeply([ $storage->client_names ], [], 'initially there are no clients');

    my $in = $storage->stream_by_name('xxx');
    undef $in;
    is_deeply([ $storage->client_names ], [], "uncommited input stream don't create posfile and so don't register itself in storage");

    $in = $storage->stream_by_name('xxx');
    $in->commit;
    $in = $storage->stream_by_name('yyy');
    $in->read;
    $in->commit;
    is_deeply([ $storage->client_names ], ['xxx', 'yyy'], "client_names returns all clients");
}
__PACKAGE__->new->runtests;


__END__
1) create stream

Stream::Log::In->new({
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

