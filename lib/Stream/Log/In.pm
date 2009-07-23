package Stream::Log::In;

use strict;
use warnings;

=head1 NAME

Stream::Log::In - reading stream which is a wrapper to Yandex::Unrotate.

=cut

use base qw(
    Stream::Mixin::Filterable
    Stream::Mixin::Lag
    Stream::In
);

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

sub position($) {
    my ($self) = @_;
    return $self->{unrotate}->position;
}

sub lag {
    my ($self) = @_;
    return $self->{unrotate}->showlag;
}

# deprecated
sub showlag {
    my ($self) = @_;
    return $self->lag;
}

sub commit ($;$) {
    my ($self, $position) = @_;
    $self->SUPER::commit();
    $self->{unrotate}->commit($position ? $position : ());
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;
