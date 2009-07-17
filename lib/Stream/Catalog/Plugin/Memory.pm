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

=item C<bind($name, $object)>

Bind C<$object> to name C<$name>.

=cut
sub bind {
    my $self = shift;
    my ($name, $object) = validate_pos(@_, { type => SCALAR }, 1);
    unless (blessed $object) {
        croak "Expected blessed object instead of '$object'";
    }

    if ($object->isa('Stream::In')) {
        $self->{bind}{in}{$name} = $object;
    }
    elsif ($object->isa('Stream::Out')) {
        $self->{bind}{out}{$name} = $object;
    }
    elsif ($object->isa('Stream::Cursor')) {
        $self->{bind}{cursor}{$name} = $object;
    }
    else {
        croak "Unknown object '$object'";
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

