package Stream::File::In;

use strict;
use warnings;

# ABSTRACT: input stream from any file.

use File::Basename;
use Yandex::TmpFile;
use Yandex::X qw(xopen xclose xprint);
use Carp;

use parent qw(
    Stream::In::Role::Lag
    Stream::In
);

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
    my $fh = $self->{fh};
    my $line = <$fh>;
    return unless defined $line;
    if ($line !~ /\n$/) {
        # incomplete line => backstep
        seek $fh, - length $line, 1;
        return;
    }

    return $line;
}

sub read_chunk {
    my ($self, $size) = @_;

    my @result;
    my $fh = $self->{fh};

    while (1) {
        my $line = <$fh>;
        last unless defined $line;
        if ($line !~ /\n$/) {
            # incomplete line => backstep
            seek $fh, - length $line, 1;
            last;
        }
        push @result, $line;
        $size--;
        last if $size <= 0;
    }
    return unless @result;
    return \@result;
}

sub lag ($) {
    my ($self) = @_;

    my @stat = stat $self->{fh};
    unless (@stat) {
        die "stat failed: $!";
    }
    my $size = $stat[7];

    my $pos = tell $self->{fh};
    if ($pos == -1) {
        die "tell failed: $!";
    }

    return $size - $pos;
}

sub commit ($) {
    my ($self) = @_;
    my $state = $self->{cursor}->state;
    $state->{position} = tell $self->{fh};
    $state->commit;
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

