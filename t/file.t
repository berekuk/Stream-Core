#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use parent qw(Test::Class);

use lib 'lib';

use Yandex::X;

use Stream::File;
use Stream::File::Cursor;

use Time::HiRes qw(sleep);

sub setup :Test(setup) {
    xsystem("rm -rf tfiles");
    xsystem("mkdir tfiles");
    xsystem("cp t/storage/file tfiles/file");
}

sub _storage {
    my $self = shift;
    return Stream::File->new("tfiles/file");
}
sub _stream {
    my $self = shift;
    my $storage = $self->_storage;
    return $storage->stream(Stream::File::Cursor->new("tfiles/pos"));
}

sub commit :Test(3) {
    my $self = shift;
    my $stream = $self->_stream;
    is($stream->read, "123456789\n");
    is($stream->read, "asdf\n");
    $stream->commit;
    $stream = $self->_stream;
    is($stream->read, "zxcv\n");
    $stream->commit;
}

sub not_commit :Test(3) {
    my $self = shift;
    my $stream = $self->_stream;
    $stream->read;
    $stream = $self->_stream;
    is($stream->read, "123456789\n");
    $stream->commit;

    $stream = $self->_stream;
    is($stream->read, "asdf\n");
    $stream = $self->_stream;
    is($stream->read, "asdf\n");
}

sub read_until_the_end :Test(3) {
    my $self = shift;
    my $stream = $self->_stream;
    $stream->read for 1..3;
    is($stream->read, "qwer\n");
    is($stream->read, undef);
    $stream->commit;

    $stream = $self->_stream;
    is($stream->read, undef);
}

sub writing :Test(3) {
    my $self = shift;

    my $storage = Stream::File->new('tfiles/storage');
    $storage->write("xxx\n");
    $storage->write("yyy\n");
    $storage->write_chunk(["zzz1\n", "zzz2\n"]);
    $storage->commit;

    my $stream = $storage->stream(Stream::File::Cursor->new("tfiles/storage.pos"));
    is($stream->read, "xxx\n");
    is_deeply(scalar($stream->read_chunk(2)), ["yyy\n", "zzz1\n"]);
    is($stream->read, "zzz2\n");
}

sub commit_empty :Test(2) {
    my $out = Stream::File->new("tfiles/out");
    lives_ok(sub { $out->commit() }, "commit of an empty file");
    ok(! -e "tfiles/out", "empty commit does not create a file");
}

sub atomic($$) {
    my ($self, $line) = @_;

    my $file = 'tfiles/atomic';
    my $storage = Stream::File->new($file);
    for (1..100) {
        if (my $child = fork) {
            1 while -z $file;
            sleep rand() / 100;
            kill 9 => $child;
            waitpid $child, 0;
        }
        else {
            while (1) {
                $storage->write($line);
            }
        }
    }
    my $in = $storage->stream(Stream::File::Cursor->new("$file.pos"));
    while (my $in_line = $in->read) {
        $in_line eq $line or die "invalid line in $file";
    }
}

sub atomic_small :Test(1) {
    my $self = shift;
    $self->atomic(join ',', 'a'..'z', "\n");
    pass;
}

sub atomic_large :Test(1) {
    my $self = shift;
    $self->atomic(join ',', 'aaa'..'zzz', "\n");
    pass;
}

sub commit_after_incomplete_line :Tests(4) {
    my $self = shift;
    my $fh = xopen('>', 'tfiles/file');
    print {$fh} "abc\n";
    print {$fh} "def";
    $fh->flush;
    my $gen_in = sub { Stream::File->new('tfiles/file')->stream(Stream::File::Cursor->new('tfiles/pos')) };

    {
        my $in = $gen_in->();
        is($in->read, "abc\n", 'first line');
        is($in->read, undef, 'incomplete line ignored');
        $in->commit;
    }

    {
        my $in = $gen_in->();
        is($in->read, undef, 'incomplete line still ignored');
        $in->commit;
    }

    print {$fh} "g\n";
    $fh->flush;

    {
        my $in = $gen_in->();
        is($in->read, "defg\n", "complete line");
    }
}

sub lag :Test(5) {
    my $self = shift;
    my $out = Stream::File->new('tfiles/file');
    my $in = $out->stream(Stream::File::Cursor->new('tfiles/pos'));
    ok($in->does('Stream::In::Role::Lag'), "role");

    is($in->lag(), 25, "simple lag");
    $in->read;
    is($in->lag(), 15, "uncommited lag");
    $in->commit;
    is($in->lag(), 15, "commited lag");
    $in = $out->stream(Stream::File::Cursor->new('tfiles/pos'));
    $out->write("blah\n");
    $out->commit;
    is($in->lag(), 20, "realtime lag");
}

sub truncate : Test(8) {
    my $self = shift;
    my $tests = [
        ["", ""],
        ["a" x 7, ""],
        ["a" x 2000, ""],
        ["\n", "\n"],
        ["aaa\n", "aaa\n"],
        ["aaa\nbbb", "aaa\n"],
        ["aaa\nbbb\nccc", "aaa\nbbb\n"],
        ["a\nc\n" . ("b" x 3000), "a\nc\n"],
    ];
    foreach my $test (@$tests) {
        my ($given, $expected) = @$test;

        xsystem("rm -f tfiles/truncate_*");
        my $out = Stream::File->new('tfiles/truncate_file', {safe => 1, reopen => 1});
        $out->write($given);
        $out->commit;

        $out->write("a\n");
        $out->commit;

        my $content;
        my $in = $out->stream(Stream::File::Cursor->new('tfiles/trunkate_file.pos'));
        while (my $l = $in->read) {
            $content .= $l;
        }
        is($content, $expected . "a\n");
    }
}

$ENV{TEST_METHOD} = 'truncate';

__PACKAGE__->new->runtests;
