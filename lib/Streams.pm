package Streams;

use strict;
use warnings;

# exports by default:
# process($stream, $processor, $limit)
# processor($callback)
# stream($name)

=head1 NAME

Streams - module for importing all common stream functions.

=head1 SYNOPSIS

use Streams;

process($stream => processor { print "item: ", shift });

=head1 DESCRIPTION

L<Stream> framework is a next abstraction layer above L<Yandex::Unrotate>, L<PPB::Join> and some other PPB coding practices.

This module is just a simple way to load most important subs from other Stream::* modules. Check out L<Stream> to learn more.

=cut

use Yandex::Version '{{DEBIAN_VERSION}}';

use Stream::Utils qw(process catalog);
use Stream::Out qw(processor);
use Stream::Filter qw(filter);

use parent qw(Exporter);
our @EXPORT = qw(process storage cursor stream processor filter catalog);

=head1 SEE ALSO

L<Stream> - first doc to learn about streams.

L<Stream::Utils> - various stream functions.

L<Stream::In> - interface which every every stream must implement.

L<Stream::Out> - output stream interface and constructor for anonimous processor.

L<Stream::Filter> - filter that can be attached to other streams.

L<process.pl> - script which processes any specified stream.

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

