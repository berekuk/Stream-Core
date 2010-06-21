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

    $self->{name2pp} = {};
    $self->{pp2name} = {};
    $self->{lazy} = {};
    $self->{stat} = {};

    return $self;
}

# load any object from file
sub _load {
    my ($self, $name, $path, $package_prefix) = @_;

    if ($self->{lazy}{$name}) {
        return $self->{lazy}{$name}->();
    }

    for my $dir (@$path) {
        my $file = "$dir/$name";
        if (-e $file) {
            my $fh = xopen('<', $file);
            my $content = do { local $/ = undef; <$fh> };

            # pp is short for "package postfix"
            my $pp ||= $self->{name2pp}{$name};
            unless (defined $pp) {
                $pp = $name;
                $pp =~ s/\W/_/;
                if ($self->{pp2name}{$pp}) {
                    # package name collsion (it can happen if one name is "blah-blah" and another is "blah_blah", for example)
                    # we call second one "blah_blah2" in this case
                    my $i = 2;
                    $i++ while $self->{pp2name}{"$pp$i"};
                }
                $self->{pp2name}{$pp} = $name;
                $self->{name2pp}{$name} = $pp;
            }

            my $stat = ++$self->{stat}{$name};
            $package_prefix = $package_prefix.$stat if $stat > 1;
            if ($stat == 100) {
                warn "100 evals of $file detected, please migrate it to lazy style instead to avoid memory leak";
            }

            $content = "package ${package_prefix}::$pp;\n# line 1 $dir/$name\n$content";
            my $object = eval $content;
            if ($@) {
                die "Failed to eval $file: $@";
            }
            if (ref $object and ref $object eq 'CODE') {
                # great, new-style file containing coderef which generates object
                $self->{lazy}{$name} = $object;
                return $self->{lazy}{$name}->();
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
    return $self->_load($name, $self->{cursor_dir}, 'Stream::Catalog::Cursor');
}

=item C<in($name)>

Loads input stream from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/in>.

=cut
sub in {
    my ($self, $name) = @_;
    return $self->_load($name, $self->{in_dir}, 'Stream::Catalog::In');
}

=item C<out($name)>

Loads output stream from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/out>.

=cut
sub out {
    my ($self, $name) = @_;
    return $self->_load($name, $self->{out_dir}, 'Stream::Catalog::Out');
}

=item C<filter($name)>

Loads filter from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/filter>.

=cut
sub filter {
    my ($self, $name) = @_;
    return $self->_load($name, $self->{filter_dir}, 'Stream::Catalog::Filter');
}

1;

