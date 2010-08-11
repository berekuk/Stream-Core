package Stream::In::Role::Lag;

use strict;
use warnings;

=head1 NAME

Stream::In::Role::Lag - lag-showing role

=head1 DESCRIPTION

Input streams implementing this role can be asked for amount of data remaining in stream.

Amount units are stream-specific.

=head1 METHODS

=over

=item C<lag()>

Get stream's lag.

=cut

sub lag($);

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut
1;
