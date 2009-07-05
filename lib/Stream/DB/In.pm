package Stream::DB::In;

use strict;
use warnings;

=head1 NAME

Stream::DB::In - DB reading stream

=cut

use Yandex::DB;
use Carp;

use Params::Validate qw(:all);

=head1 CONSTRUCTOR

=over

=item C<< new({storage => $storage, cursor => $cursor}) >>

Constructs new reading stream. C<$storage> should be L<Stream::DB> instance, C<$cursor> - L<Stream::DB::Cursor>.

=cut
sub new($$) {
    my $class = shift;
    my $params = validate(@_, {
        storage => { isa => 'Stream::DB' },
        cursor => { isa => 'Stream::DB::Cursor' },
    });
    my ($storage, $cursor) = ($params->{storage}, $params->{cursor});

    my $self = bless {
        dbh => connectdb($storage->{db}),
        table => $storage->{table},
        fields => $storage->{fields},
        pk => $storage->{pk},
        cursor => $cursor,
    } => $class;

    if (grep {$_ eq $storage->{pk}} @{$storage->{fields}}) {
        $self->{pk_in_fields} = 1;
    }
    $self->{position} = $cursor->position;
    return $self;
}

sub read_chunk($$) {
    my ($self, $limit) = @_;
    $limit =~ /^\d+$/ or croak "Wrong limit '$limit'";
    my $pk = $self->{pk};
    my $sth = $self->{dbh}->prepare(qq{
        SELECT $pk, }.join(',', @{$self->{fields}}).qq(
        FROM $self->{table}
        WHERE $pk > $self->{position}
        LIMIT $limit
    ));
    $sth->execute;

    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        $self->{position} = $row->{$pk};
        unless ($self->{pk_in_fields}) {
            delete $row->{$pk};
        }
        push @rows, $row;
    }
    return unless @rows;
    return \@rows;
}

# FIXME - very non-optimal implementation!!!
sub read {
    my ($self) = @_;
    my $chunk = $self->read_chunk(1);
    return unless $chunk;
    return $chunk->[0];
}

sub commit {
    my ($self) = @_;
    $self->{cursor}->commit($self->{position});
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

