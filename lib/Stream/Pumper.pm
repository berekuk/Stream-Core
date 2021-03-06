package Stream::Pumper;

use strict;
use warnings;

use Carp;

# ABSTRACT: pumper interface

=head1 SYNOPSIS

    $pumper->pump({ limit => 100 });

=head1 INTERFACE

=over

=item B<new>

Default constructor creates empty blessed hashref.

=cut
sub new {
    my $class = shift;
    return bless {} => $class;
}

=item B<pump($options)>

Process data.

Usually pumpers have input stream and output stream, and C<pump> method processes some items from input stream into output stream.

Options:

=over

=item I<limit>

Process only I<limit> items.

=cut

=back

Returns number of processed items.

=cut
sub pump {
    croak 'pump not implemented';
}

=back

=cut

1;
