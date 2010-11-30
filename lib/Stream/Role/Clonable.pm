package Stream::Role::Clonable;

use strict;
use warnings;

=head1 NAME

Stream::Role::Clonable - role for stream objects which implement 'clone'

=cut

use Carp;

sub clone {
    croak 'not implemented';
}

1;

