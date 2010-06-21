#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use lib 'lib';
BEGIN {
    $ENV{STREAM_PATH} = 'etc/stream';
}

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

use Stream::File::Cursor;
use Stream::Formatter::LinedStorable;
use Stream::File;
use Streams;
my $storage = Stream::File->new("./tfiles/file");
my $wrapper = Stream::Formatter::LinedStorable->new;
my $formatted_storage = $wrapper->wrap($storage);
$formatted_storage->write({ abc => "def" });
$formatted_storage->write({ "1\n2\n" => "3\n4\n" });
$formatted_storage->write("ghi");
$formatted_storage->commit;

my $in = $formatted_storage->stream(Stream::File::Cursor->new("./tfiles/pos"));
is_deeply(scalar($in->read), { abc => 'def' }, 'data deserialized correctly');
is_deeply(scalar($in->read), { "1\n2\n" => "3\n4\n" }, 'data with \n');
is_deeply(scalar($in->read), 'ghi', 'simple strings can be stored too');
$in->commit;
$in = $formatted_storage->stream(Stream::File::Cursor->new("./tfiles/pos"));
is($in->read, undef, 'commit worked, nothing to read');

