package Stream::Mixin::Lag;

use strict;
use warnings;

=head1 NAME

Stream::Mixin::Lag - lag-showing trait

=head1 DESCRIPTION

Input streams having this mix-in can be asked for amount of data remaining in stram.

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

