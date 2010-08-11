package Stream::In::Role::Shift;

use strict;
use warnings;

# TODO - deprecate this module? PPB::Join rewritten using streams already...

use parent qw(Stream::In);

=head1 NAME

Stream::In::Role::Shift - role which allows your input stream to be used as PPB::Join-like sequence

=cut

=head1 METHODS

=over

=item B<< shift() >>

Alias for C<read()> method.

=cut
sub shift {
    return $_[0]->read;
}

1;

