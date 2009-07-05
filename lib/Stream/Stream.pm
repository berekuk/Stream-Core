package Stream::Stream;

use strict;
use warnings;

=head1 NAME

Stream::Stream - stream interface

=head1 SYNOPSIS

    $line = $stream->read;
    $chunk = $stream->read_chunk($limit);
    $stream->commit;

=head1 DESCRIPTION

C<Stream::Stream> defines interface which every stream must implement.

=cut

use Yandex::Version '{{DEBIAN_VERSION}}';

use Carp;

sub read($) {
    croak 'read not implemented';
}

sub read_chunk($$) {
    my ($self, $limit) = @_;
    my @chunk;
    while (defined($_ = $self->read)) {
        push @chunk, $_;
        last if @chunk >= $limit;
    }
    return unless @chunk; # return false if nothing can be read
    return \@chunk;
}

sub commit {} # do nothing by default

1;

