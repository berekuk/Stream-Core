#!/usr/bin/perl

use strict;
use warnings;

use PPB::Test::TFiles;

use lib 'lib';

use Stream::File;
use Benchmark;

my $out = Stream::File->new('tfiles/out');

my $line = ('data' x 20) . "\n";
timethis(1_000_000, sub {
    $out->write($line);
});
$out->commit;

