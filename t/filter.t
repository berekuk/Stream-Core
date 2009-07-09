#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use lib qw(lib);

use Stream::Processor qw(processor);
use Stream::Filter qw(filter);

# simple pipeline of filters
{
    my @values;
    my $p = (filter { chomp(my $x = shift); return $x; })
        | (filter { shift() ** 2 })
        | (processor { push @values, shift; });

    $p->write(5);
    is_deeply(\@values, [25]);

    $p->write_chunk([6, 7]);
    is_deeply(\@values, [25, 36, 49]);
}

# checking that callback can return several items at once
{
    my @values;
    my $p = (filter { chomp(my $x = shift); return ($x, $x + 1); })
        | (filter { shift() ** 2 })
        | (processor { push @values, shift; });

    $p->write(5);
    is_deeply(\@values, [25, 36]);

    $p->write_chunk([6, 7]);
    is_deeply(\@values, [25, 36, 36, 49, 49, 64]);
}

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
    is($reader->read, "25\n");
    is($reader->read, "36\n");
    is($reader->read, "49\n");
}

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

    is($reader->read, "25\n");
    is($reader->read, "36\n");
    is($reader->read, "49\n");
    is($reader->read, undef);
    $reader->commit; # just to make sure that it doesn't fail
}
