package Stream::Utils;

use strict;
use warnings;

=head1 NAME

Stream::Utils - common stream utilities

=head1 SYNOPSIS

    use Stream::Utils qw(process);

    process($in => $out);

=cut

use Params::Validate;
use Stream::Catalog;

use base qw(Exporter);
our @EXPORT_OK = qw/process storage cursor stream catalog /;

sub process($$;$) {
    my ($in, $out, $limit) = validate_pos(@_, {isa => 'Stream::In'}, {isa => 'Stream::Out'}, 0);
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

our $catalog = Stream::Catalog->new; # global stream catalog, you usually need only one instance

sub catalog() {
    return $catalog;
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

