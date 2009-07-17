package Stream::Catalog::Plugin::File;

use strict;
use warnings;

=head1 NAME

Stream::Catalog::Plugin::File - catalog plugin which load objects from files

=head1 SYNOPSIS

    use Stream::Catalog::Plugin::File;
    $plugin = Stream::Catalog::Plugin::File->new;
    $cursor = $plugin->cursor("process_tinylinks");

=head1 METHODS

=over

=cut

use Yandex::X;
use base qw(Stream::Catalog::Plugin);

our $CURSOR_DIR =
    $ENV{STREAM_CURSOR_DIR} # TODO - rename in STREAM_CURSOR_PATH?
    || '/etc/stream/cursor';

our $IN_DIR =
    $ENV{STREAM_IN_DIR}
    || '/etc/stream/in';

our $OUT_DIR =
    $ENV{STREAM_OUT_DIR}
    || '/etc/stream/out';

=item C<new>

Constructs plugin.

=cut
sub new {
    my $class = shift;
    my $self = bless {
        cursor_dir => $CURSOR_DIR,
        in_dir => $IN_DIR,
        out_dir => $OUT_DIR,
    } => $class;
    for (qw/ cursor_dir in_dir out_dir /) {
        $self->{$_} = [ split /:/, $self->{$_} ];
    }
    return $self;
}

# load any object from file
sub _load {
    my ($self, $name, $path, $package) = @_;
    for my $dir (@$path) {
        if (-e "$dir/$name") {
            my $fh = xopen("$dir/$name");
            my $content;
            { local $/; $content = <$fh>; }
            $content = "package $package".int(rand(10 ** 6)).";\n# line 1 $dir/$name\n$content"; # FIXME - if file is loaded twice, shouldn't packages match?
            my $cursor = eval $content;
            if ($@) {
                die "Failed to eval '$content': $@";
            }
            return $cursor;
        }
    }
    return;
}

=item C<cursor($name)>

Loads cursor from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/cursor>.

=cut
sub cursor {
    my ($self, $name) = @_;
    return $self->_load($name, $self->{cursor_dir}, 'AnonCursor');
}

=item C<in($name)>

Loads input stream from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/in>.

=cut
sub in {
    my ($self, $name) = @_;
    return $self->_load($name, $self->{in_dir}, 'AnonIn');
}

=item C<out($name)>

Loads output stream from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/out>.

=cut
sub out {
    my ($self, $name) = @_;
    return $self->_load($name, $self->{out_dir}, 'AnonOut');
}

1;

