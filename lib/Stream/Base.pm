package Stream::Base;

use strict;
use warnings;

use MRO::Compat;

=head1 NAME

Stream::Base - base class for In, Out and Filter classes

=head1 DESCRIPTION

This class implement the basis for stream metaprogramming.

Roles are optional features which stream class (or object) is capable of.
Since we want to have many various implementations of streams, it would be impossible to require them all to support all features, so they have to be optional.

Roles are like L<Moose> roles, but streams are not using C<Moose> yet.
To make use of roles even on perl5.8, and make them compatible with future streams moosification, this class implements common C<does> method.

C<Stream::In>, C<Stream::Out> and C<Stream::Filter> all inherit C<does()> method from this class.

Some utilities, like C<process()> function from L<Stream::Utils>, will make use of these roles and adapt their behavior appropriately.

=head1 METHODS

=over

=item B<does($role)>

Check if stream implements given role.

This method is equivalent to C<UNIVERSAL::isa>, or C<UNIVERSAL::DOES> in perl5.10. It'll be replaced with implementation from L<Moose::Object> once streams will actually be based on L<Moose>.

=cut
sub does($$) {
    my ($self, $class) = @_;
    return $self->isa($class);
}

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

