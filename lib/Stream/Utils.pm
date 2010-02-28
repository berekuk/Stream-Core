package Stream::Utils;

use strict;
use warnings;

use Yandex::Version '{{DEBIAN_VERSION}}';

=head1 NAME

Stream::Utils - common stream utilities

=head1 SYNOPSIS

    use Stream::Utils qw(process);

    process($in => $out); # read all data from input stream and write them into output stream, then commit both

=head1 DESCRIPTION

This module contains several non-OOP functions which are important enough to be exported.

=head1 FUNCTIONS

=over

=cut

use Carp;
use Scalar::Util qw(blessed);
use Params::Validate 0.83.0 qw(:all);
use Stream::Catalog;
use Yandex::Logger;

use base qw(Exporter);
our @EXPORT_OK = qw/process pump storage cursor stream catalog /;

our $catalog = Stream::Catalog->new; # global stream catalog, you usually need only one instance

=item B<catalog()>

Obtain catalog object. Catalog is almost always a singleton.

=cut
sub catalog() {
    return $catalog;
}

=item B<< process($in => $out) >>

=item B<< process($in => $out, $limit) >>

Process input stream into output stream. Both streams will be commited if processing was successful.

Process at most C<$limit> items, or everything if C<$limit> is not specified.

=cut
sub process($$;$) {
    my ($in, $out, $limit) = validate_pos(@_, 1, 1, { optional => 1, regex => qr/^\d*$/ });

    if (blessed($in)) {
        unless ($in->isa('Stream::In')) {
            croak "first argument expected to be Stream::In, you specified: '$in'";
        }
    }
    elsif (ref($in) eq '') {
        # looking in catalog
        $in = $catalog->in($in);
    }
    else {
        croak "Wrong argument '$in'";
    }

    if (blessed($out)) {
        unless ($out->isa('Stream::Out')) {
            croak "first argument expected to be Stream::Out, you specified: '$out'";
        }
    }
    elsif (ref($out) eq '') {
        # looking in catalog
        $out = $catalog->out($out);
    }
    else {
        croak "Wrong argument '$in'";
    }

    my $i = 0;
    my $chunk_size = 100;
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
    return $i; # return number of actually processed items
}

=item B<< pump($storage => $outs, $options) >>

Process storage into several outputs, each with its own cursor.

If some output streams will fail, error will be logged, but processing into other outputs will continue.

Options:

=over

=item I<limit>

Process at most these number of items for each output.

=item I<cursor_sub>

For each pair C<($storage,$out)> specified coderef will be called to construct cursor.

It's author's responsibility to make sure that resulting cursor can be used to construct input stream using C<$storage->stream($cursor)>.

=back

=cut
sub pump($$;$) {
    my ($storage, $outs, $options) = validate_pos(@_, 1, { type => ARRAYREF }, 0);

    unless (ref $options) {
        $options = { limit => $options };
    }
    $options = validate_with(
        params => $options,
        spec => {
            limit => { optional => 1 },
            cursor_sub => { type => CODEREF },
        }
    );

    if (blessed($storage)) {
        unless ($storage->isa('Stream::Storage')) {
            croak "first argument expected to be Stream::Storage, you specified: '$storage'";
        }
    }
    else {
        $storage = $catalog->storage($storage);
    }

    my %stat = (
        ok      => 0,
        failed  => 0,
    );
    my @failures;

    for my $out (@$outs) {
        my $cursor = $options->{cursor_sub}->($storage, $out);
        my $in = $storage->stream($cursor);
        eval {
            process($in => $out, $options->{limit});
        };
        if ($@) {
            ERROR $@;
            push @failures, $@; # TODO - return failures
            $stat{failed}++;
        }
        else {
            $stat{ok}++;
        }
    }
    return { stat => \%stat };
}

=item B<storage($name)>

Get storage by name.

DEPRECATED! Use catalog->out instead.

=cut
sub storage($) {
    my ($name) = @_;
    return $catalog->storage($name);
}

=item B<cursor($name)>

Get cursor by name.

DEPRECATED! Use catalog->cursor instead.

=cut
sub cursor($) {
    my ($name) = @_;
    return $catalog->cursor($name);
}

=item B<stream($name)>

Get input stream by name.

DEPRECATED! Use catalog->in instead.

=cut
sub stream($) {
    my ($name) = @_;
    return $catalog->in($name);
}

=back

=head1 SEE ALSO

If you want even shorter way to load all streams machinery, you can use L<Streams>.

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

