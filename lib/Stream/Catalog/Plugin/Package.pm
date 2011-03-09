package Stream::Catalog::Plugin::Package;

use strict;
use warnings;

use parent qw(Stream::Catalog::Plugin);

sub _gen_method {
    my ($type) = @_;
    return sub {
        my ($self, $name) = @_;
        return unless $name =~ /::/;
        return if $name =~ / /; # invalid name anyway
        my $result = eval "use $name; 1";
        unless ($result) {
            if ($@ =~ /^Can't locate/) {
                return; # TODO - negative cache?
            }
            die $@;
        }
        my $object = $name->new;
        unless ($object->isa('Stream::'.ucfirst($type))) {
            die "Can't construct $name, '$object' has invalid type";
        }
        return $object;
    };
}

our @TYPES = qw/ cursor in out filter pumper /;
{
    no strict 'refs';
    for my $type (@TYPES) {
        *{$type} = _gen_method($type);
    }
}
1;

