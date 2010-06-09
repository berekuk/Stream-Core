package Stream::Cursor::Integer;

use strict;
use warnings;

use Params::Validate qw(:all);

=head1 NAME

Stream::Cursor::Integer - simplest cursor which keeps position as a single integer value in local file.

=cut

use overload '""' => sub {
    my $self = shift;
    $self->{posfile};
};

use Carp;
use Yandex::Persistent 1.2.1;

sub new($$;$) {
    my $class = shift;
    my ($posfile, $storage) = validate_pos(@_, 1, 0);

    my $self = bless {posfile => $posfile} => $class;

    $self->load; # should be implemented in child class; calling it here to synchronize posfile and memory
    if ($storage) {
        $self->set_storage($storage); # should be implemented in child class
    }
    return $self;
}

sub posfile($) {
    my ($self) = @_;
    return $self->{posfile};
}

sub position($) {
    my ($self) = @_;

    my $posfile = $self->{posfile};
    my $state = Yandex::Persistent->new($posfile, { format => 'json' });

    my $position = $state->{position} || 0;
    $position =~ /^\d+$/ or croak "position must be integer, but $posfile contains: '$position'";

    return $position;
}

sub commit {
    my $self = shift;
    my ($position) = validate_pos(@_, {type => SCALAR, regex => qr/^\d+$/});

    my $posfile = $self->{posfile};
    my $state = Yandex::Persistent->new($posfile, { format => 'json' });
    $state->{position} = $position;
    $state->commit;
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut
1;

