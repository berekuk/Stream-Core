#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 'lib';
use File::Find;

my @modules;
find(sub {
    if (/\.pm$/) {
        push @modules, $File::Find::name;
    }
}, 'lib');

plan tests => scalar @modules;

for (@modules) {
    s{^lib/}{};
    s{/}{::}g;
    s{\.pm$}{};
    use_ok($_);
}

