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

use Stream::Catalog::Storage::File;
use Stream::Catalog::Cursor::File;

sub new ($) {
    my ($class) = @_;
    return bless {} => $class;
}

{
    my $file_module = Stream::Catalog::Storage::File->new;
    sub storage_modules ($$) {
        return $file_module;
    }
}

{
    my $cursor_module = Stream::Catalog::Cursor::File->new;
    sub cursor_modules ($$) {
        return $cursor_module;
    }
}

sub storage ($$) {
    my ($self, $name) = @_;
    for my $module ($self->storage_modules) {
        my $storage = $module->storage($name);
        if ($storage) {
            return $storage;
        }
    }
    die "Can't find storage by name '$name'";
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

