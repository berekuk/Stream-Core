package Stream::Catalog::Storage::File;

use strict;
use warnings;

use Yandex::X;

our $CATALOG_DIR = $ENV{STORAGE_CATALOG_DIR} || '/etc/storage.d';

sub new {
    return bless {} => shift;
}

sub storage {
    my ($self, $name) = @_;
    if (-e "$CATALOG_DIR/$name") {
        my $fh = xopen("$CATALOG_DIR/$name");
        my $content;
        { local $/; $content = <$fh>; }
        $content = "package AnonStorage".int(rand(10 ** 6)).";\n# line 1 $CATALOG_DIR/$name\n$content";
        my $storage = eval $content;
        if ($@) {
            die "Failed to eval '$content': $@";
        }
        return $storage;
    }
}

1;

