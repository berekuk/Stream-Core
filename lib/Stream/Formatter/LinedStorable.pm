package Stream::Formatter::LinedStorable;

use strict;
use warnings;

# ABSTRACT: storable line-oriented formatter

use Stream::Utils qw(catalog);

use parent qw(Stream::Formatter);

sub read_filter {
    return catalog->filter('line2str') | catalog->filter('thaw');
}

sub write_filter {
    return catalog->filter('freeze') | catalog->filter('str2line');
}

1;
