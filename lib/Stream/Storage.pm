package Stream::Storage;

use strict;
use warnings;

# ABSTRACT: interface to any storage.

=head1 SYNOPSIS

    $storage->write($line);
    $storage->write_chunk(\@lines);

    $stream = $storage->stream($cursor);

=head1 DESCRIPTION

Stream::Storage is an object which can act as a writing stream, and which can generate associated reading stream with C<stream> method.

=head1 METHODS

=over

=cut

use parent qw(Stream::Out);

=item C<stream(...)>

Constructs input stream for this storage.

Most storages are able to have several different input streams with different positions in storage.

C<stream> method usually accepts either associated cursor or clients name as plain string.

=cut
sub stream {
    my ($self, $cursor) = @_;
    die "stream construction not implemented";
}

=back

=cut

1;
