package Stream::Out;

use strict;
use warnings;

# ABSTRACT: output stream interface

=head1 SYNOPSIS

    use Stream::Out;

    $out->write($item);
    $out->write_chunk(\@items);
    $out->commit;

=head1 DESCRIPTION

C<Stream::Out> defines interface which every writing stream must implement.

=head1 INTERFACE

=over

=cut

use parent qw(Stream::Base);

use Carp;

=item I<new>

Default constructor returns empty blessed hashref. You can redefine it with any parameters you want.

=cut
sub new {
    return bless {} => shift;
}

=item I<write($item)>

C<write> method should be implemented by child class.

It receives one scalar C<$item> as its argument.

At the implementor's option, it can process C<$item> immediately or keep it's value until C<commit()>.

Currently, C<Stream::Out> doesn't coerce C<write()> into C<write_chunk(1)>.
This can be fixed in future (in a safe way, so that non-implementing both C<write> and C<write_chunk> still will be error), or there will be mixin for this task.

Return value is not specified.

=cut
sub write($$) {
    croak "write method not implemented";
}

=item I<write_chunk($chunk)>

C<write_chunk> receives array ref with items ordered as they would be if C<write> method was used instead.

C<write_chunk> method can be provided by a child class if it's convenient or when maximum performance is needed.

Default implementation simply calls C<write> for each element in C<$chunk>.

Return value is unspecified, like in the C<write> method.

=cut
sub write_chunk($$) {
    my ($self, $chunk) = @_;
    confess "write_chunk method expects arrayref, you specified: '$chunk'" unless ref($chunk) eq 'ARRAY'; # can chunks be blessed into something?
    for my $item (@$chunk) {
        $self->write($item);
    }
    return;
}

=item I<commit()>

C<commit> method can flush cached data, print statistics or do anything neccessary to make sure that writing is completed correctly.

Stream's author should make sure that stream is still usable after that.

Default implementation does nothing.

=cut
sub commit {
}

=back

=head1 HELPER FUNCTIONS

This package also exports (deprecated) helper function C<processor>.

=over


=back

=head1 SEE ALSO

L<Stream::Storage> - skeleton of a persistent storage into which all data gets written.

=cut

1;

