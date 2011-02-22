package Stream::Role::Clonable;

use strict;
use warnings;

# ABSTRACT: role for stream objects which implement 'clone'

=head1 METHODS

=over

=cut

use Carp;

=item B<< clone() >>

Clone object.

=cut
sub clone {
    croak 'not implemented';
}

=back

=cut

1;

