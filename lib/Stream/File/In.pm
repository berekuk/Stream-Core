package Stream::File::In;

use strict;
use warnings;

=head1 NAME

Stream::File::In - input stream from any file.

=cut

use File::Basename;
use Yandex::TmpFile;
use Yandex::X qw(xopen xclose xprint);
use Carp;

use parent qw(Stream::In);

sub new {
    my ($class, $params) = @_;

    my $file = $params->{file} or croak 'file not specified';
    my $cursor = $params->{cursor} or croak 'cursor not specified';

    my $position = $cursor->position;
    $position =~ /^\d+$/ or croak "position must be integer, but cursor returned '$position'";
    my $fh = xopen($file);
    seek($fh, $position, 0);
    my $self = bless {fh => $fh, cursor => $cursor} => $class;
}

sub read ($) {
    my ($self) = @_;
    my $fh = shift->{fh};
    my $line = <$fh>;
    if (defined $line and $line !~ /\n$/) {
        return;
    }
    return $line;
}

sub commit ($) {
    my ($self) = @_;
    $self->{cursor}->commit(tell $self->{fh});
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

