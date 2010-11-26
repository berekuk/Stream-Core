package Stream::In::Role::ShiftAsScalar;

use strict;
use warnings;

use parent qw(Stream::In);

=head1 NAME

Stream::In::Role::ShiftAsScalar - role for classes which want 'shift' method to be aliased to 'read'

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

