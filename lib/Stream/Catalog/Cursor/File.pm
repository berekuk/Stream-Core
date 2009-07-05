package Stream::Catalog::Cursor::File;

use strict;
use warnings;

use Yandex::X;

our $CATALOG_DIR = $ENV{CURSOR_CATALOG_DIR} || '/etc/cursor.d';

sub new {
    return bless {} => shift;
}

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

