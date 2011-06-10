package Streams;

use strict;
use warnings;

# exports by default:
# process($stream, $processor, $limit)
# processor($callback)
# stream($name)

# ABSTRACT: module for importing all common stream functions.

=head1 SYNOPSIS

use Streams;

process($stream => processor { print "item: ", shift });

=head1 DESCRIPTION

L<Stream> framework is a next abstraction layer above L<Yandex::Unrotate>, L<PPB::Join> and some other PPB coding practices.

This module is just a simple way to load most important subs from other Stream::* modules. Check out L<Stream> to learn more.

=cut

use Stream::Utils qw(process catalog processor);
use Stream::Out;
use Stream::Filter qw(filter);

use parent qw(Exporter);
our @EXPORT = qw(process processor catalog filter);

=head1 SEE ALSO

L<Stream> - first doc to learn about streams.

L<Stream::Utils> - various stream functions.

L<Stream::In> - input stream interface.

L<Stream::Out> - output stream interface.

L<Stream::Filter> - filter that can be attached to other streams.

=cut

1;
