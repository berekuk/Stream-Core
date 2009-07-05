package Stream::Storage;

use strict;
use warnings;

=head1 NAME

Stream::Storage - interface to any storage.

=head1 SYNOPSIS

    $storage->write($line);
    $storage->write_chunk(\@lines);

    $stream = $storage->stream($cursor);

=cut

use Carp;

use Stream::Processor;
use base qw(Stream::Processor); # TODO - should we introduce common base class Stream::Writer?

sub new {
    return bless {} => shift;
}

sub write ($$) {
    my ($self, $line) = @_;
    die "write not implemented";
}

sub write_chunk ($$) {
    my ($self, $chunk) = @_;
    croak "write_chunk method expects arrayref" unless ref($chunk) eq 'ARRAY'; # can chunks be blessed into something?
    # TODO - lock?
    for my $line (@$chunk) {
        $self->write($line);
    }
    return; # TODO - what useful data can we return?
}

sub commit($) {
    my ($self) = @_;
    return; # do nothing by default; should commit all buffered data from previous writes
}

# TODO - is it useful in base class at all?
sub stream {
    my ($self, $cursor) = @_;
    die "stream construction not implemented";
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

