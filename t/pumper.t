#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 'lib';

use Stream::Pumper::Common;
use Stream::Filter qw(filter);

{
    package t::In;
    use parent qw(Stream::In);
    my @in = ('a'..'d');
    sub read {
        return shift @in;
    }
}

{
    package t::Out;
    use parent qw(Stream::Out);
    my @out;
    sub write {
        push @out, $_[1];
    }

    sub data {
        return \@out;
    }
}

my $out = t::Out->new;
my $pumper = Stream::Pumper::Common->new({
    in => t::In->new,
    out => $out,
    filter => filter(sub { shift() x 2 }),
});

$pumper->pump({ limit => 2 });
is_deeply($out->data, ["aa", "bb"]);
$pumper->pump();
is_deeply($out->data, ["aa", "bb", "cc", "dd"]);

