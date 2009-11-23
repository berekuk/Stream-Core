package Stream::Formatter::LinedStorable;

use strict;
use warnings;

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

