package Stream::Catalog;

use strict;
use warnings;

use Yandex::Version '{{DEBIAN_VERSION}}';

=head1 NAME

Stream::Catalog - registry of all streams

=head1 SYNOPSIS

    use Stream::Catalog;

    $catalog = new Stream::Catalog;
    $output_stream = $catalog->out("enqueue");
    $input_stream = $catalog->in("bulca.storelog");
    $storage = $catalog->storage("bulca.storelog");

=head1 METHODS

=over

=cut

use Stream::Catalog::Plugin::File;
use Stream::Catalog::Plugin::Memory;

=item C<new()>

Constructor.

Usually you'll want to obtain singleton catalog object using C<catalog()> from L<Stream::Utils> instead.

=cut
sub new ($) {
    my ($class) = @_;
    my $self = bless {
        plugins => [ Stream::Catalog::Plugin::File->new ],
    } => $class;
    $self->{memory_plugin} = Stream::Catalog::Plugin::Memory->new();
    push @{$self->{plugins}}, $self->{memory_plugin};
    return $self;
}

sub _plugins ($) {
    my $self = shift;
    return @{$self->{plugins}};
}

=item C<out($name)>

Get output stream by name.

=cut
sub out ($$) {
    my ($self, $name) = @_;
    for my $module ($self->_plugins) {
        my $out = $module->out($name);
        if ($out) {
            return $out;
        }
    }
    die "Can't find output stream by name '$name'";
}

=item C<filter($name)>

Get filter by name.

=cut
sub filter ($$) {
    my ($self, $name) = @_;
    for my $module ($self->_plugins) {
        my $filter = $module->filter($name);
        if ($filter) {
            return $filter;
        }
    }
    die "Can't find filter by name '$name'";
}

=item C<in($name)>

Get input stream by name. If stream doesn't exist, but cursor with the same name exists, return stream associated with this cursor instead.

=cut
sub in ($$) {
    my ($self, $name) = @_;
    for my $module ($self->_plugins) {
        my $stream = $module->in($name);
        if ($stream) {
            return $stream;
        }
    }
    my $cursor = $self->cursor($name) or die "Can't find input stream by name '$name'";
    return $cursor->stream();
}

=item C<storage($name)>

Just an alias to out() method.

=cut
sub storage {
    # TODO - since Out stream must have special abilities to be storage, we should check for it's type
    goto &out;
}

=item C<cursor($name)>

Get cursor by name.

=cut
sub cursor ($$) {
    my ($self, $name) = @_;

    for my $module ($self->_plugins) {
        my $cursor = $module->cursor($name);
        if ($cursor) {
            return $cursor;
        }
    }
    die "Can't find cursor by name '$name'";
}

=item C<bind_in($name, $object)>

Bind existing input stream to given name.

=cut
sub bind_in($$$) {
    my ($self, $name, $object) = @_;
    $self->{memory_plugin}->bind($name, $object);
}

=back

=head1 SEE ALSO

L<Stream::Utils> for storage() sub

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

