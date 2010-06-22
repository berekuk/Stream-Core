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
use Stream::Utils qw(process catalog :vivify);

sub new {
    my $class = shift;
    my $self = validate(@_, {
        in => 1,
        out => 1,
        filter => { optional => 1 },
    });
    $self->{in} = vivify_in($self->{in});
    $self->{out} = vivify_out($self->{out});
    $self->{filter} = vivify_filter($self->{filter}) if defined $self->{filter};
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

