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

=head1 EXPORTABLE FUNCTIONS

=over

=item filter(&callback)

Create anonymous fitler which calls C<&callback> on each item.

=cut
# not a method! (TODO - remove it from method namespace using namespace::clean?)
sub filter(&) {
    my ($callback) = @_;
    croak "Expected callback" unless ref($callback) eq 'CODE';
    # alternative constructor
    return Stream::Filter::Anon->new($callback);
}

=back

=cut

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
    my ($self, $line) = @_;
    my @lines = $self->{filter}->write($line);
    return map { $self->{out}->write($_) } @lines;
}

sub write_chunk {
    my ($self, $chunk) = @_;
    $chunk = $self->{filter}->write_chunk($chunk);
    return $self->{out}->write_chunk($chunk);
}

sub commit {
    my ($self) = @_;
    $self->{filter}->commit; # useless?
    $self->{out}->commit; # necessary!
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
    my $line = $self->{in}->read() or return;
    my @filtered = $self->{filter}->write($line);
    return unless @filtered;
    die "One-to-many not implemented in source filters" unless @filtered == 1;
    return $filtered[0];
}

sub read_chunk {
    my ($self, $limit) = @_;
    my $chunk = $self->{in}->read_chunk($limit);
    return unless $chunk;
    return $self->{filter}->write_chunk($chunk);
}

sub commit {
    my ($self) = @_;
    $self->{filter}->commit; # useless?
    $self->{in}->commit; # necessary!
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

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

