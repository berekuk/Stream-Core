package Stream::Formatter::Wrapped;

use strict;
use warnings;

use parent qw(Stream::Storage);
use Params::Validate;

sub new {
    my $class = shift;
    my ($formatter, $storage) = validate_pos(@_, { isa => 'Stream::Formatter' }, { isa => 'Stream::Storage' });
    return bless {
        formatter => $formatter,
        storage => $storage,
        write_filter => $formatter->write_filter,
        read_filter => $formatter->read_filter,
    } => $class;
}

sub write {
    my ($self, $item) = @_;
    my @filtered = $self->{write_filter}->write($item);
    return unless @filtered;
    $self->{storage}->write($_) for @filtered;
}

sub write_chunk {
    my ($self, $chunk) = @_;
    $self->{storage}->write_chunk($self->{write_filter}->write_chunk($chunk));
}

sub stream {
    my $self = shift;
    my $input_stream = $self->{storage}->stream(@_);
    return ($input_stream | $self->{read_filter});
}

sub stream_by_name {
    my $self = shift;
    my $input_stream = $self->{storage}->stream_by_name(@_);
    return ($input_stream | $self->{read_filter});
}

sub commit {
    my $self = shift;
    $self->{storage}->commit;
}

sub does {
    my ($self, $role) = @_;
    if ($role eq 'Stream::Storage::Role::ClientList') {
        return $self->{storage}->does($role);
    }
    return $self->SUPER::does($role);
}

sub client_names { return shift->{storage}->client_names }
sub register_client { return shift->{storage}->register_client }
sub unregister_client { return shift->{storage}->unregister_client }
sub has_client { return shift->{storage}->has_client }

1;
