package Stream::Catalog::Storage::File;

use strict;
use warnings;

# obsolete

use base qw(Stream::Catalog::Out::File);

sub storage {
    goto &out;
}

1;

