package Stream::Catalog::Out::File;

use strict;
use warnings;

use Yandex::X;

our $CATALOG_DIR =
    $ENV{STORAGE_CATALOG_DIR} # deprecated, should be removed soon
    || $ENV{STREAM_OUT_DIR}
    || '/etc/stream/out';

sub new {
    return bless {} => shift;
}

sub out {
    my ($self, $name) = @_;
    if (-e "$CATALOG_DIR/$name") {
        my $fh = xopen("$CATALOG_DIR/$name");
        my $content;
        { local $/; $content = <$fh>; }
        $content = "package AnonOut".int(rand(10 ** 6)).";\n# line 1 $CATALOG_DIR/$name\n$content";
        my $out = eval $content;
        if ($@) {
            die "Failed to eval '$content': $@";
        }
        return $out;
    }
}

1;

