package Stream::Processor;

use strict;
use warnings;

=head1 NAME

Stream::Processor - deprecated module for backward-compatibility

=head1 DESCRIPTION

This module was renamed into Stream::Out and will be removed soon.

=cut

use Exporter;
use Stream::Out;

our @EXPORT_OK = qw(processor);
our @ISA = qw(Exporter Stream::Out);

sub processor(&) {
    goto &Stream::Out::processor;
}

1;

