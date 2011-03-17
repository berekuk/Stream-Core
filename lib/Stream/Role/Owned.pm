package Stream::Role::Owned;

use strict;
use warnings;

# ABSTRACT: role for stream objects which belong to specific user

=head1 METHODS

=over

=cut

use Carp;

=item B<< owner() >>

Get object owner's login string.

=cut
sub owner {
    croak 'not implemented';
}

=back

=cut

1;
