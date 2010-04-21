#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

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
my $in = $storage->stream(Stream::Log::Cursor->new({ PosFile => 'tfiles/pos' }));
ok($in->cap('lag'), "Stream::Log::In is capable of 'lag' method");
ok(not($in->cap('bug')), "Stream::Log::In is not capable of 'bug' method");
is_deeply($in->caps(), { lag => 1 }, "caps() method");

# TODO - test that caps() method merges results of all class_caps() correctly

