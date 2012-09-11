package Stream::Catalog::Plugin::ParsePipe;

use strict;
use warnings;

# ABSTRACT: catalog plugin which parses pipes of stream objects names.

=head1 METHODS

=over

=cut

use Scalar::Util qw(blessed);
use Carp;
use Params::Validate qw(:all);

use parent qw(Stream::Catalog::Plugin);

=item C<new($catalog)>

Constructs plugin.

Parameters:

=over

=item I<catalog>

This plugin needs calatog object to resolve steams and filters names.

=back

=cut
sub new {
    my $class = shift;
    my ($catalog) = validate_pos(@_, { isa => 'Stream::Catalog' });
    return bless { catalog => $catalog } => $class;
}


=item C<in($name)>

Splits C<$name> by B<|> and returns pipe of filters preceded by in stream.

=cut
sub in {
    my ($self, $name) = @_;

    if ($name =~ /\|/) {
        my ($in, @filters) = split /\s*\|\s*/, $name;
        $in = $self->{catalog}->in($in);
        for (@filters) {
            $in = $in | $self->{catalog}->filter($_);
        }
        return $in;
    } else {
        return;
    }
}

=item C<out($name)>

Splits C<$name> by B<|> and returns pipe of filters followed by out stream.

=cut
sub out {
    my ($self, $name) = @_;
    if ($name =~ /\|/) {
        my @filters = split /\s*\|\s*/, $name;
        my $out = $self->{catalog}->out(pop @filters);
        for (@filters) {
            $out = $self->{catalog}->filter($_) | $out;
        }
        return $out;
    } else {
        return;
    }
}

=item C<filter($name)>

Splits C<$name> by B<|> and returns pipe of filters.

=cut
sub filter {
    my ($self, $name) = @_;
    if ($name =~ /\|/) {
        my ($filter, @filters) = split /\s*\|\s*/, $name;
        $filter = $self->{catalog}->filter($filter);
        for (@filters) {
            $filter = $filter | $self->{catalog}->filter($_);
        }
        return $filter;
    } else {
        return;
    }
}

=back

=cut

1;

