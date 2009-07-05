package Stream::Processor;

use strict;
use warnings;

=head1 NAME

Stream::Processor - interface for any module which processes streams

=head1 SYNOPSIS

    $processor->write($line);
    $processor->write_chunk(\@lines);
    $processor->commit;

=cut

use Yandex::Version '{{DEBIAN_VERSION}}';

use base qw(Exporter);
our @EXPORT_OK = 'processor';

use Carp;

sub new {
    return bless {} => shift;
}

sub write($$) {
    my ($self, $line) = @_;
    croak "write unimplemented";
}

sub write_chunk($$) {
    my ($self, $chunk) = @_;
    confess "write_chunk method expects arrayref, you specified: '$chunk'" unless ref($chunk) eq 'ARRAY'; # can chunks be blessed into something?
    for my $line (@$chunk) {
        $self->write($line);
    }
    return; # TODO - what useful data can we return?
}

sub commit {
    # do nothing by detault
}

sub processor(&) {
    my ($callback) = @_;
    croak "Expected callback" unless ref($callback) eq 'CODE';
    # alternative constructor
    return Stream::Processor::Anon->new($callback);
}
1;

package Stream::Processor::Anon;

our @ISA = 'Stream::Processor';

sub new {
    my ($class, $callback) = @_;
    my $self = $class->SUPER::new;
    $self->{callback} = $callback;
    return $self;
}

sub write {
    my ($self, $line) = @_;
    $self->{callback}->($line);
}

