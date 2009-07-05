package Stream::DB;

use strict;
use warnings;

=head1 NAME

Stream::DB - DB-based storage

=cut

use Yandex::DB 2.2.0;
use PPB::DB::Inserter;
use Stream::DB::Stream;

use Carp;

use base qw(Stream::Storage);

sub new {
    my ($class, $params) = @_;
    my $table = $params->{table} or croak "No table specified";
    my $db = $params->{db} or croak "No DB specified";
    my $fields = $params->{fields} or croak "No fields specified";
    my $pk = $params->{pk} || 'id';

    my $self = bless {
        table => $table,
        db => $db,
        fields => $fields,
        pk => $pk,
    } => $class;
}

sub _prepare_write {
    my ($self) = @_;
    $self->{inserter} = PPB::DB::Inserter->new({
        DB => connectdb($self->{db}),
        Insert => "INSERT IGNORE $self->{table} (".join(',', @{$self->{fields}}).")", # FIXME - ignore should be optional!
        Values => join(',', ('?')x@{$self->{fields}}),
    });
}

sub write {
    my ($self, $values) = @_;
    $self->_prepare_write unless $self->{inserter};
    $self->{inserter}->insert(
        map { ($values->{$_}) } @{$self->{fields}}
    );
}

sub commit {
    my ($self) = @_;
    return unless $self->{inserter};
    $self->{inserter}->finish;
    delete $self->{inserter};
}

# used in Cursor when associating cursor with storage
sub params {
    my ($self) = @_;
    return {
        fields => $self->{fields},
        pk => $self->{pk},
        db => $self->{db},
        table => $self->{table},
    };
}

sub stream {
    my ($self, $cursor) = @_;
    return Stream::DB::Stream->new({storage => $self, cursor => $cursor});
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

