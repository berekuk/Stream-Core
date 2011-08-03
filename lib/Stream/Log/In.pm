package Stream::Log::In;

use strict;
use warnings;

# ABSTRACT: input stream for Stream::Log storage.

=head1 SYNOPSIS

    $in = $log_storage->stream($cursor); # see Stream::Log and Stream::Log::Cursor for details

    $line = $in->read; # read next line from log

    $lag = $in->lag; # get log lag in bytes

    $in->commit; # commit current position
    # or:
    $position = $in->position; # remember position
    ... # read more lines
    $in->commit($position); # commit saved position to cursor, ignoring all other lines

=head1 METHODS

=over

=cut

use parent qw(
    Stream::Role::Clonable
    Stream::In::Role::Filterable
    Stream::In::Role::Lag
    Stream::In
);

use Params::Validate qw(:all);
use Carp;

use Yandex::Unrotate;

sub new {
    my $class = shift;

    my $params = validate_with(
        params => \@_,
        spec => {
            PosFile => {type => SCALAR},
            LogFile => {type => SCALAR, optional => 1},
        },
        allow_extra => 1,
    );

    my $unrotate = Yandex::Unrotate->new($params);
    return bless {
        unrotate => $unrotate,
        params => $params,
    } => $class;
}

sub clone {
    my $self = shift;
    return __PACKAGE__->new($self->{params});
}

# do_read instead of read - Filterable role requires it
sub do_read ($) {
    my ($self) = @_;
    return $self->{unrotate}->readline;
}

=item C<< position() >>

Get current position.

You can commit this stream later using this position instead of position at the moment of commit.

=cut
sub position($) {
    my ($self) = @_;
    return $self->{unrotate}->position;
}

=item C<< lag() >>

Get log lag in bytes.

=cut
sub lag {
    my ($self) = @_;
    return $self->{unrotate}->lag;
}

=item C<< commit() >>

=item C<< commit($position) >>

Commit position in stream's cursor.

=cut
sub commit ($;$) {
    my ($self, $position) = @_;
    $self->SUPER::commit();
    $self->{unrotate}->commit($position ? $position : ());
}

=back

=head1 SEE ALSO

L<Stream::Log> - output stream for writing logs.

L<Stream::In> - base class for all input streams.

L<Yandex::Unrotate> - module for reading rotated logs.

=cut

1;
