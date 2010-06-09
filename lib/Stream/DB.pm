package Stream::DB;

use strict;
use warnings;

use Yandex::Version '{{DEBIAN_VERSION}}';

=head1 NAME

Stream::DB - DB-based storage

=head1 METHODS

=over

=cut

use Yandex::DB 2.2.0;
use PPB::DB::Inserter;
use Stream::DB::In;

use Params::Validate qw(:all);

use Carp;

use parent qw(Stream::Storage);

=item new($params)

Construct storage.

Possible params:

=over

=item I<db>

DB name for L<Yandex::DB> to connect.

=item I<table>

Table name.

=item I<fields>

Array ref with field names.

=item I<pk>

Primary key. If not specified, assumed to be C<id>.

=back

=cut
sub new {
    my $class = shift;
    my $params = validate(@_, {
        table => { type => SCALAR },
        db => { type => SCALAR },
        fields => { type => ARRAYREF },
        pk => { default => 'id' },
    });
    my $self = bless $params => $class;
}

sub _prepare_write {
    my ($self) = @_;
    $self->{inserter} = PPB::DB::Inserter->new({
        DB => connectdb($self->{db}),
        Insert => "INSERT IGNORE $self->{table} (".join(',', @{$self->{fields}}).")", # FIXME - ignore should be optional!
        Values => join(',', ('?')x@{$self->{fields}}),
    });
}

=item write($values)

Write new row in storage.

C<$values> should be hashref with data.

=cut
sub write {
    my ($self, $values) = @_;
    $self->_prepare_write unless $self->{inserter};
    $self->{inserter}->insert(
        map { ($values->{$_}) } @{$self->{fields}}
    );
}

=item commit()

Flush and commit remaining data in storage.

=cut
sub commit {
    my ($self) = @_;
    return unless $self->{inserter};
    $self->{inserter}->finish;
    delete $self->{inserter};
}

=item params()

Get storage params as plain hashref.

Used in Stream::DB::Cursor when associating cursor with storage.

=cut
sub params {
    my ($self) = @_;
    return {
        fields => $self->{fields},
        pk => $self->{pk},
        db => $self->{db},
        table => $self->{table},
    };
}

=item stream($cursor)

Construct input stream from storage, starting from position saved in cursor.

C<$cursor> should be of C<Stream::DB::Cursor> class.

=cut
sub stream {
    my ($self, $cursor) = @_;
    return Stream::DB::In->new({storage => $self, cursor => $cursor});
}

sub class_caps {
    return { persistent => 1 };
}

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

