package Stream::Log::In;

use strict;
use warnings;

=head1 NAME

Stream::Log::In - input stream for Stream::Log storage.

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
    Stream::Mixin::Filterable
    Stream::In
);

# deprecated, to be removed after culca-ds rebuild
use parent qw( Stream::Mixin::Lag );

use Yandex::Version '{{DEBIAN_VERSION}}';

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
    return bless {unrotate => $unrotate} => $class;
}

# do_read instead of read - Mixin::Filterable requires it
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

# deprecated
sub showlag {
    my ($self) = @_;
    return $self->lag;
}

# deprecated
sub show_lag {
    my ($self) = @_;
    return $self->lag;
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

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;
