package Streams;

use strict;
use warnings;

# exports by default:
# process($stream, $processor, $limit)
# processor($callback)
# stream($name)

=head1 NAME

Streams - stream-processing framework

=head1 SYNOPSIS

use Streams;

process($stream => processor { print "item: ", shift });

=head1 DESCRIPTION

C<Streams> is a next abstraction layer above L<Yandex::Unrotate>, L<PPB::Join> and some other PPB coding practices.

This module is just a simple way to load most important subs from other Stream::* modules.

=cut

use Yandex::Version '{{DEBIAN_VERSION}}';

use Stream::Utils qw(process storage cursor stream);
use Stream::Out qw(processor);
use Stream::Filter qw(filter);

use base qw(Exporter);
our @EXPORT = qw(process storage cursor stream processor filter catalog);

=head1 SEE ALSO

L<Stream::In> - interface which every every stream must implement.

L<Stream::Out> - output stream interface and constructor for anonimous processor.

L<Stream::Filter> - specific output stream which generates another stream

L<process.pl> - script which processes any specified stream.

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

