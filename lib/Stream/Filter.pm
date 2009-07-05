package Stream::Filter;

use strict;
use warnings;

=head1 NAME

Stream::Filter - specialized processor which transform incoming stream into outcoming.

=head1 SYNOPSIS

    $new_line = $filter->write($line);
    $new_chunk = $filter->write_chunk(\@lines);
    $filter->commit; # commit is useless in filter, actually

=head1 METHODS

=over

=cut

use Yandex::Version '{{DEBIAN_VERSION}}';

use Carp;
use Params::Validate;
use Scalar::Util qw(blessed);

use Stream::Processor;
use base qw(
    Stream::Processor
    Exporter
);
our @EXPORT_OK = 'filter';

use overload '|' => sub {
    my ($left, $right, $swap) = @_;
    if ($swap) {
        ($left, $right) = ($right, $left);
    }
    unless (blessed $left) {
        croak "Left side of pipe is not object, but '$left'";
    }
    unless (blessed $right) {
        croak "Right side of pipe is not object, but '$right'";
    }
    if ($left->isa('Stream::Filter') and $right->isa('Stream::Processor')) {
        # right-side filter
        if ($right->isa('Stream::Filter')) {
            return Stream::Filter::FilteredFilter->new($left, $right);
        }
        else {
            return Stream::Filter::FilteredProcessor->new($left, $right);
        }
    }
    elsif ($left->isa('Stream::Stream') and $right->isa('Stream::Filter')) {
        # left-side filter
        return Stream::Filter::FilteredStream->new($left, $right);
    }
    else {
        croak "Strange arguments '$left' and '$right'";
    }
}, '""' => sub { $_[0] }; # strangely, when i overload |, i need to overload other operators too...

=item write($line)

Processes one line and return some "filtered" lines.

Number of filtered lines can be any, from zero to several.

Implementation should be provided by inherited class.

=item write_chunk($chunk)

Processes one chunk and returns another, filtered chunk.

Filtered chunk can contain any number of items, independently from source chunk, but it should be arrayref, even if it's empty.

=cut
sub write_chunk($$) {
    my ($self, $chunk) = @_;
    confess "write_chunk method expects arrayref, you specified: '$chunk'" unless ref($chunk) eq 'ARRAY'; # can chunks be blessed into something?
    my @result_chunk;
    for my $line (@$chunk) {
        push @result_chunk, $self->write($line);
    }
    return \@result_chunk;
}

=back

=cut

# not a method! (TODO - remove it from method namespace using namespace::clean?)
sub filter(&) {
    my ($callback) = @_;
    croak "Expected callback" unless ref($callback) eq 'CODE';
    # alternative constructor
    return Stream::Filter::Anon->new($callback);
}

package Stream::Filter::Anon;

our @ISA = 'Stream::Filter';

sub new {
    my ($class, $callback) = @_;
    my $self = $class->SUPER::new;
    $self->{callback} = $callback;
    return $self;
}

sub write {
    my ($self, $line) = @_;
    return $self->{callback}->($line);
}

package Stream::Filter::FilteredProcessor;

use Stream::Processor;
use base qw(Stream::Processor);

sub new {
    my ($class, $filter, $processor) = @_;
    return bless {
        filter => $filter,
        processor => $processor,
    } => $class;
}

sub write {
    my ($self, $line) = @_;
    my @lines = $self->{filter}->write($line);
    return map { $self->{processor}->write($_) } @lines;
}

sub write_chunk {
    my ($self, $chunk) = @_;
    $chunk = $self->{filter}->write_chunk($chunk);
    return $self->{processor}->write_chunk($chunk);
}

sub commit {
    my ($self) = @_;
    $self->{filter}->commit; # useless?
    $self->{processor}->commit; # necessary!
}

package Stream::Filter::FilteredStream;

use Stream::Stream;
use base qw(Stream::Stream);

sub new {
    my ($class, $stream, $filter) = @_;
    return bless {
        filter => $filter,
        stream => $stream,
    } => $class;
}

sub read {
    my ($self) = @_;
    my $line = $self->{stream}->read() or return;
    my @filtered = $self->{filter}->write($line);
    return unless @filtered;
    die "One-to-many not implemented in source filters" unless @filtered == 1;
    return $filtered[0];
}

sub read_chunk {
    my ($self, $limit) = @_;
    my $chunk = $self->{stream}->read_chunk($limit);
    return unless $chunk;
    return $self->{filter}->write_chunk($chunk);
}

sub commit {
    my ($self) = @_;
    $self->{filter}->commit; # useless?
    $self->{stream}->commit; # necessary!
}

package Stream::Filter::FilteredFilter;

# FilteredFilter is the same as FilteredProcessor, but it's also a filter, which means it can be used on a left side of a pipe
our @ISA = qw(
    Stream::Filter::FilteredProcessor
    Stream::Filter
);

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

