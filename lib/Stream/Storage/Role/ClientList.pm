package Stream::Storage::Role::ClientList;

use strict;
use warnings;

# ABSTRACT: common storage methods for working with named clients

=head1 SYNOPSIS

    @client_names = $storage->client_names;

    $in = $storage->stream($client_name);

    $storage->register_client($client_name);
    $storage->unregister_client($client_name);

    $storage->has_client($client_name);

=head1 DESRIPTION

Some storages implement ability to generate stream by client's name. This role guarantees that storage implements some common methods for listing and registering storage clients.

=head1 METHODS

=over

=item B<< client_names() >>

Get all storage client names as plain list.

=cut
sub client_names($);

=item B<< register_client($name) >>

Register new client in storage.

Default implementation does nothing.

=cut
sub register_client($$) {
}

=item B<< unregister_client($name) >>

Unregister client from storage.

Default implementation does nothing.

=cut
sub unregister_client($$) {
}

=item B<< has_client($name) >>

Check whether storage has client with given name.

Default implementation uses C<client_names()>, but override it if you want to do this check faster.

=cut
sub has_client($$) {
    my $self = shift;
    my $name = shift;
    return grep { $_ eq $name } $self->client_names;
}

=item B<< inefficiency >>

Returns the lag value for this storage (the sum of lags of all clients).

=cut
sub inefficiency {
    my $self = shift;

    my $lag = 0;
    $lag += $self->in($_)->lag() for ($self->client_names);

    return $lag;
}

=back

=cut

1;
