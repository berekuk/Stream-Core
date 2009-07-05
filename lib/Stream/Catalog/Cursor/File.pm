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

our $CATALOG_DIR =
    $ENV{CURSOR_CATALOG_DIR} # deprecated
    || $ENV{STREAM_CURSOR_DIR}
    || '/etc/stream/cursor';

=item C<new>

Constructs plugin.

=cut
sub new {
    return bless {} => shift;
}

=item C<cursor($name)>

Loads cursor from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/cursor>.

=cut
sub cursor {
    my ($self, $name) = @_;
    if (-e "$CATALOG_DIR/$name") {
        my $fh = xopen("$CATALOG_DIR/$name");
        my $content;
        { local $/; $content = <$fh>; }
        $content = "package AnonCursor".int(rand(10 ** 6)).";\n# line 1 $CATALOG_DIR/$name\n$content";
        my $cursor = eval $content;
        if ($@) {
            die "Failed to eval '$content': $@";
        }
        return $cursor;
    }
}

1;

