package Stream::Catalog::Utils;

use strict;
use warnings;

# ABSTRACT: general utils for Stream::Catalog module

=head1 METHODS

=over

=cut

use parent qw(Exporter);
our @EXPORT_OK = 'types';

=item B<< types() >>

List of all types of objects which can be stored in catalog.

=cut
sub types {
    return qw/
        in out cursor filter pumper format
    /;
}

=back

=cut

1;
