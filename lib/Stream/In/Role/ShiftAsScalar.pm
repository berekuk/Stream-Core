package Stream::In::Role::ShiftAsScalar;

use strict;
use warnings;

use parent qw(Stream::In);

# ABSTRACT: role for classes which want 'shift' method to be aliased to 'read'

=head1 METHODS

=over

=item B<< shift() >>

Alias for C<read()> method.

=cut
sub shift {
    return $_[0]->read;
}

=back

=cut

1;

