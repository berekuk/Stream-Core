package Stream::In;

use strict;
use warnings;

# ABSTRACT: input stream interface

=head1 SYNOPSIS

    $line = $stream->read;
    $chunk = $stream->read_chunk($limit);
    $stream->commit;

=head1 DESCRIPTION

C<Stream::In> defines interface which every reading stream must implement.

=head1 INTERFACE

=over

=cut

use parent qw(Stream::Base);

use Carp;

=item I<new>

Default constructor creates empty blessed hashref.

=cut
sub new {
    my $class = shift;
    croak 'no parameters expected' if @_;
    return bless {} => $class;
}

=item I<read()>

C<read> method should be implemented by child class.

It must return any defined scalar when there's something left in stream, and undef when stream is over.

Currently, C<Stream::In> doesn't coerce C<read()> into C<read_chunk(1)>. This can be fixed in future (in a safe way, so that non-implementing both C<read> and C<read_chunk> still will be error), or there will be mixin for this task.

=cut
sub read($) {
    croak 'read not implemented';
}

=item I<read_chunk($limit)>

C<read_chunk> receives integer limit as an only argument and should return array ref with single scalars, ordered as if C<read()> was invoked several times, or undef if there is no data left in the stream.

C<read_chunk> method can be provided by a child class if it's convenient or when maximum performance is needed.

Default implementation simply calls C<read()> I<$limit> times.

=cut
sub read_chunk($$) {
    my ($self, $limit) = @_;
    my @chunk;
    while (defined($_ = $self->read)) {
        push @chunk, $_;
        last if @chunk >= $limit;
    }
    return unless @chunk; # return false if nothing can be read
    return \@chunk;
}

=item I<commit()>

C<commit> method can commit position, print statistics or do anything neccessary to make sure that reading is completed correctly.

Stream's author should make sure that stream is still readable after that.

Default implementation does nothing.

=cut
sub commit {
}

=back

=cut

1;

