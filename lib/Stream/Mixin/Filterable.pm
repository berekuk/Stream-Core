package Stream::Mixin::Filterable;

use strict;
use warnings;

=head1 NAME

Stream::Mixin::Filterable - allows you to attach stack of filters to your input stream

=head1 METHODS

=over

=cut

use base qw( Stream::In );

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
    my $item = $self->do_read; # child class should implement do_read() instead of read()
    unless (defined $item) {
        return;
    }

    for my $filter (@{$self->{_Filters}}) {
        $item = $filter->write($item);
        unless (defined $item) {
            return;
        }
    }
    return $item;
}

=item C<commit()>

Commits all filters in stack.

Child class must call C<SUPER->commit()> to make sure that all filters was commited successfully.

=cut
sub commit {
    my $self = shift;
    for my $filter (@{$self->{_Filters}}) {
        $filter->commit;
    }
}

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

