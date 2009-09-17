#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

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


