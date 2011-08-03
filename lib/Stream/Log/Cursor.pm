package Stream::Log::Cursor;

use strict;
use warnings;

use Params::Validate qw(:all);

# ABSTRACT: log cursor - unrotate wrapper

use Stream::Log::In;
use Carp;
use Yandex::Unrotate;

sub new($$) {
    my $class = shift;
    my $params = validate_with(
        params => \@_,
        spec => {
            PosFile => {type => SCALAR},
            LogFile => {type => SCALAR, optional => 1},
        },
        allow_extra => 1,
    );

    my $self = bless {%$params} => $class;
    return $self;
}

sub stream {
    my $self = shift;
    if (@_ > 2) {
        croak "Expected options: (storage, unrotate_params) or (unrorate_params)";
    }

    my $storage;
    my $unrotate_params = {};

    if (@_ == 2) {
        # (storage, {UnrotateParams})
        ($storage, $unrotate_params) = validate_pos(@_, {isa => 'Stream::Log'}, {type => HASHREF});
    }
    elsif (@_ == 1) {
        if (ref($_[0]) eq 'HASH') {
            # unrotate params
            $unrotate_params = $_[0];
        }
        elsif ($_[0]->isa('Stream::Log')) {
            # storage
            $storage = $_[0];
        }
        else {
            die "Expected hashref or Stream::Log object, you specified: '$storage'";
        }
    }

    if ($storage) {
        if ($self->{LogFile}) {
            if ($storage->file ne $self->{LogFile}) {
                croak "Cursor '$self->{PosFile}' is already associated with log '$self->{LogFile}', can't redefine into '".$storage->file."'";
            }
        }
        else {
            # could associate with LogFile here, but it's useless anyway - Stream::Log::In currently implements commit logic itself
            $self->{LogFile} = $storage->file;
        }
    }

    $unrotate_params = {%$self, %$unrotate_params};

    return Stream::Log::In->new($unrotate_params);
}

1;
