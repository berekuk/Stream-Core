package Stream::File;

use strict;
use warnings;

use Yandex::Version '{{DEBIAN_VERSION}}';

=head1 NAME

Stream::File - file storage

=head1 SYNOPSIS

    $storage = Stream::File->new($filename);
    $stream = $storage->stream($posfile);

=head1 METHODS

=over

=cut

use Params::Validate;
use Stream::Storage;
use parent qw(Stream::Storage);

use Carp;
use IO::Handle;
use Yandex::X qw(xopen xprint);
use Yandex::Lockf;
use Stream::File::In;

=item B<new($file)>

Create new object. C<$file> should be a name of any writable file into which lines will be appended.

If C<$file> does not yet exist, it will be created.

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

sub _write ($) {
    my ($self) = @_;
    my $current_size = -s $self->{fh};
    $self->{fh}->write($self->{data});
    my $flush_ok = $self->{fh}->flush;
    unless ($flush_ok) {
        if (defined $current_size) {
            $self->{fh}->truncate($current_size); # try to rollback
        }
        die "write to $self->{file} failed";
    }
    delete $self->{data};
}

sub _flush($) {
    my ($self) = @_;
    return unless defined $self->{data};
    $self->_open unless $self->{fh};
    my $lock = lockf($self->{fh});
    $self->_write();
}

=item B<write($line)>

Write new line into file.

=cut
sub write ($$) {
    my ($self, $line) = @_;
    if (defined $self->{data}) {
        $self->{data} .= $line;
    }
    else {
        $self->{data} = $line;
    }
    if (length($self->{data}) > 1_000) {
        $self->_flush;
    }
}

=item B<write_chunk($chunk)>

Write multiple lines into file.

=cut
sub write_chunk ($$) {
    my ($self, $chunk) = @_;
    croak "write_chunk method expects arrayref" unless ref($chunk) eq 'ARRAY'; # can chunks be blessed into something?
    return unless @$chunk;
    for my $line (@$chunk) {
        if (defined $self->{data}) {
            $self->{data} .= $line;
        }
        else {
            $self->{data} = $line;
        }
    }
    if (length($self->{data}) > 1_000) {
        $self->_flush;
    }
    return; # TODO - what useful data can we return?
}

sub commit ($) {
    my ($self) = @_;
    $self->_flush;
}

=item B<file()>

Get filename.

=cut
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

sub class_caps {
    return { persistent => 1 };
}

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;
