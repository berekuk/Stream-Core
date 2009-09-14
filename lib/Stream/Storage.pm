package Stream::Storage;

use strict;
use warnings;

use Yandex::Version '{{DEBIAN_VERSION}}';

=head1 NAME

Stream::Storage - interface to any storage.

=head1 SYNOPSIS

    $storage->write($line);
    $storage->write_chunk(\@lines);

    $stream = $storage->stream($cursor);

=head1 DESCRIPTION

Stream::Storage is an object which can act as a writing stream, and which can generate associated reading stream with C<stream> method.

=head1 METHODS

=over

=cut

use base qw(Stream::Out);

=item C<stream(...)>

C<stream> method usually accepts associated cursor, but implementations may vary...

=cut
sub stream {
    my ($self, $cursor) = @_;
    die "stream construction not implemented";
}

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

