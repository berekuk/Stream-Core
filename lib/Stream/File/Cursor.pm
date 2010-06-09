package Stream::File::Cursor;

use strict;
use warnings;

use Params::Validate;

=head1 NAME

Stream::File::Cursor - file cursor

=cut

use parent qw(Stream::Cursor::Integer);
use Yandex::Persistent;
use Carp;

sub load {
    my $self = shift;
    validate_pos(@_);
    my $state = Yandex::Persistent->new($self->{posfile}, { format => 'json' });

    if ($state->{storage_file}) {
        if ($self->{storage_file}) {
            # already associated
            if ($state->{storage_file} eq $self->{storage_file}) {
                return;
            }
            else {
                croak "Cursor '$self->{posfile}' is already associated with file '$self->{storage_file}', but state file specifies '$state->{storage_file}'";
            }
        }
        else {
            $self->{storage_file} = $state->{storage_file}; # load association
        }
    }
}

sub set_storage
{
    my $self = shift;
    my ($storage) = validate_pos(@_, {isa => 'Stream::File'});

    # TODO - check storage type?
    # TODO - allow association by name in catalog?

    my $state = Yandex::Persistent->new($self->{posfile}, { format => 'json' });
    if ($state->{storage_file}) {
        if ($state->{storage_file} eq $storage->file) {
            # already associated
            return;
        }
        croak "Cursor '$self->{posfile}' is already associated with file '$state->{storage_file}'";
    }
    $state->{storage_file} = $storage->file;
    $state->commit;
    $self->{storage} = $storage;
    $self->{storage_file} = $storage->file;
}

sub stream {
    my $self = shift;
    my ($storage) = validate_pos(@_, {isa => 'Stream::File', optional => 1});

    my $storage_file;
    if ($storage) {
        $storage_file = $storage->file;
    }

    if ($self->{storage_file}) {
        if ($storage_file and $storage_file ne $self->{storage_file}) {
            croak "cursor '$self->{posfile}' already have associated file $self->{storage_file}, can't redefine to $storage_file";
        }
        else {
            $storage_file = $self->{storage_file};
        }
    }
    else {
        if ($storage_file) {
            $self->set_storage($storage);
        }
        else {
            croak "Cursor '$self->{posfile}' doesn't have any associated file";
        }
    }
    return Stream::File::In->new({file => $storage_file, cursor => $self});
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

