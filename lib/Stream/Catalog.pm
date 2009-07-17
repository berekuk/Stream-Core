package Stream::Catalog;

use strict;
use warnings;

=head1 NAME

Stream::Catalog - registry of all streams

=head1 SYNOPSIS

    use Stream::Catalog;

    $catalog = new Stream::Catalog;
    $stream = $catalog->stream("enqueue");

=cut

use Stream::Catalog::Out::File;
use Stream::Catalog::In::File;
use Stream::Catalog::Cursor::File;

sub new ($) {
    my ($class) = @_;
    return bless {} => $class;
}

{
    my $file_module = Stream::Catalog::Out::File->new;
    sub out_modules ($$) {
        return $file_module;
    }
}
{
    my $file_module = Stream::Catalog::In::File->new;
    sub in_modules ($$) {
        return $file_module;
    }
}

{
    my $cursor_module = Stream::Catalog::Cursor::File->new;
    sub cursor_modules ($$) {
        return $cursor_module;
    }
}

sub out ($$) {
    my ($self, $name) = @_;
    for my $module ($self->out_modules) {
        my $out = $module->out($name);
        if ($out) {
            return $out;
        }
    }
    die "Can't find output stream by name '$name'";
}

sub in ($$) {
    my ($self, $name) = @_;
    for my $module ($self->in_modules) {
        my $stream = $module->in($name);
        if ($stream) {
            return $stream;
        }
    }
    my $cursor = $self->cursor($name) or die "Can't find input stream by name '$name'";
    return $cursor->stream();
}

# just an alias to out() method
# TODO - since Out stream must have special abilities to be storage, we should check for it's type
sub storage {
    goto &out;
}

sub cursor ($$) {
    my ($self, $name) = @_;

    for my $module ($self->cursor_modules) {
        my $cursor = $module->cursor($name);
        if ($cursor) {
            return $cursor;
        }
    }
    die "Can't find cursor by name '$name'";
}

=head1 SEE ALSO

L<Stream::Utils> for storage() sub

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

