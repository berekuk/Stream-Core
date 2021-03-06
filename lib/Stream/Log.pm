package Stream::Log;

use strict;
use warnings;

# ABSTRACT: storage implemented as log.

=head1 DESCRIPTION

This class is similar to L<Stream::File>, but designed to work with logs (files which can rotate sometimes).

In future it'll probably contain some logic about safe writing into rotating logs.

=cut

use Params::Validate qw(:all);

use Stream::File;
use Digest::MD5 qw(md5_hex);
use parent qw(
    Stream::File
    Stream::Storage::Role::ClientList
    Stream::Role::Description
);
use Stream::Log::Cursor;
use Scalar::Util qw(blessed reftype);
use Carp;

sub new {
    my $class = shift;
    my ($fname) = validate_pos(@_, 1);
    my $self = $class->SUPER::new($fname, { lock => 1, safe => 1, reopen => 1 });
    return $self;
}

sub description {
    my $self = shift;
    return "log: ".$self->file;
}

=head1 METHODS

=over

=item B<in($cursor_or_client)>

=item B<in($cursor_or_client, $unrotate_params)>

Construct input stream from a client name or an L<Stream::Log::Cursor> object.

C<$unrotate_params> can contain more unrotate options.

=cut
sub in($$;$) {
    my $self = shift;
    my ($cursor_or_name, $unrotate_params) = validate_pos(@_, 1, {type => HASHREF, optional => 1});
    if (reftype($cursor_or_name)) {
        my $cursor = $cursor_or_name;
        croak "Stream::Log::Cursor expected" unless blessed($cursor) and $cursor->isa('Stream::Log::Cursor');
        return $cursor->stream($self, ($unrotate_params ? $unrotate_params : ()));
    }
    else {
        return $self->_in_by_name(@_);
    }

}

sub _in_by_name($$;$) {
    my $self = shift;
    my ($name, $unrotate_params) = validate_pos(@_, { type => SCALAR }, {type => HASHREF, optional => 1});

    my $file_md5 = md5_hex($self->file);
    my $name_md5 = md5_hex($name);
    my $old_posdir = $ENV{STREAM_LOG_POSDIR} || '/var/lib/stream'; # env variable is neccesary for tests
    my $old_posfile = "$old_posdir/$name_md5.$file_md5.pos";

    my $new_posdir = $ENV{STREAM_LOG_POSDIR} || '/var/lib/stream/log_pos';
    my $new_posfile = "$new_posdir/$file_md5.$name.pos";

    if (-e $old_posfile) {
        warn "Old posfile $old_posfile found, renaming according to new naming policy";
        rename $old_posfile => $new_posfile or die "Can't rename $old_posfile to $new_posfile: $!";
    }

    my $cursor = Stream::Log::Cursor->new({ LogFile => $self->file, PosFile => $new_posfile });
    return $cursor->stream($self, ($unrotate_params ? $unrotate_params : ()));
}

sub client_names {
    my $self = shift;
    my $file_md5 = md5_hex($self->file);
    my $posdir = $ENV{STREAM_LOG_POSDIR} || '/var/lib/stream/log_pos';
    my @posfiles = glob "$posdir/$file_md5.*.pos";
    my @names;
    for my $posfile (@posfiles) {
        if ($posfile =~ m{^\Q$posdir\E/\Q$file_md5\E\.(.*)\.pos$}) {
            push @names, $1;
        }
        else {
            warn "Strange posfile $posfile, looks like internal error";
        }
    }
    return @names;
}

=back

=cut

1;
