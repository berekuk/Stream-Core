package Stream::Catalog;

use strict;
use warnings;

# ABSTRACT: registry of all streams

=head1 SYNOPSIS

    use Stream::Catalog;

    $catalog = Stream::Catalog->new; # although usually you'll want catalog() from Stream::Utils
    $output_stream = $catalog->out("enqueue");
    $input_stream = $catalog->in("bulca.storelog");
    $storage = $catalog->storage("bulca.storelog");

=head1 METHODS

=over

=cut

use namespace::autoclean;

use Stream::Catalog::Plugin::File;
use Stream::Catalog::Plugin::Package;
use Stream::Catalog::Plugin::Memory;

use Stream::Catalog::Utils qw(types);

=item C<new()>

Constructor.

Usually you'll want to obtain singleton catalog object using C<catalog()> from L<Stream::Utils> instead.

=cut
sub new ($) {
    my ($class) = @_;
    my $self = bless {
        plugins => [
            Stream::Catalog::Plugin::File->new,
            Stream::Catalog::Plugin::Package->new,
        ],
    } => $class;
    $self->{memory_plugin} = Stream::Catalog::Plugin::Memory->new();
    unshift @{$self->{plugins}}, $self->{memory_plugin};
    return $self;
}

sub _plugins ($) {
    my $self = shift;
    return @{$self->{plugins}};
}

sub _any {
    my ($self, $type, $name) = @_;
    for my $module ($self->_plugins) {
        my $object = $module->$type($name);
        if ($object) {
            return $object;
        }
    }
    return;
}

=item C<out($name)>

Get output stream by name.

=cut
sub out ($$) {
    my ($self, $name) = @_;
    return $self->_any('out', $name) || die "Can't find output stream by name '$name'";
}

=item C<filter($name)>

Get filter by name.

=cut
sub filter ($$) {
    my ($self, $name) = @_;
    $self->_any('filter', $name) || die "Can't find filter by name '$name'";
}

=item C<in($name)>

Get input stream by name.

If stream doesn't exist, but cursor with the same name exists, return stream associated with this cursor instead.

If name looks like C<aaa[bbb]>, and no input stream found, this method will try to find storage with name C<aaa> and then get input stream from it using C<stream("bbb"> method.

=cut
sub in ($$) {
    my ($self, $name) = @_;
    my $in = $self->_any('in', $name);
    return $in if $in;

    if (my ($storage, $in_name) = $name =~ /(.+)\[(.*)\]$/) {
        return $self->storage($storage)->stream($in_name);
    }

    my $cursor = $self->cursor($name); # TODO - get rid of cursors in catalog as a separate type
    die "Can't find input stream by name '$name'" unless $cursor;
    return $cursor->stream();
}

=item C<storage($name)>

Just an alias to out() method.

=cut
sub storage {
    my ($self, $name) = @_;
    my $storage = $self->out($name);
    # TODO - since Out stream must have special abilities to be storage, we should check for its type
    return $storage;
}

=item C<cursor($name)>

Get cursor by name.

=cut
sub cursor ($$) {
    my ($self, $name) = @_;
    # TODO - get rid of cursors in catalog as a separate type
    $self->_any('cursor', $name) || die "Can't find cursor by name '$name'";
}

=item C<format($name)>

Get formatter by name.

=cut
sub format ($$) {
    my ($self, $name) = @_;
    $self->_any('format', $name) || die "Can't find format by name '$name'";
}

=item C<pumper($name)>

Get pumper by name.

=cut
sub pumper ($$) {
    my ($self, $name) = @_;
    # TODO - do we need pumpers in streams core? they are not used by now, Yandex::Pumper is a separate entity.
    $self->_any('pumper', $name) || die "Can't find pumper by name '$name'";
}

=item B<list_in()>

=item B<list_out()>

=item B<list_cursor()>

=item B<list_filter()>

=item B<list_pumper()>

=item B<list_format()>

List all objects of one type.

=cut
sub _list_any {
    my ($self, $type) = @_;
    my $method = "list_$type";
    my %uniq;
    for my $module ($self->_plugins) {
        my @list = $module->list($type);
        $uniq{$_}++ for @list;
    }
    return keys %uniq;
}

for my $type (types()) {
    no strict 'refs';
    *{"list_$type"} = sub {
        shift()->_list_any($type);
    };
}

=item C<bind_in($name => $object)>

Bind existing input stream to given name.

Binding happens in-memory and will be lost when catalog object will be destroyed.

=cut
sub bind_in($$$) {
    my ($self, $name, $object) = @_;
    $self->{memory_plugin}->bind_in($name => $object);
}

=item C<bind_out($name => $object)>

Bind output stream to given name.

=cut
sub bind_out($$$) {
    my ($self, $name, $object) = @_;
    $self->{memory_plugin}->bind_out($name => $object);
}

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;
