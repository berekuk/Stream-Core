package Stream::Filter;

use strict;
use warnings;

=head1 NAME

Stream::Filter - objects for transforming input or output streams.

=head1 SYNOPSIS

    $new_item = $filter->write($item);
    # or when you know that filter can generate multiple items from one:
    @items = $filter->write($item);

    $new_chunk = $filter->write_chunk(\@items);

    @last_items = $filter->commit; # some filters keep items in internal buffer and process them at commit step

    $filtered_in = $input_stream | $filter; # resulting object is a input stream
    $double_filter = $filter1 | $filter2; # resulting object is a filter
    $filtered_out = $filter | $output_stream; # resulting object is a output stream

=head1 DESCRIPTION

C<Stream::Filter> instances can be attached to other streams to filter, expand and transform their data.

It's API is currently identical to C<Stream::Out>, consisting of C<write>, C<write_chunk> and C<commit> methods, but unlike common output streams, values returned from these methods are always getting used.

Depending on context, filters can filter input or output streams, or be attached to other filters to construct more complex filters.

A simplest way to create new filter is to use C<filter(&)> function. Or you can inherit your class from C<Stream::Filter> and implement C<write> and/or C<write_chunk> methods (and optionally C<commit> too).

C<|> operator is overloaded by all filters. It works differently depending on second parameter. Synopsis contains some examples which demostrate it more clearly.

Filters don't have to return all filtered results after each C<write> call, and results don't have to match filter's input in one-to-one fashion. On the other hand, there exist some filter clients which assume it to be so. In future there'll probably emerge some specialization expressed in roles or subclasses of C<Stream::Filter> class.

=head1 METHODS

=over

=cut

use Yandex::Version '{{DEBIAN_VERSION}}';

use Carp;
use Params::Validate qw(:all);
use Scalar::Util qw(blessed);

use Stream::Out;
use base qw(
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
    if ($left->isa('Stream::Filter') and $right->isa('Stream::Filter')) {
        # f | f
        return Stream::Filter::FilteredFilter->new($left, $right);
    }
    elsif ($left->isa('Stream::Filter') and $right->isa('Stream::Out')) {
        # f | o
        return Stream::Filter::FilteredOut->new($left, $right);
    }
    elsif ($left->isa('Stream::In') and $right->isa('Stream::Filter')) {
        # i | f
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

=item I<new>

Default constructor returns empty blessed hashref. You can redefine it with any parameters you want.

=cut
sub new {
    return bless {} => shift;
}

=item I<write($item)>

Processes one item and return some "filtered" items.

Number of filtered items can be any, from zero to several, so returned data should always be processed in list context.

Implementation should be provided by inherited class.

=item I<write_chunk($chunk)>

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

=item I<commit()>

C<commit> method can flush cached data and return remaining transformed items as plain list.

Default implementation does nothing.

=cut
sub commit {
    return ();
}

=back

=head1 EXPORTABLE FUNCTIONS

=over

=item I<filter(&write_cb)>

=item I<filter(&write_cb, &flush_cb)>

Create anonymous fitler which calls C<&write_cb> on each item.

If C<&flush_cb> is provided, it'll be called at commit step and it's results will be used too (but remember that flushable filters can't be attached to input streams).

=cut
# not a method! (TODO - remove it from method namespace using namespace::clean?)
sub filter(&;&) {
    my ($filter, $commit) = validate_pos(@_, { type => CODEREF }, { type => CODEREF, optional => 1 });
    # alternative constructor
    return Stream::Filter::Anon->new($filter, $commit);
}

=back

=cut

package Stream::Filter::Anon;

our @ISA = 'Stream::Filter';
use Params::Validate qw(:all);

sub new {
    my $class = shift;
    my ($callback, $commit) = validate_pos(@_, { type => CODEREF }, { type => CODEREF | UNDEF, optional => 1 });
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

use base qw(Stream::Filter);

sub new {
    my ($class, $f1, $f2) = @_;
    return bless {
        f1 => $f1,
        f2 => $f2,
    } => $class;
}

sub write {
    my ($self, $item) = @_;
    my @items = $self->{f1}->write($item);
    my @result = map { $self->{f2}->write($_) } @items;
    return (wantarray ? @result : $result[0]);
}

sub write_chunk {
    my ($self, $chunk) = @_;
    $chunk = $self->{f1}->write_chunk($chunk);
    return $self->{f2}->write_chunk($chunk);
}

sub commit {
    my ($self) = @_;
    my @items = $self->{f1}->commit;
    my $result = $self->{f2}->write_chunk(\@items);
    push @$result, $self->{f2}->commit;
    return @$result;
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

