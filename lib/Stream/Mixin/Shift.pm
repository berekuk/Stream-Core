package Stream::Mixin::Shift;

use strict;
use warnings;

=head1 NAME

Stream::Mixin::Shift - mixin which allows your input stream to be used as PPB::Join-like sequence

=cut

# TODO - deprecate this module? PPB::Join rewritten using streams already...
sub shift {
    return $_[0]->read;
}

1;

