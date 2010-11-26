package Stream::In::Role::ShiftAsList;

use strict;
use warnings;

=head1 NAME

Stream::In::Role::ShiftAsList - role for classes which want 'shift' method to return lists.

=cut

=head1 METHODS

=over

=item B<< shift() >>

Call C<read()> and dereference its result as array.

=cut
sub shift {
    my $item = $_[0]->read;
    return unless $item;
    return @$item;
}

1;
