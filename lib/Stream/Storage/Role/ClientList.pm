package Stream::Storage::Role::ClientList;

use strict;
use warnings;

=head1 NAME

Stream::Storage::Role::ClientList - common storage methods for working with named clients

=head1 SYNOPSIS

    @client_names = $storage->client_names;

    $in = $storage->stream($client_name);

    $storage->register_client($client_name);
    $storage->unregister_client($client_name);

    $storage->has_client($client_name);

=head1 DESRIPTION

Some storages implement ability to generate stream by client's name. This role guarantees that storage implements some common methods for listing and registering storage clients.

=head1 METHODS

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

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

