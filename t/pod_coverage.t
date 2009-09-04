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

my @bad_modules = qw(
    Stream::Cursor::Integer
    Stream::File::In
    Stream::File::Stream
    Stream::DB::Stream
    Stream::Mixin::Shift
    Stream::DB::Cursor
    Stream::DB::In
    Stream::Log::In
    Stream::Log::Stream
    Stream::File::Cursor
    Stream::Log::Cursor
    Stream::File
);

TODO: {
    local $TODO = 'not all Stream modules are properly documented still';
    for (@bad_modules) {
        pod_coverage_ok($_);
        delete $modules{$_};
    }
}

for (keys %modules) {
    pod_coverage_ok($_);
}

