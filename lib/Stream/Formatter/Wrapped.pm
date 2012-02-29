package Stream::Formatter::Wrapped;

use strict;
use warnings;

use parent qw(Stream::Storage);
use Params::Validate;

use Scalar::Util qw(blessed);

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
    my $self = shift;
    my $item = shift;
    my @filtered = $self->{write_filter}->write($item);
    return unless @filtered;
    $self->{storage}->write($_, @_) for @filtered; # would write_chunk be better?
}

sub write_chunk {
    my $self = shift;
    my $chunk = shift;
    $self->{storage}->write_chunk(
        $self->{write_filter}->write_chunk($chunk),
        @_
    );
}

sub in {
    my $self = shift;
    my $input_stream = $self->{storage}->stream(@_); # TODO - replace ->stream with ->in!
    return ($input_stream | $self->{read_filter});
}

sub commit {
    my $self = shift;
    $self->{storage}->commit(@_);
}

sub DOES {
    my ($self, $role) = @_;
    if ($role eq 'Stream::Storage::Role::ClientList' or $role eq 'Stream::Role::Description') {
        return $self->{storage}->DOES($role);
    }
    return $self->SUPER::DOES($role);
}

{
    no strict 'refs';
    *does = \&DOES;
}

sub client_names { return shift->{storage}->client_names(@_) }
sub register_client { return shift->{storage}->register_client(@_) }
sub unregister_client { return shift->{storage}->unregister_client(@_) }
sub has_client { return shift->{storage}->has_client(@_) }

sub description {
    my $self = shift;
    my $inner_description = $self->{storage}->description(@_);
    return
        "format: ".blessed($self->{formatter})."\n"
        .$inner_description;
}

1;
