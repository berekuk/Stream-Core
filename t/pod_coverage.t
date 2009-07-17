#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

my @modules = all_modules();
plan tests => scalar @modules;
my %modules = map { ($_ => 1) } @modules;

my @good_modules = qw(
    Streams
    Stream::Log
    Stream::In
    Stream::Out
    Stream::Stream
    Stream::Processor
    Stream::Storage
    Stream::Catalog::Plugin
    Stream::Catalog::Plugin::File
    Stream::Catalog::Plugin::Memory
);

for (@good_modules) {
    pod_coverage_ok($_);
    delete $modules{$_};
}

TODO: {
    local $TODO = 'not all Stream modules are properly documented still';
    for (keys %modules) {
        pod_coverage_ok($_);
    }
}

