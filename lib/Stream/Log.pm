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
use base qw(Stream::File);

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


=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

