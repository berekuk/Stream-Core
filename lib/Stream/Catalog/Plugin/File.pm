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
use parent qw(Stream::Catalog::Plugin);

our ($CURSOR_DIR, $IN_DIR, $OUT_DIR, $FILTER_DIR);
for my $type (qw/ cursor in out filter /) {
    my $TYPE = uc($type);
    my $dir = "/etc/stream/$type";
    $dir = $ENV{"STREAM_${TYPE}_DIR"}.":".$dir if $ENV{"STREAM_${TYPE}_DIR"}; # TODO - rename in STREAM_${TYPE}_PATH?
    if ($ENV{STREAM_DIR}) {
        for (reverse split /:/, $ENV{STREAM_DIR}) {
            $dir = "$_/$type:$dir";
        }
    }
    no strict 'refs';
    ${"${TYPE}_DIR"} = $dir;
}

=item C<new>

Constructs plugin.

=cut
sub new {
    my $class = shift;
    my $self = bless {
        cursor_dir => $CURSOR_DIR,
        in_dir => $IN_DIR,
        out_dir => $OUT_DIR,
        filter_dir => $FILTER_DIR,
    } => $class;
    for (qw/ cursor_dir in_dir out_dir filter_dir /) {
        $self->{$_} = [ split /:/, $self->{$_} ];
    }
    return $self;
}

# load any object from file
sub _load {
    my ($self, $name, $path, $package) = @_;
    for my $dir (@$path) {
        my $file = "$dir/$name";
        if (-e $file) {
            my $fh = xopen($file);
            my $content;
            { local $/; $content = <$fh>; }
            $content = "package $package".int(rand(10 ** 6)).";\n# line 1 $dir/$name\n$content"; # FIXME - if file is loaded twice, shouldn't packages match?
            my $object = eval $content;
            if ($@) {
                die "Failed to eval $file: $@";
            }
            return $object;
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

=item C<filter($name)>

Loads filter from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/filter>.

=cut
sub filter {
    my ($self, $name) = @_;
    return $self->_load($name, $self->{filter_dir}, 'AnonFilter');
}

1;

