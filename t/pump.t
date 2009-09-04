#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use lib 'lib';

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");
{
    my $fh = xopen('>', 'tfiles/storage');
    for (1..10) {
        xprint($fh, "line$_\n");
    }
    xclose($fh);
}

use Stream::Utils qw(pump);
use Stream::Out qw(processor);
use Stream::File;
use Stream::File::Cursor;

# pump storage into two targets
{
    my @data1;
    my @data2;
    my $i = 1;

    pump(Stream::File->new('tfiles/storage'), [
        processor(sub { $_ = shift; chomp; push @data1, $_ }),
        processor(sub { $_ = shift; chomp; push @data2, "second: $_" }),
    ], {
        cursor_sub => sub { Stream::File::Cursor->new("tfiles/".$i++.".pos") },
        limit => 2,
    });

    is_deeply(\@data1, ["line1", "line2"], 'first output stream filled');
    is_deeply(\@data2, ["second: line1", "second: line2"], 'second output stream filled');
}

# now one of targets will fail
{
    my @data1;
    my @data2;
    my $i = 1;

    pump(Stream::File->new('tfiles/storage'), [
        processor(sub { die "temporary outage" }),
        processor(sub { $_ = shift; chomp; push @data2, "second: $_" }),
    ], {
        cursor_sub => sub { Stream::File::Cursor->new("tfiles/".$i++.".pos") },
        limit => 2,
    });

    is_deeply(\@data1, [], 'first output stream is temporary broken');
    is_deeply(\@data2, ["second: line3", "second: line4"], 'second output stream filled anyway');
}

# now we can check that both streams have independent cursors
{
    my @data1;
    my @data2;
    my $i = 1;

    pump(Stream::File->new('tfiles/storage'), [
        processor(sub { $_ = shift; chomp; push @data1, $_ }),
        processor(sub { $_ = shift; chomp; push @data2, "second: $_" }),
    ], {
        cursor_sub => sub { Stream::File::Cursor->new("tfiles/".$i++.".pos") },
        limit => 2,
    });

    is_deeply(\@data1, ["line3", "line4"], 'first stream works from where it stopped last time');
    is_deeply(\@data2, ["second: line5", "second: line6"], 'second output stream continues to move forward');
}


