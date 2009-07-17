package Stream::Catalog::Out::File;

use strict;
use warnings;

=head1 NAME

Stream::Catalog::Out::File - catalog plugin which loads output streams from files

=head1 SYNOPSIS

    use Stream::Catalog::Out::File;
    $plugin = Stream::Catalog::Out::File->new;
    $out = $plugin->out("bulca_ds");

=head1 METHODS

=over

=cut

use Yandex::X;
use base qw(Stream::Catalog::File);

our $CATALOG_DIR =
    $ENV{STORAGE_CATALOG_DIR} # deprecated, should be removed soon
    || $ENV{STREAM_OUT_DIR}
    || '/etc/stream/out';

=item C<new>

Constructs plugin.

=cut
sub new {
    my $class = shift;
    return $class->SUPER::new({
        path => $CATALOG_DIR,
        package => 'AnonOut',
    });
}

=item C<out($name)>

Loads output stream from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/out>.

=cut
sub out {
    my ($self, $name) = @_;
    return $self->load($name);
}

=back

=cut

1;

