package Stream::DB::Cursor;

use strict;
use warnings;

=head1 NAME

Stream::DB::Cursor - DB cursor

=cut

use Stream::DB::In;
use base qw(Stream::Cursor::Integer);
use Carp;

sub load {
    my ($self) = @_;
    my $state = new Yandex::Persistent($self->posfile);

    if ($state->{storage}) {
        if ($self->{storage}) {
            # already associated, reassociating is not implemented, and checking is not implemented too
        }
        else {
            # load association
            for (/table db fields pk/) {
                $self->{storage}{$_} = $state->{storage}{$_};
            }
        }
    }
}

sub set_storage {
    my ($self, $storage) = @_;

    # TODO - check storage type?
    # TODO - allow association by name in catalog?

    my $state = new Yandex::Persistent($self->posfile);
    if ($state->{storage}) {
        # TODO - what should we do, croak or silently overwrite?
        # probably we should overwrite association but print log message about all changed fields
    }
    $state->{storage} = $storage->params;
    $state->commit;

    for (/table db fields pk/) {
        $self->{storage}{$_} = $state->{storage}{$_};
    }
}

sub stream {
    my ($self, $storage) = @_;
    if ($self->{storage}) {
        if ($storage) {
            croak "cursor '$self' already have associated storage";
        }
        else {
            $storage = $self->{storage};
        }
    }
    else {
        if ($storage) {
            $self->set_storage($storage);
        }
        else {
            croak "Cursor '$self' doesn't have any associated storage";
        }
    }
    return Stream::DB::In->new({storage => $storage, cursor => $self});
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

