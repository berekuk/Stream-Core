package Stream::Pumper::Common;

use strict;
use warnings;

=head1 NAME

Stream::Pumper::Common - common class for simple in-filter-out pumpers.

=head1 SYNOPSIS

    $pumper = Stream::Pumper::Common->new({ in => $in, filter => $filter, out => $out });
    $pumper->pump({ limit => 100 });

=cut

use parent qw(Stream::Pumper);

use Params::Validate qw(:all);
use Stream::Utils qw(process);

sub new {
    my $class = shift;
    my $self = validate(@_, {
        in => { isa => 'Stream::In' },
        out => { isa => 'Stream::Out' },
        filter => { isa => 'Stream::Filter', optional => 1 },
    });
    return bless $self => $class;
}

sub pump {
    my $self = shift;
    my $options = validate(@_, {
        limit => { type => SCALAR, regex => qr/^\d+$/, optional => 1 },
    });
    my $limit = $options->{limit};
    my $out = $self->{out};
    $out = $self->{filter} | $out if $self->{filter};
    process($self->{in} => $out, {
        defined($limit) ? (limit => $limit) : (),
    });
    return; # don't want anyone to rely on pump() return value too soon
}

1;

