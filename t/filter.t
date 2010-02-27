#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

use lib qw(lib);

use Streams qw(process);
use Stream::Processor qw(processor);
use Stream::Filter qw(filter);

# simple pipeline of filters (2)
{
    my @values;
    my $p = (filter { chomp(my $x = shift); return $x; })
        | (filter { shift() ** 2 })
        | (processor { push @values, shift; });

    $p->write(5);
    is_deeply(\@values, [25], 'f|f|p pipeline, write method');

    $p->write_chunk([6, 7]);
    is_deeply(\@values, [25, 36, 49], 'f|f|p pipeline, write_chunk method');
}

# checking that callback can return several items at once (2)
{
    my @values;
    my $p = (filter { chomp(my $x = shift); return ($x, $x + 1); })
        | (filter { shift() ** 2 })
        | (processor { push @values, shift; });

    $p->write(5);
    is_deeply(\@values, [25, 36], 'f|f|p pipeline, write method, filter implements one-to-many');

    $p->write_chunk([6, 7]);
    is_deeply(\@values, [25, 36, 36, 49, 49, 64], 'f|f|p pipeline, write_chunk method, filter implements one-to-many');
}

# reading from storage written by f|f|f|p (3)
{
    use Stream::File;
    use Stream::File::Cursor;
    use Yandex::X;

    xsystem("rm -rf tfiles");
    xsystem("mkdir tfiles");

    my @values;
    my $p = (filter { chomp(my $x = shift); return $x; })
        | (filter { shift() ** 2 })
        | (filter { shift()."\n" })
        | (Stream::File->new("tfiles/output"));
    $p->write(5);
    $p->write_chunk([6, 7]);
    $p->commit;

    my $reader = Stream::File::Cursor->new("tfiles/output.pos")->stream(Stream::File->new("tfiles/output"));
    is($reader->read, "25\n", 'reading from storage written by f|f|f|p');
    is($reader->read, "36\n", 'reading - step 2');
    is($reader->read, "49\n", 'reading - step 3');
}

# reading from filtered input stream (4)
{
    use Stream::File;
    use Stream::File::Cursor;
    use Yandex::X;
    use Stream::Simple qw(array_seq); # FIXME! Stream::Simple doesn't exist when building core streams

    xsystem("rm -rf tfiles");
    xsystem("mkdir tfiles");

    my @values;
    my $reader = array_seq([5, 6, 7])
        | (filter { my $x = shift or return; chomp $x; return $x; })
        | (filter { shift() ** 2 })
        | (filter { shift()."\n" });

    is($reader->read, "25\n", 'i|f|f|f pipeline, read, step 1');
    is($reader->read, "36\n", 'i|f|f|f pipeline, read, step 2');
    is($reader->read, "49\n", 'i|f|f|f pipeline, read, step 3');
    is($reader->read, undef, 'i|f|f|f pipeline, last read returns undef');
    $reader->commit; # just to make sure that it doesn't fail
}

# filtering Filterable input streams (3)
{
    use Stream::Log::In;
    xsystem("echo abc >>tfiles/log");
    xsystem("echo def >>tfiles/log");

    my $stream = Stream::Log::In->new({
        LogFile => 'tfiles/log',
        PosFile => 'tfiles/pos',
    });
    my $filtered_stream = $stream | filter(sub {
        my $item = shift;
        chomp $item;
        return "$item$item"; # dup
    }) | filter(sub {
        my $item = shift;
        chomp $item;
        return "$item-$item"; # double dup
    });
    is($stream, $filtered_stream, 'Stream::Log::In is Filterable and holds filters inside');
    is($stream->read, 'abcabc-abcabc', 'all filter stack is applied');
    is($stream->lag, 4, 'lag works for filtered input stream');
}

# if filter returns undef, next line should be pulled from input stream
{
    use Stream::Log::In;
    my $i = 0;
    my $reader = array_seq([5..10])
        | (filter { return if $i++ % 2; return shift; });
    is($reader->read, 5, 'first item from stripy stream');
    is($reader->read, 7, 'third item from stripy stream');
}

# raw write() method in scalar context and in list context
{
    my $f = filter { return shift() ** 2 };
    my ($x) = $f->write(5);
    is($x, 25, 'write() in list context');
    my $y = $f->write(5);
    is($y, 25, 'write() in scalar context');
}

# commitable right-side filters
{
    sub make_buffered_filter {
        my $buffer;
        return filter(
            sub { 
                push @$buffer, $_[0] + 1; 
                return () unless @$buffer >= 5;
                return splice (@$buffer, 0, 2);
            }, sub {
                return splice @$buffer;
            }
        );
    }
    my $f1 = make_buffered_filter();
    my $result;
    my $p = processor(sub {
        push @$result, $_[0];
    });

    process(array_seq([1 .. 10]) => $f1 | $p);
    is_deeply($result, [2 .. 11], "buffered filters are flushed");

    $result = [];
    my $f2 = make_buffered_filter();
    process(array_seq([1 .. 10]) => $f1 | ($f2 | $p));
    is_deeply($result, [3 .. 12], "buffered filters compositions are flushed");

    $result = [];
    process(array_seq([1 .. 10]) => ($f1 | $f2) | $p);
    is_deeply($result, [3 .. 12], "buffered filters compositions via FilteredFilter are flushed");
}

# commitable left-side filters
{
    my $f = filter(sub {
        return $_[0];
    }, sub {
        return (0);
    });
    throws_ok(sub { process(array_seq([1 .. 10]) | $f => processor(sub{})) }, qr/cannot/, "flushable filters cannot be attached to input streams");
}
