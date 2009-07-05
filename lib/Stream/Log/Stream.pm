package Stream::Log::Stream;

use strict;
use warnings;

=head1 NAME

Stream::Log::Stream - stream which is a wrapper to Yandex::Unrotate.

=cut

use base qw(Stream::In);

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

sub read ($) {
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

sub showlag {
    my ($self) = @_;
    return $self->lag;
}

sub commit ($;$) {
    my ($self, $position) = @_;
    $self->{unrotate}->commit($position ? $position : ());
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

