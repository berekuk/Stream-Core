package Stream::DB::Cursor;

use strict;
use warnings;

# ABSTRACT: DB cursor

use Params::Validate;
use Carp;
use Yandex::Persistent 1.2.1;

use Stream::DB::In;
use Stream::DB;

sub new {
    my $class = shift;
    my ($posfile, $storage) = validate_pos(@_, 1, 0);

    my $self = bless { posfile => $posfile } => $class;
    $self->set_storage($storage) if $storage;
    return $self;
}

sub state {
    my $self = shift;
    validate_pos(@_);
    return Yandex::Persistent->new($self->{posfile}, { format => 'json', auto_commit => 0 });
}

# see note for this method in Stream::File::Cursor
sub position {
    my $self = shift;
    return $self->state->{position} || 0;
}

sub set_storage {
    my $self = shift;
    my ($storage) = validate_pos(@_, { isa => 'Stream::DB' });

    my $state = $self->state;
    if ($state->{storage}) {
        # some storage already associated
        # TODO - what should we do, croak or silently overwrite?
        # probably we should overwrite association but print log message about all changed fields
    }
    $state->{storage} = $storage->params;
    $state->commit;
}

sub stream {
    my $self = shift;
    my ($storage) = validate_pos(@_, { isa => 'Stream::File', optional => 1 });

    unless ($storage) {
        my $storage_params = $self->state->{storage};
        unless ($storage_params) {
            croak "Cursor '$self' doesn't have any associated storage";
        }
        $storage = Stream::DB->new($self->state->{storage});
    }
    return Stream::DB::In->new({ storage => $storage, cursor => $self });
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

