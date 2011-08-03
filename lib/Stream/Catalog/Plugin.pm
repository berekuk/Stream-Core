package Stream::Catalog::Plugin;

use strict;
use warnings;

# ABSTRACT: base class for any catalog's plugin

=head1 METHODS

Each catalog plugin can implement any number of following methods:

=over

=item B<new>

Constructs new plguin.

You shouldn't call this method directly, but it can be helpful in writing really short plugins (although i don't actually think it'll be that useful... but i still need this POD to pass pod_coverage.t :) )

=cut
sub new {
    my $class = shift;
    return bless {} => $class;
}

=item B<in($name)>

Get input stream by name.

Should return C<Stream::In> object or undef.

=cut
sub in {
    return;
}

=item B<out($name)>

Get output stream by name.

Should return C<Stream::Out> object or undef.

=cut
sub out {
    return;
}

=item B<filter($name)>

Get filter by name.

Should return C<Stream::Filter> object or undef.

=cut
sub filter {
    return;
}

=item B<cursor($name)>

Get cursor by name.

Should return C<Stream::Cursor> object or undef.

=cut
sub cursor {
    return;
}

=item B<pumper($name)>

Get pumper by name.

Should return C<Stream::Pumper> object or undef.

=cut
sub pumper {
    return;
}

=item B<format($name)>

Get format by name.

Should return C<Stream::Formatter> object or undef.

=cut
sub format {
    return;
}

=item B<list($type)>

List all objects of one type.

Returns list with names.

=cut
sub list {
    return ();
}

=back

=head1 SEE ALSO

L<Stream::Catalog> - main catalog class. Most stream users shouldn't be aware about catalog plugins and use it instead.

=cut

1;
