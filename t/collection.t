#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use lib 'lib';

BEGIN {
    $ENV{STREAM_PATH} = 'stream';
}

use Yandex::X qw(xsystem);
use Perl6::Slurp;
use Streams;

xsystem('rm -rf tfiles');
xsystem('mkdir tfiles');

xsystem(q! (echo "aaa"; echo "bbb") | perl -Ilib -MStreams -e 'process("stdin" => filter(sub { shift() x 2 }) | catalog->out("stdout"))' >tfiles/result!);

is(slurp('tfiles/result'), "aaa\naaa\nbbb\nbbb\n", 'stdin and stdout streams');

xsystem(q! (echo 'a\naa'; echo 'b\\\\\nbb') | perl -Ilib -MStreams -e 'process(catalog->in("stdin") | catalog->filter("line2str") | filter(sub {return shift, "\n"}) => "stdout")' >tfiles/result!);

is(slurp('tfiles/result'), "a\naa\nb\\\nbb\n", 'line2str filter unquotes new lines and double backslashes');

xsystem(q! (echo "aaa"; echo "bbb") | perl -Ilib -MStreams -e 'process("stdin" => filter(sub { return { item => shift } }) | catalog->filter("freeze") | catalog->filter("str2line") | catalog->out("stdout"))' >tfiles/result!);

like(slurp('tfiles/result'), qr/12345678/, 'freezed stream looks like storable');

xsystem(q! cat tfiles/result | perl -Ilib -MStreams -e 'process(catalog->in("stdin") | catalog->filter("line2str") | catalog->filter("thaw") | filter(sub { my $item = shift; return $item->{item} }) => catalog->out("stdout"))' >tfiles/result2!);
is(slurp('tfiles/result2'), "aaa\nbbb\n", 'thaw works');

ok(catalog->format('storable')->isa('Stream::Formatter::LinedStorable'), 'LinedStorable formatter in catalog');
