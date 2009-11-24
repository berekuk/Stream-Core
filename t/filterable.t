#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use lib 'lib';

use Stream::Log::In;
use Stream::Filter qw(filter);

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

xsystem("echo line1 >>tfiles/log");
xsystem("echo line2 >>tfiles/log");
xsystem("echo line3 >>tfiles/log");
xsystem("echo line4 >>tfiles/log");

{
    my $in = Stream::Log::In->new({ LogFile => 'tfiles/log', PosFile => 'tfiles/pos' });
    my $filter = filter(sub {
        my $line = shift;
        my ($n) = $line =~ /(\d+)$/;
        if ($n == 1) {
            return;
        }
        if ($n == 3) {
            return undef;
        }
        return $line;
    });

    $in = $in | $filter;

    is($in->read, "line2\n", 'undefs from filter skipped');
    is($in->read, "line4\n", 'second undef from filter skipped');
    is($in->read, undef, 'stream depleted');
}

# two filters
{
    my $in = Stream::Log::In->new({ LogFile => 'tfiles/log', PosFile => 'tfiles/pos' });
    my $f1 = filter(sub {
        my $line = shift;
        chomp $line;
        my ($id) = $line =~ /(\d+)$/;
        return $id * 2;
    });
    my $f2 = filter(sub {
        return shift() * 3;
    });
    $in = $in | $f1 | $f2;
    is($in->read, 6, 'both filters applied');
    is($in->read, 12, 'second read with two filters');
}

# two filters glued together
{
    my $in = Stream::Log::In->new({ LogFile => 'tfiles/log', PosFile => 'tfiles/pos' });
    my $f1 = filter(sub {
        my $line = shift;
        chomp $line;
        my ($id) = $line =~ /(\d+)$/;
        return $id * 2;
    });
    my $f2 = filter(sub {
        return shift() * 3;
    });
    $in = $in | ($f1 | $f2);
    is($in->read, 6, 'complex filter applied');
    is($in->read, 12, 'second read with complex filter');
}

