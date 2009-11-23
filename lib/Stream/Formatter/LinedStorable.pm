package Stream::Formatter::LinedStorable;

use strict;
use warnings;

=head1 NAME

Stream::Formatter::LinedStorable - storable line-oriented formatter

=cut

use Stream::Utils qw(catalog);

use base qw(Stream::Formatter);

sub read_filter {
    return catalog->filter('line2str') | catalog->filter('thaw');
}

sub write_filter {
    return catalog->filter('freeze') | catalog->filter('str2line');
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

