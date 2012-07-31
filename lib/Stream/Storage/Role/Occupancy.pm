package Stream::Storage::Role::Occupancy;

use strict;
use warnings;

# ABSTRACT: common storage method for occupancy retrieving

=head1 SYNOPSIS

    $storage->occupancy();

=head1 DESRIPTION

Some storages implement ability to calculate their occupancy.

=head1 METHODS

=over

=item B<< occupancy >>

Returns occupancy value.

=cut
sub occupancy;

=back

=cut

1;
