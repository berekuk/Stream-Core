package Stream::Base;

use strict;
use warnings;

use MRO::Compat;

# ABSTRACT: base class for In, Out and Filter classes

=head1 DESCRIPTION

This class implement the basis for stream metaprogramming.

Roles are optional features which stream class (or object) is capable of.
Since we want to have many various implementations of streams, it would be impossible to require them all to support all features, so they have to be optional.

Roles are like L<Moose> roles, but streams are not using C<Moose> yet.
To make use of roles even on perl5.8, and make them compatible with future streams moosification, this class implements common C<DOES> method.

C<Stream::In>, C<Stream::Out> and C<Stream::Filter> all inherit C<DOES()> method from this class.

Some utilities, like C<process()> function from L<Stream::Utils>, will make use of these roles and adapt their behavior appropriately.

=head1 METHODS

=over

=item B<DOES($role)>

Check if stream implements given role.

This method is equivalent to C<UNIVERSAL::DOES> in perl5.10. It's better than C<does()> because it's more agnostic to used object system (i.e., it works both with moose-based clases and classic perl classes).

=cut
sub DOES {
    my ($self, $class) = @_;
    return $self->isa($class);
}

=item B<does($role)>

Check if stream implements given role.

DEPRECATED. Use C<DOES> to check interface conformance instead.

=cut
{
    no strict 'refs';
    *does = \&DOES;
}

=back

=cut

1;
