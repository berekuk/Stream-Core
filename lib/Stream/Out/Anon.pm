package Stream::Out::Anon;

# This class is deprecated. You should never use it directly. (It is used by deprecated Stream::Out::processor() function).
# There is also a complete copy-paste of it in Steam::Simple::CodeOut module.

use strict;
use warnings;

use parent qw(Stream::Out);

sub new {
    my ($class, $callback) = @_;
    my $self = $class->SUPER::new;
    $self->{callback} = $callback;
    return $self;
}

sub write {
    my ($self, $item) = @_;
    $self->{callback}->($item);
}

1;
