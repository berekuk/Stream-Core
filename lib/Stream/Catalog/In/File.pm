package Stream::Catalog::In::File;

use strict;
use warnings;

use Yandex::X;

our $CATALOG_DIR =
    $ENV{STREAM_IN_DIR}
    || '/etc/stream/in';

sub new {
    return bless {} => shift;
}

sub in {
    my ($self, $name) = @_;
    if (-e "$CATALOG_DIR/$name") {
        my $fh = xopen("$CATALOG_DIR/$name");
        my $content;
        { local $/; $content = <$fh>; }
        $content = "package AnonIn".int(rand(10 ** 6)).";\n# line 1 $CATALOG_DIR/$name\n$content";
        my $stream = eval $content;
        if ($@) {
            die "Failed to eval '$content': $@";
        }
        return $stream;
    }
}

1;

