package Stream::In::Role::Shift;

use strict;
use warnings;

use parent qw(Stream::In);

=head1 NAME

Stream::In::Role::Shift - role which allows your input stream to be used as PPB::Join-like sequence

=cut

# TODO - deprecate this module? PPB::Join rewritten using streams already...
sub shift {
    return $_[0]->read;
}

1;

