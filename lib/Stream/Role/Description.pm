package Stream::Role::Description;

use strict;
use warnings;

# ABSTRACT: role for stream objects which implement 'description'

=head1 METHODS

=over

=cut

use Carp;

=item B<< description() >>

String with object's description.

Should not end with "\n" but can contain "\n" in the middle of the string.

=cut
sub description {
    croak 'not implemented';
}

=back

=cut

1;
