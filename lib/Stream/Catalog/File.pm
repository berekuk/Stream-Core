package Stream::Catalog::File;

use strict;
use warnings;

=head1 NAME

Stream::Catalog::File - base class for catalog plugins which loads any objects from files

=head1 METHODS

=over

=cut

use Yandex::X;
use Params::Validate qw(:all);

=item C<new($params)>

Constructs plugin.

Parameters:

=over

=item I<path>

Colon-separated list of dirs from which file can be loaded.

=item I<package>

String with prefix of anonymous package which will be created for each loaded file.

=back

=cut
sub new {
    my $class = shift;
    my $props = validate(@_, {
        path => 1,
        package => { type => SCALAR, default => 'Anon' },
    });
    $props->{path} = [ split /:/, $props->{path} ];
    return bless $props => $class;
}

=item C<load($name)>

Loads object from file named C<$name> in path.

=cut
sub load {
    my ($self, $name) = @_;
    for my $dir (@{$self->{path}}) {
        if (-e "$dir/$name") {
            my $fh = xopen("$dir/$name");
            my $content;
            { local $/; $content = <$fh>; }
            $content = "package ".$self->{package}.int(rand(10 ** 6)).";\n# line 1 $dir/$name\n$content"; # FIXME - if file is loaded twice, should packages match?
            my $cursor = eval $content;
            if ($@) {
                die "Failed to eval '$content': $@";
            }
            return $cursor;
        }
    }
    return;
}

1;

