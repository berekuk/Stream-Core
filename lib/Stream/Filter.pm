package Stream::Filter;

use strict;
use warnings;

=head1 NAME

Stream::Filter - specialized processor which transforms input or output streams.

=head1 SYNOPSIS

    $new_item = $filter->write($item);
    $new_chunk = $filter->write_chunk(\@items);
    $filter->commit; # commit is useless in filter, actually

    $filtered_in = $input_stream | $filter; # resulting object is a input stream
    $double_filter = $filter1 | $filter2; # resulting object is a filter
    $filtered_out = $filter | $output_stream; # resulting object is a output stream

=head1 DESCRIPTION

<Stream::Filter> instances are output streams with some meaning for C<write> and C<write_chunk> return values.

Depending on context, filters can filter input or output streams, or be attached to other filters to construct more complex filters.

A simplest way to create new filter is to use C<filter(&)> function. Or you can inherit your class from C<Stream::Filter> and implement C<write> and/or C<write_chunk> methods (and optionally C<commit> too).

C<|> operator is overloaded by all filters. It works differently depending on second parameter. Synopsis contains some examples which demostrate it more clearly.

Filters don't have to return all filtered results after each C<write> call, and results don't have to match filter's input in one-to-one fashion. On the other hand, there exist some filter clients which assume it to be so. In future there'll probably emerge some specialization expressed in roles or subclasses of C<Stream::Filter> class.

=head1 METHODS

=over

=cut

use Yandex::Version '{{DEBIAN_VERSION}}';

use Carp;
use Params::Validate;
use Scalar::Util qw(blessed);

use Stream::Out;
use base qw(
    Stream::Out
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
    if ($left->isa('Stream::Filter') and $right->isa('Stream::Out')) {
        # right-side filter
        if ($right->isa('Stream::Filter')) {
            return Stream::Filter::FilteredFilter->new($left, $right);
        }
        else {
            return Stream::Filter::FilteredOut->new($left, $right);
        }
    }
    elsif ($left->isa('Stream::In') and $right->isa('Stream::Filter')) {
        # left-side filter
        if ($left->isa('Stream::Mixin::Filterable')) {
            $left->add_filter($right);
            return $left;
        }
        else {
            return Stream::Filter::FilteredIn->new($left, $right);
        }
    }
    else {
        croak "Strange arguments '$left' and '$right'";
    }
}, '""' => sub { $_[0] }; # strangely, when i overload |, i need to overload other operators too...

=item write($item)

Processes one item and return some "filtered" items.

Number of filtered items can be any, from zero to several, so returned data must always be processed in list context.

Implementation should be provided by inherited class.

=item write_chunk($chunk)

Processes one chunk and returns another, filtered chunk.

Filtered chunk can contain any number of items, independently from source chunk, but it should be arrayref, even if it's empty.

=cut
sub write_chunk($$) {
    my ($self, $chunk) = @_;
    confess "write_chunk method expects arrayref, you specified: '$chunk'" unless ref($chunk) eq 'ARRAY'; # can chunks be blessed into something?
    my @result_chunk;
    for my $item (@$chunk) {
        push @result_chunk, $self->write($item);
    }
    return \@result_chunk;
}

=back

=head1 EXPORTABLE FUNCTIONS

=over

=item filter(&callback)

Create anonymous fitler which calls C<&callback> on each item.

=cut
# not a method! (TODO - remove it from method namespace using namespace::clean?)
sub filter(&;&) {
    my ($filter, $commit) = @_;
    croak "Expected sub, got $filter" unless ref($filter) eq 'CODE';
    croak "Expected sub, got $commit" if $commit and ref($commit) ne 'CODE';
    # alternative constructor
    return Stream::Filter::Anon->new($filter, $commit);
}

=back

=cut

package Stream::Filter::Anon;

our @ISA = 'Stream::Filter';

sub new {
    my ($class, $callback, $commit) = @_;
    my $self = $class->SUPER::new;
    $self->{callback} = $callback;
    $commit ||= sub {};
    $self->{commit} = $commit;
    return $self;
}

sub write {
    my ($self, $item) = @_;
    return $self->{callback}->($item);
}

sub commit {
    my ($self) = @_;
    return $self->{commit}->();
}

package Stream::Filter::FilteredOut;

use base qw(Stream::Out);

sub new {
    my ($class, $filter, $out) = @_;
    return bless {
        filter => $filter,
        out => $out,
    } => $class;
}

sub write {
    my ($self, $item) = @_;
    my @items = $self->{filter}->write($item);
    $self->{out}->write($_) for @items;
}

sub write_chunk {
    my ($self, $chunk) = @_;
    $chunk = $self->{filter}->write_chunk($chunk);
    return $self->{out}->write_chunk($chunk);
}

sub commit {
    my ($self) = @_;
    my @items = $self->{filter}->commit;
    $self->{out}->write_chunk(\@items);
    return $self->{out}->commit;
}

package Stream::Filter::FilteredIn;

use base qw(Stream::In);
use base qw(Stream::Mixin::Lag);

sub new {
    my ($class, $in, $filter) = @_;
    return bless {
        filter => $filter,
        in => $in,
    } => $class;
}

sub read {
    my ($self) = @_;
    my @filtered;
    while (my $item = $self->{in}->read()) {
        my @filtered = $self->{filter}->write($item);
        next unless @filtered;
        die "One-to-many not implemented in source filters" unless @filtered == 1;
        return $filtered[0];
    }
    return; # underlying input stream is depleted
}

sub read_chunk {
    my ($self, $limit) = @_;
    my $chunk = $self->{in}->read_chunk($limit);
    return unless $chunk;
    return $self->{filter}->write_chunk($chunk);
}

sub commit {
    my ($self) = @_;
    my @items = $self->{filter}->commit;
    die "flushable filters cannot be attached to input streams" if @items;
    #FIXME: check it earlier
    $self->{in}->commit;
}

sub lag {
    my $self = shift;
    die unless $self->{in}->isa('Stream::Mixin::Lag');
    return $self->{in}->lag;
}

package Stream::Filter::FilteredFilter;

# FilteredFilter is the same as FilteredOut, but it's also a filter, which means it can be used on a left side of a pipe
our @ISA = qw(
    Stream::Filter::FilteredOut
    Stream::Filter
);

sub write {
    my ($self, $item) = @_;
    my @items = $self->{filter}->write($item);
    my @result = map { $self->{out}->write($_) } @items;
    return (wantarray ? @result : $result[0]);
}

sub commit {
    my ($self) = @_;
    my @items = $self->{filter}->commit;
    my $result = $self->{out}->write_chunk(\@items);
    push @$result, $self->{out}->commit;
    return @$result;
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

