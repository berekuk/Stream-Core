package Stream::Log;

use strict;
use warnings;

=head1 NAME

Stream::Log - storage implemented as log.

=head1 DESCRIPTION

This class is similar to L<Stream::File>, but designed to work with logs (files which can rotate sometimes).

In future it'll probably contain some logic about safe writing into rotating logs.

=cut

use Params::Validate qw(:all);

use Stream::File;
use Digest::MD5 qw(md5_hex);
use base qw(Stream::File);

=head1 METHODS

=over

=item B<stream($cursor)>

=item B<stream($cursor, $unrotate_params)>

Construct stream object from an L<Stream::Log::Cursor> object.

C<$unrotate_params> can contain more unrotate options.

=cut
sub stream($$;$) {
    my $self = shift;
    my ($cursor, $unrotate_params) = validate_pos(@_, {isa => 'Stream::Log::Cursor'}, {type => HASHREF, optional => 1});

    return $cursor->stream($self, ($unrotate_params ? $unrotate_params : ()));
}

=item B<stream_by_name($name)>

=item B<stream_by_name($name, $unrotate_params)>

Construct stream object by name.

Position will be saved in file which guaranteed to be unique for any log+name pair.

C<$unrotate_params> can contain more unrotate options.

=cut
sub stream_by_name($$;$) {
    my $self = shift;
    my ($name, $unrotate_params) = validate_pos(@_, { type => SCALAR }, {type => HASHREF, optional => 1});
    my $posdir = $ENV{STREAM_LOG_POSDIR} || '/var/lib/stream'; # env variable is neccesary for tests
    my $posfile = $posdir.'/'.md5_hex($name).'.'.md5_hex($self->file).'.pos';
    my $cursor = Stream::Log::Cursor->new({ LogFile => $self->file, PosFile => $posfile });
    return $cursor->stream($self, ($unrotate_params ? $unrotate_params : ()));
}

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

