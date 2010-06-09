package Stream::Catalog::Plugin::Memory;

use strict;
use warnings;

=head1 NAME

Stream::Catalog::Plugin::Memory - catalog plugin which binds objects by names into catalog

=head1 METHODS

=over

=cut

use Scalar::Util qw(blessed);
use Carp;
use Yandex::X;
use Params::Validate qw(:all);

use parent qw(Stream::Catalog::Plugin);

=item C<new($params)>

Constructs plugin.

Parameters:

=over

=item I<package>

Every binded package will be verified to belong to this class.

=back

=cut
sub new {
    my $class = shift;
    return bless { bind => {} } => $class;
}

=item C<bind_in($name, $in)>

Bind input stream C<$in> to name C<$name>.

=cut
sub bind_in {
    my $self = shift;
    my ($name, $in) = validate_pos(@_, { type => SCALAR }, 1);

    if ($in->isa('Stream::In')) {
        $self->{bind}{in}{$name} = $in;
    }
    else {
        croak "Unknown param '$in'";
    }
}

=item C<in($name)>

Load input stream binded earlier to name C<$name>.

=cut
sub in {
    my ($self, $name) = @_;
    return $self->{bind}{in}{$name};
}

=item C<out($name)>

Load output stream binded earlier to name C<$name>.

=cut
sub out {
    my ($self, $name) = @_;
    return $self->{bind}{out}{$name};
}

=item C<cursor($name)>

Load cursor binded earlier to name C<$name>.

=cut
sub cursor {
    my ($self, $name) = @_;
    return $self->{bind}{cursor}{$name};
}
1;

