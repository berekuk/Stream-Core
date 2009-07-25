package Stream::Utils;

use strict;
use warnings;

=head1 NAME

Stream::Utils - common stream utilities

=head1 SYNOPSIS

    use Stream::Utils qw(process);

    process($in => $out);

=cut

use Carp;
use Scalar::Util qw(blessed);
use Params::Validate;
use Stream::Catalog;

use base qw(Exporter);
our @EXPORT_OK = qw/process storage cursor stream catalog /;

our $catalog = Stream::Catalog->new; # global stream catalog, you usually need only one instance

sub catalog() {
    return $catalog;
}

sub process($$;$) {
    my ($in, $out, $limit) = validate_pos(@_, 1, 1, { optional => 1, regex => qr/^\d+$/ });

    if (blessed($in)) {
        unless ($in->isa('Stream::In')) {
            croak "first argument expected to be Stream::In, you specified: '$in'";
        }
    }
    else {
        # looking in catalog
        $in = $catalog->in($in);
    }

    if (blessed($out)) {
        unless ($out->isa('Stream::Out')) {
            croak "first argument expected to be Stream::Out, you specified: '$out'";
        }
    }
    else {
        # looking in catalog
        $out = $catalog->in($out);
    }

    my $i = 0;
    my $chunk_size = 1000;
    while (1) {
        if (defined $limit and $i + $chunk_size >= $limit) {
            $chunk_size = $limit - $i; # last chunk will be smaller than others
        }
        my $chunk = $in->read_chunk($chunk_size);
        last unless $chunk;
        $out->write_chunk($chunk);
        $i += scalar(@$chunk);
        if (defined $limit and $i >= $limit) {
            last;
        }
    }
    $out->commit; # output is committed before input to make sure that all data was flushed down correctly
    $in->commit;
    return $i; # return number of actually processed lines
}

# Deprecated! Use catalog->out instead.
sub storage($) {
    my ($name) = @_;
    return $catalog->storage($name);
}

sub cursor($) {
    my ($name) = @_;
    return $catalog->cursor($name);
}

# Deprecated! Use catalog->in instead.
sub stream($) {
    my ($name) = @_;
    return cursor($name)->stream();
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

