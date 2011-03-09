#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

eval "use Test::Pod::Coverage; 1" or plan skip_all => "Test::Pod::Coverage required for testing POD coverage";

my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };

my @modules = all_modules();

plan tests => scalar @modules;
my %modules = map { ($_ => 1) } @modules;

my @bad_modules = qw(
    Stream::DB::Cursor
    Stream::Log::In
    Stream::File::Cursor
    Stream::Log::Cursor
    Stream::Filter::FilteredIn
    Stream::Formatter::Wrapped
);

TODO: {
    local $TODO = 'not all Stream modules are properly documented still';
    for (@bad_modules) {
        pod_coverage_ok($_, $trustparents);
        delete $modules{$_} or die $_;
    }
}

for (keys %modules) {
    pod_coverage_ok($_, $trustparents);
}

