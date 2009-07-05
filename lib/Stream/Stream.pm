package Stream::Stream;

use strict;
use warnings;

=head1 NAME

Stream::Stream - deprecated module for backward-compatibility

=head1 DESCRIPTION

This module was renamed into Stream::In and will be removed soon.

=cut

use base qw(Stream::In);

use Yandex::Version '{{DEBIAN_VERSION}}';

1;

