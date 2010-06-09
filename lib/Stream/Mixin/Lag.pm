package Stream::Mixin::Lag;

use strict;
use warnings;

use parent qw(Stream::Base);

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

sub class_caps {
    return { lag => 1 };
}

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

