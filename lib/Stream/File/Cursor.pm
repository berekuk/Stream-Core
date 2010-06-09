package Stream::File::Cursor;

use strict;
use warnings;

=head1 NAME

Stream::File::Cursor - file cursor

=cut

use Params::Validate;
use Carp;

use Yandex::Persistent 1.2.1;

sub new {
    my $class = shift;
    my ($posfile, $storage) = validate_pos(@_, 1, 0); # TODO - do we really need to set storage from cursor's constructor?

    my $self = bless {posfile => $posfile} => $class;
    $self->set_storage($storage) if $storage;
    return $self;
}

sub state {
    my $self = shift;
    validate_pos(@_);
    return Yandex::Persistent->new($self->{posfile}, { format => 'json', auto_commit => 0 });
}

# I don't know if anyone uses this method.
# It existed in old versions, and it could be handy to construct cursor without input stream,
# but it requires high coupling between this module and Stream::File::In. Sigh...
sub position {
    my $self = shift;
    return $self->state->{position} || 0;
}

sub set_storage
{
    my $self = shift;
    my ($storage) = validate_pos(@_, { isa => 'Stream::File' });

    my $state = $self->state;
    if ($state->{storage_file}) {
        if ($state->{storage_file} eq $storage->file) {
            # already associated
            return;
        }
        croak "Cursor '$self->{posfile}' is already associated with file '$state->{storage_file}'";
    }
    $state->{storage_file} = $storage->file;
    $state->commit;
}

sub stream {
    my $self = shift;
    my ($storage) = validate_pos(@_, { isa => 'Stream::File', optional => 1 });

    my $storage_file;
    if ($storage) {
        $storage_file = $storage->file;
        $self->set_storage($storage);
    }
    else {
        $storage_file = $self->state->{storage_file};
    }

    unless (defined $storage_file) {
        croak "Cursor '$self->{posfile}' doesn't have any associated file";
    }

    return Stream::File::In->new({ file => $storage_file, cursor => $self });
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

