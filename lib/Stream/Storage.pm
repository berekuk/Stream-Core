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

=item C<in(...)>

Constructs input stream for this storage.

Most storages are able to have several different input streams with different positions in storage.

C<in> method usually accepts either clients name (as plain string), or more complicated cursor object.

=cut
sub in {
    my ($self, $client) = @_;
    die "input stream construction not implemented";
}

=item C<stream(...)>

Old deprecated name for C<in(...)> method. Some storage implementations still use it, though, and don't implement C<in>.

This method redirects its calls to C<in(...)> by default, so don't implement it in new storages, please!

=cut
sub stream {
    my $self = shift;
    $self->in(@_);
}

=back

=cut

1;
