#!/usr/bin/perl
# Copyright (c) 2009 Yandex.ru

use strict;
use warnings;

=head1 NAME

process.pl - process any stream with any processor

=head1 SYNOPSIS

process.pl --file=/var/log/something.log --pos=/var/log/something.pos --module=Some::Module --limit=100

=cut

use Getopt::Long;
use Pod::Usage;

my $file;
my $pos;
my $module;
my $limit;

GetOptions(
    'f|file=s'    => \$file,
    'pos=s'    => \$pos,
    'module=s' => \$module,
    'limit=i' => \$limit,
) or pod2usage(2);
pod2usage(2) unless $file and $pos and $module;

use Stream::Unrotate;
use Streams;

eval "require $module";
if ($@) {
    die "Failed to load ${module}: $@";
}

my $processor = $module->new;

my $stream = Stream::Unrotate->new({
    LogFile => $file,
    PosFile => $pos,
});

process($stream => $processor, $limit);

