package Stream::Filter;

use strict;
use warnings;

# ABSTRACT: objects for transforming input or output streams.

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

use parent qw(Stream::Base);

use Carp;
use Params::Validate qw(:all);
use Scalar::Util qw(blessed);

use Stream::Out;
use parent qw(Exporter);
our @EXPORT_OK = 'filter';

use Stream::Filter::Anon;
use Stream::Filter::FilteredIn;
use Stream::Filter::FilteredOut;
use Stream::Filter::FilteredFilter;

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
        if ($left->isa('Stream::In::Role::Filterable')) {
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

1;
