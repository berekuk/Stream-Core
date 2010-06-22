#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use lib 'lib';

use Stream::Pumper::Common;
use Stream::Filter qw(filter);

{
    package t::In;
    use parent qw(Stream::In);
    our @in = ('a'..'d');
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
is_deeply($out->data, [ qw/ aa bb / ]);
$pumper->pump();
is_deeply($out->data, [ qw/ aa bb cc dd / ]);

use Stream::Utils qw(catalog);

{
    catalog->bind_in('my.in' => t::In->new);
    catalog->bind_out('my.out' => t::Out->new);

    push @t::In::in, ('a1'..'a5');
    my $pumper = Stream::Pumper::Common->new({
        in => 'my.in',
        out => 'my.out',
    });
    $pumper->pump();
    is_deeply($out->data, [ qw/ aa bb cc dd a1 a2 a3 a4 a5 / ]);
}

