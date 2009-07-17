package Stream::Catalog::Cursor::File;

use strict;
use warnings;

=head1 NAME

Stream::Catalog::Cursor::File - catalog plugin which loads cursors from files

=head1 SYNOPSIS

    use Stream::Catalog::Cursor::File;
    $plugin = Stream::Catalog::Cursor::File->new;
    $cursor = $plugin->cursor("process_tinylinks");

=head1 METHODS

=over

=cut

use Yandex::X;
use base qw(Stream::Catalog::File);

our $CATALOG_DIR =
    $ENV{CURSOR_CATALOG_DIR} # deprecated
    || $ENV{STREAM_CURSOR_DIR}
    || '/etc/stream/cursor';

=item C<new>

Constructs plugin.

=cut
sub new {
    my $class = shift;
    return $class->SUPER::new({
        path => $CATALOG_DIR,
        package => 'AnonCursor',
    });
}

=item C<cursor($name)>

Loads cursor from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/cursor>.

=cut
sub cursor {
    my ($self, $name) = @_;
    return $self->load($name);
}

1;

