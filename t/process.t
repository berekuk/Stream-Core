#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;

use lib 'lib';

BEGIN {
    $ENV{STREAM_OUT_DIR} = 't/storage.d';
    $ENV{STREAM_CURSOR_DIR} = 't/cursor.d';
}

use Yandex::X;
xsystem("rm -rf tfiles");
xsystem("mkdir tfiles");

use Stream::Utils qw(process catalog);
use Stream::Out qw(processor);
use Stream::Simple qw(array_seq); # FIXME - this is a dependence on stream-more

my @data;
my $catcher = processor(sub { push @data, shift });

process(
    catalog->in('something.cursor') => $catcher
);
is_deeply(\@data, ["qqq\n", "www\n", "eee\n"], 'process processes all data when limit is not specified');

@data = ();
process(
    catalog->in('something.cursor') => $catcher
);
is_deeply(\@data, [], 'process probably commits position');
# there can be other reasons why process breaks on second invocation; but we'll double check later

xsystem("rm tfiles/something.pos");

@data = ();
process(
    catalog->in('something.cursor') => $catcher, 2
);
is_deeply(\@data, ["qqq\n", "www\n"], 'process respects limit');

@data = ();
process(
    catalog->in('something.cursor') => $catcher
);
is_deeply(\@data, ["eee\n"], 'process really commits position');

xsystem("rm tfiles/something.pos");

@data = ();
process(
    'something.cursor' => $catcher, 2
);
is_deeply(\@data, ["qqq\n", "www\n"], 'process searches for input stream by name');
# TODO - check searching of output stream by name too

@data = ();
process(
    array_seq([qw/ qqq www eee /]) => $catcher, { limit => 2 }
);
is_deeply(\@data, [qw/ qqq www /], 'process understands verbose options');

# return value
{
    @data = ();
    my $processed;
    $processed = process(
        array_seq([('a'..'z') x 10]) => $catcher, { limit => 250 }
    );
    is($processed, 250, 'process() return value');

    @data = ();
    $processed = process(
        array_seq([('a'..'z') x 10]) => $catcher
    );
    is($processed, 260, 'process() return value without limit specified');
}

# commit_step
{
    {
        package t::CommitCounter;
        use base qw(Stream::Out);
        sub write_chunk {
            my ($self, $chunk) = @_;
            $self->{processed} += @$chunk;
        }
        sub commit {
            my $self = shift;
            push @{$self->{commit_points}}, $self->{processed} || 0;
        }
    }
    my $commit_counter = t::CommitCounter->new;
    process(
        array_seq([('a'..'z') x 10]) => $commit_counter
    );
    is_deeply($commit_counter->{commit_points}, [ 260 ], 'by default, process() commits only in the end');

    $commit_counter = t::CommitCounter->new;
    process(
        array_seq([('a'..'z') x 10]) => $commit_counter, { commit_step => 100 }
    );
    is_deeply($commit_counter->{commit_points}, [ 100, 200, 260 ], 'commit_step works');

    $commit_counter = t::CommitCounter->new;
    process(
        array_seq([('a'..'z') x 10]) => $commit_counter, { commit_step => 50 }
    );
    is_deeply($commit_counter->{commit_points}, [ 100, 200, 260, 260 ], "commit_step still don't force smaller chunks"); # i don't see a quick way to fix this double commit in the end, sorry
}

# chunk_size
{
    {
        package t::ChunkCatcher;
        use base qw(Stream::Out);
        sub write_chunk {
            push @{$_[0]->{chunks}}, $_[1];
        }
    }

    {
        my $chunk_catcher = t::ChunkCatcher->new;
        process(
            array_seq([map { "a$_" } (1..950)]) => $chunk_catcher
        );
        my $chunks = $chunk_catcher->{chunks};
        my @expected;
        for my $i (0..8) {
            push @expected, [map { "a$_" } (($i * 100 + 1)..($i * 100 + 100))];
        }
        push @expected, [map { "a$_" } (901..950)];
        is_deeply($chunks, \@expected, 'process uses chunk_size=100 by default and correctly processes last chunk');
    }

    {
        my $chunk_catcher = t::ChunkCatcher->new;
        process(
            array_seq([map { "a$_" } (1..950)]) => $chunk_catcher, { chunk_size => 200 }
        );
        my $chunks = $chunk_catcher->{chunks};
        my @expected;
        for my $i (0..3) {
            push @expected, [map { "a$_" } (($i * 200 + 1)..($i * 200 + 200))];
        }
        push @expected, [map { "a$_" } (801..950)];
        is_deeply($chunks, \@expected, 'chunk_size option works');
    }
}

