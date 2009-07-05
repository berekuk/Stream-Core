package Stream::File;

use strict;
use warnings;

=head1 NAME

Stream::File - file storage

=head1 SYNOPSIS

    $storage = Stream::File->new($filename);
    $stream = $storage->stream($posfile);

=head1 METHODS

=cut

use Params::Validate;
use Stream::Storage;
use base qw(Stream::Storage);

use Carp;
use IO::Handle;
use Yandex::X qw(xopen xprint);
use Stream::File::In;

=item B<new($file)>

Create new object. C<$file> should be a name of any existing file which we're going to read by one line at a time.

=cut
sub new($$) {
    my $class = shift;
    my ($file) = validate_pos(@_, 1);

    return bless {file => $file} => $class;
}

sub _open($) {
    my ($self) = @_;
    $self->{fh} = xopen(">>", $self->{file});
}

=item B<write($line)>

Write new line into file.

=cut
sub write ($$) {
    my ($self, $line) = @_;
    $self->_open unless $self->{fh};
    xprint($self->{fh}, $line);
}

=item B<write($chunk)>

Write multiple lines into file.

=cut
sub write_chunk ($$) {
    my ($self, $chunk) = @_;
    croak "write_chunk method expects arrayref" unless ref($chunk) eq 'ARRAY'; # can chunks be blessed into something?
    $self->_open unless $self->{fh};
    # TODO - lock?
    for my $line (@$chunk) {
        xprint($self->{fh}, $line);
    }
    return; # TODO - what useful data can we return?
}

sub commit ($) {
    my ($self) = @_;
    if ($self->{fh}) {
        $self->{fh}->flush;
    }
}

sub file {
    my ($self) = @_;
    return $self->{file};
}

=item B<stream($cursor)>

Construct stream object from an L<Stream::File::Cursor> object.

=cut
sub stream($$) {
    my $self = shift;
    my ($cursor) = validate_pos(@_, {isa => 'Stream::File::Cursor'});

    return $cursor->stream($self);
}

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;
