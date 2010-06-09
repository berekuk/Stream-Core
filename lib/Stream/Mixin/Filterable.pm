package Stream::Mixin::Filterable;

use strict;
use warnings;

=head1 NAME

Stream::Mixin::Filterable - allows you to inject stack of filters into your input stream.

=head1 SYNOPSIS

    $in = ...; # $in have to implement do_read() instead of read()
    $in->add_filter($f1);
    $in->add_filter($f2);

    $item = $in->read();

=head1 DESCRIPTION

Usual way to filter streams (C< $in | $filter >) has one defect: resulting filtered stream don't propagate custom methods to original input stream.

You can use C<Stream::Mixin::Filterable> as workaround. This mixin allows to inject filters directly into your input stream using usual C<|> syntax (L<Stream::Filter> knows about this mixin for C<|> to work correctly in all cases).

Remember that you have to implement C<do_read> method instead of C<read>, and your C<read_chunk> should call C<read> too for all these things to work.

=head1 METHODS

=over

=cut

use parent qw( Stream::In );

use Params::Validate;

=item C<add_filter($filter)>

Adds new filter to filter stack.

C<$filter> must be C<Stream::Filter> object.

=cut
sub add_filter {
    my $self = shift;
    my ($filter) = validate_pos(@_, { isa => 'Stream::Filter' });
    push @{$self->{_Filters}}, $filter;
}

=item C<read()>

Read new item from child class using C<do_read()> method and filter it using each filter in filter stack.

=cut
sub read {
    my $self = shift;

    ITEM: while (1) {
        # child class should implement do_read() instead of read()
        my $item = $self->do_read;
        last unless defined $item;

        for my $filter (@{$self->{_Filters}}) {
            my (@filtered) = $filter->write($item);
            if (not @filtered or (@filtered == 1 and not defined $filtered[0])) {
                next ITEM;
            }
            die "One-to-many not implemented in mixin filters attached to input stream" unless @filtered == 1; # TODO - put items in stack and return them on following reads
            $item = $filtered[0];
        }
        return $item;
    }
    return; # stream depleted
}

# TODO - read_chunk??

=item C<commit()>

Commits all filters in stack.

Child class must call C<SUPER->commit()> to make sure that all filters was commited successfully.

=cut
sub commit {
    my $self = shift;
    for my $filter (@{$self->{_Filters}}) {
        my @result = $filter->commit;
        if (@result) {
            die "Filter $filter is flushable";
        }
    }
}

=back

=head1 SEE ALSO

L<Stream::Filter>

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

