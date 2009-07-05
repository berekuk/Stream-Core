package Stream::Utils;

use strict;
use warnings;

=head1 NAME

Stream::Utils - common stream utilities

=head1 SYNOPSIS

    use Stream::Utils qw(process);

    process($stream => $processor);

=cut

use Params::Validate;
use Stream::Catalog;

use base qw(Exporter);
our @EXPORT_OK = qw/process storage cursor stream/;

sub process($$;$) {
    my ($stream, $processor, $limit) = validate_pos(@_, {isa => 'Stream::Stream'}, {isa => 'Stream::Processor'}, 0);
    my $i = 0;
    my $chunk_size = 1000;
    while (1) {
        if (defined $limit and $i + $chunk_size >= $limit) {
            $chunk_size = $limit - $i; # last chunk will be smaller than others
        }
        my $chunk = $stream->read_chunk($chunk_size);
        last unless $chunk;
        $processor->write_chunk($chunk);
        $i += scalar(@$chunk);
        if (defined $limit and $i >= $limit) {
            last;
        }
    }
    $processor->commit; # processor is committed before stream to make sure that all data was flushed down correctly
    $stream->commit;
    return $i; # return number of actually processed lines
}

our $catalog = Stream::Catalog->new; # global stream catalog, you usually need only one instance
sub storage($) {
    my ($name) = @_;
    return $catalog->storage($name);
}

sub cursor($) {
    my ($name) = @_;
    return $catalog->cursor($name);
}

sub stream($) {
    my ($name) = @_;
    return cursor($name)->stream();
}

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

