package Stream::Utils;

use strict;
use warnings;

# ABSTRACT: common stream utilities

=head1 SYNOPSIS

    use Stream::Utils qw(process);

    process($in => $out); # read all data from input stream and write them into output stream, then commit both

=head1 DESCRIPTION

This module contains several non-OOP functions which are important enough to be exported.

=head1 FUNCTIONS

=over

=cut

use Carp;
use Scalar::Util qw(blessed);
use Params::Validate 0.83.0 qw(:all);
use Stream::Catalog;
use Yandex::Logger;
use Try::Tiny;
use Stream::Out::Anon;

use parent qw(Exporter);
our %EXPORT_TAGS = (
    vivify => [ map { "vivify_$_" } qw/ in out cursor filter storage pumper / ],
);
our @EXPORT_OK = (qw/ process pump catalog processor /, @{ $EXPORT_TAGS{vivify} });

our $catalog = Stream::Catalog->new; # global stream catalog, you usually need only one instance

=item B<catalog()>

Obtain catalog object. Catalog is almost always a singleton.

=cut
sub catalog() {
    return $catalog;
}

=item B<< process($in => $out) >>

=item B<< process($in => $out, $limit) >>

=item B<< process($in => $out, $options) >>

Process input stream into output stream. Both streams will be commited if processing was successful.

Third argument can be either integer C<$limit>, or hashref with some of following options:

=over

=item I<limit>

Process at most I<limit> items, or everything if I<limit> is not specified.

=item I<commit_step>

Commit both output and input streams every I<commit_step> items. By default, they'll be commited in the end of processing only.

=item I<chunk_size>

Force specific chunk size. Default is C<100>.

=item I<commit>

If set and false, input stream will not be commited.

=back

=cut
sub process($$;$) {
    my ($in, $out, $options) = validate_pos(@_, 1, 1, { optional => 1, type => SCALAR | HASHREF | UNDEF });
    my $limit;
    my $chunk_size = 100;
    my $commit_step; # TODO - choose some sane default?
    my $commit = 1;
    if (ref($options)) {
        my @list = ($options);
        $options = validate(@list, {
            limit => { type => SCALAR | UNDEF, regex => qr/^\d+$/, optional => 1 },
            commit_step => { type => SCALAR | UNDEF, regex => qr/^\d+$/, optional => 1 },
            chunk_size => { type => SCALAR | UNDEF, regex => qr/^\d+$/, optional => 1 },
            commit => { type => SCALAR | UNDEF, optional => 1 },
        });
        $limit = $options->{limit};
        $commit_step = $options->{commit_step};
        $chunk_size = $options->{chunk_size} if $options->{chunk_size};
        $commit = 0 if exists $options->{commit} and not $options->{commit};
    }
    else {
        $limit = $options;
    }

    $in = vivify_in($in);
    $out = vivify_out($out);

    {
        my $user;
        my $get_user = sub {
            $user = getpwuid($>) unless defined $user; # LDAP is sloooow
            return $user;
        };

        my $check_owner = sub {
            my $stream = shift;
            if (
                $stream->DOES('Stream::Role::Owned') and $stream->owner ne $get_user->()
                or $stream->DOES('Stream::Moose::Role::Owned') and $stream->owner_uid != $> # sorry, this role belongs to more/ source tree
            ) {
                die "Stream $stream belongs to ".$stream->owner.", not to ".$get_user->();
            }
        };
        # you can read from stream which belong to another user, as long as you don't try to commit it
        $check_owner->($in) if $commit;
        $check_owner->($out);
    }

    my $commit_both_sub = sub {
        $out->commit; # output is committed before input to make sure that all data was flushed down correctly
        return unless $commit;
        $in->commit;
    };

    my $i = 0;
    my $last_commit = 0;
    while (1) {
        if (defined $limit and $i + $chunk_size >= $limit) {
            $chunk_size = $limit - $i; # last chunk will be smaller than others
        }
        if ($commit_step and $i - $last_commit >= $commit_step) {
            $commit_both_sub->();
            $last_commit = $i;
        }
        my $chunk = $in->read_chunk($chunk_size);
        last unless $chunk;
        $out->write_chunk($chunk);
        $i += scalar(@$chunk);
        if (defined $limit and $i >= $limit) {
            last;
        }
    }
    $commit_both_sub->();
    return $i; # return number of actually processed items
}

=item C<processor(&)>

Creates anonymous output stream which calls specified callback on every C<write> call.

This function is deprecated. You should use C<code_out> from C<Stream::Simple> instead.

=cut
sub processor(&) {
    # TODO - remove from class methods with namespace::clean
    my ($callback) = @_;
    croak "Expected callback" unless ref($callback) eq 'CODE';
    # alternative constructor
    return Stream::Out::Anon->new($callback);
}

=item B<< pump($storage => $outs, $options) >>

Process storage into several outputs, each with its own cursor.

If some output streams will fail, error will be logged, but processing into other outputs will continue.

Options:

=over

=item I<limit>

Process at most these number of items for each output.

=item I<cursor_sub>

For each pair C<($storage,$out)> specified coderef will be called to construct cursor.

It's author's responsibility to make sure that resulting cursor can be used to construct input stream using C<$storage->stream($cursor)>.

=back

=cut
sub pump($$;$) {
    my ($storage, $outs, $options) = validate_pos(@_, 1, { type => ARRAYREF }, 0);

    unless (ref $options) {
        $options = { limit => $options };
    }
    $options = validate_with(
        params => $options,
        spec => {
            limit => { optional => 1 },
            cursor_sub => { type => CODEREF },
        }
    );

    $storage = vivify_storage($storage);

    my %stat = (
        ok      => 0,
        failed  => 0,
    );
    my @failures;

    for my $out (@$outs) {
        my $cursor = $options->{cursor_sub}->($storage, $out);
        my $in = $storage->stream($cursor);
        try {
            process($in => $out, $options->{limit});
            $stat{ok}++;
        }
        catch {
            ERROR $_;
            push @failures, $_; # TODO - return failures
            $stat{failed}++;
        };
    }
    return { stat => \%stat };
}

sub _vivify_any {
    my ($obj, $type) = @_;
    my $class = "Stream::".ucfirst($type);
    if (blessed($obj)) {
        unless ($obj->isa($class)) {
            croak "argument expected to be $class, you specified: '$obj'";
        }
        return $obj;
    }
    if (ref($obj) eq '') {
        # looking in catalog
        return $catalog->$type($obj);
    }
    croak "Wrong argument '$obj'";
}

=item B<< vivify_in($str_or_object) >>
=item B<< vivify_out($str_or_object) >>
=item B<< vivify_filter($str_or_object) >>
=item B<< vivify_pumper($str_or_object) >>
=item B<< vivify_cursor($str_or_object) >>
=item B<< vivify_storage($str_or_object) >>

Helpers which take objects from catalog if called with string, or return their parameter as is if it's object already.

=cut
sub vivify_in { _vivify_any(shift, 'in') }
sub vivify_out { _vivify_any(shift, 'out'); }
sub vivify_filter { _vivify_any(shift, 'filter'); }
sub vivify_pumper { _vivify_any(shift, 'pumper'); }
sub vivify_cursor { _vivify_any(shift, 'cursor'); }
sub vivify_storage { _vivify_any(shift, 'storage'); }

=back

=head1 SEE ALSO

If you want even shorter way to load all streams machinery, you can use L<Streams>.

=cut

1;
