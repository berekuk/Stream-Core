package Stream::Formatter;

use strict;
use warnings;

# ABSTRACT: interface for both-way formatter of any storage.

=head1 SYNOPSIS

    $formatted_storage = $formatter->wrap($storage);
    $formatted_storage->write({ a => "b" });
    $reader =$formatted_storage->stream_by_name("client1");
    $data = $reader->read();

=head1 DESCRIPTION

There's a common need to store complex data into storage which can only store strings.
Simple C<Stream::Filter> is not enough, because storage should both serialize and deserialize data in the same way. So C<Stream::Formatter> provides interface for objects which can decorate C<Stream::Storage> objects into storages which can both write data through serializing filter and create reading streams which deserialize that data correctly.

Usual way to create new formatters is to inherit from this class and implement C<read_filter> and C<write_filter> methods.

=head1 METHODS

=over

=cut

use Carp;
use Params::Validate qw(:all);

use Stream::Formatter::Wrapped;

=item I<new>

Default constructor returns empty blessed hashref. You can redefine it with any parameters you want.

=cut
sub new {
    return bless {} => shift;
}

=item B<< write_filter() >>

This method should return filter which will be applied to any item written into wrapped storage.

Filter is expected to be of C<Stream::Filter> class and to transform data in 1-to-1 fashion.

=cut
sub write_filter {
    croak 'write_filter not implemented';
}

=item B<< read_filter() >>

This method should return filter which will be applied to any item read from input stream derived from wrapped storage.

Filter is expected to be of C<Stream::Filter> class and to transform data in 1-to-1 fashion.

=cut
sub read_filter {
    croak 'read_filter not implemented';
}

=item B<< wrap($storage) >>

Construct formatted storage from given storage. Returns formatted storage.

Resulting object will transform all writes using C<write_filter> and generate input streams which are filtered by C<read_filter>.

Default implementation of this method should be good in most cases, you don't have to reimplement it in child classes.

=cut
sub wrap {
    my $self = shift;
    my ($storage) = validate_pos(@_, { isa => 'Stream::Storage' });
    my $wrapped_storage = Stream::Formatter::Wrapped->new($self, $storage);
    return $wrapped_storage;
}

=back

=cut

1;
