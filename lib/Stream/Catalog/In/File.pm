package Stream::Catalog::In::File;

use strict;
use warnings;

use Yandex::X;
use base qw(Stream::Catalog::File);

our $CATALOG_DIR =
    $ENV{STREAM_IN_DIR}
    || '/etc/stream/in';

sub new {
    my $class = shift;
    return $class->SUPER::new({
        path => $CATALOG_DIR,
        package => 'AnonIn',
    });
}

sub in {
    my ($self, $name) = @_;
    return $self->load($name);
}

1;

