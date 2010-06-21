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
use File::Find;
use parent qw(Stream::Catalog::Plugin);

our @TYPES = qw/ cursor in out filter pumper /;
our %TYPE2DIR;

for my $type (@TYPES) {
    my $TYPE = uc($type);
    my $dir = "/etc/stream/$type:/usr/share/stream/$type";

    my $type_env = $ENV{"STREAM_${TYPE}_DIR"} || $ENV{"STREAM_${TYPE}_PATH"};
    if ($type_env) {
        warn "STREAM_*_DIR vars are deprecated, use STREAM_PATH instead";
        $dir = "$type_env:$dir";
    }

    my $env = $ENV{STREAM_DIR};
    if ($ENV{STREAM_PATH}) {
        $env = $ENV{STREAM_PATH}; # unlike STREAM_DIR, STREAM_PATH completely overrides default paths
        $dir = '';
    }
    if ($env) {
        for (reverse split /:/, $env) {
            $dir = "$_/$type:$dir";
        }
    }
    $TYPE2DIR{$type} = $dir;
}

=item C<new>

Constructs plugin.

=cut
sub new {
    my $class = shift;
    my $self = bless {} => $class;
    for (@TYPES) {
        $self->{ $_."_dir" } = [ split /:/, $TYPE2DIR{$_} ];
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

=item C<pumper($name)>

Loads pumper from file named C<$name> in catalog dir. Dir defaults to C</etc/stream/pumper>.

=cut
sub pumper {
    my ($self, $name) = @_;
    return $self->_load($name, $self->{pumper_dir}, 'Stream::Catalog::Pumper');
}

sub list {
    my ($self, $type) = @_;

    my $path = $self->{$type."_dir"} or die "Unknown type $type";
    my @files;
    for my $dir (@$path) {
        next unless -d $dir;
        find({
            wanted => sub {
                return unless -f;
                my $file = $File::Find::name;
                $file = File::Spec->abs2rel($file, $dir);
                push @files, $file;
            },
            no_chdir => 1,
        }, $dir);
    }
    return @files;
}

1;

