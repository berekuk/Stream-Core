package Stream::Formatter;

use strict;
use warnings;

=head1 NAME

Stream::Formatter - interface for both-way formatter of any storage.

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

use Yandex::Version '{{DEBIAN_VERSION}}';

use Carp;
use Params::Validate qw(:all);

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

package Stream::Formatter::Wrapped;

use warnings;
use strict;

use parent qw(Stream::Storage);
use Params::Validate;

sub new {
    my $class = shift;
    my ($formatter, $storage) = validate_pos(@_, { isa => 'Stream::Formatter' }, { isa => 'Stream::Storage' });
    return bless {
        formatter => $formatter,
        storage => $storage,
        write_filter => $formatter->write_filter,
        read_filter => $formatter->read_filter,
    } => $class;
}

sub write {
    my ($self, $item) = @_;
    my @filtered = $self->{write_filter}->write($item);
    return unless @filtered;
    $self->{storage}->write($_) for @filtered;
}

sub write_chunk {
    my ($self, $chunk) = @_;
    $self->{storage}->write_chunk($self->{write_filter}->write_chunk($chunk));
}

sub stream {
    my $self = shift;
    my $input_stream = $self->{storage}->stream(@_);
    return ($input_stream | $self->{read_filter});
}

sub stream_by_name {
    my $self = shift;
    my $input_stream = $self->{storage}->stream_by_name(@_);
    return ($input_stream | $self->{read_filter});
}

sub commit {
    my $self = shift;
    $self->{storage}->commit;
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

