package Stream::Filter::Anon;

use strict;
use warnings;

use parent qw(Stream::Filter);
use Params::Validate qw(:all);

sub new {
    my $class = shift;
    my ($callback, $commit) = validate_pos(@_, { type => CODEREF }, { type => CODEREF | UNDEF, optional => 1 });
    my $self = $class->SUPER::new;
    $self->{callback} = $callback;
    $commit ||= sub {};
    $self->{commit} = $commit;
    return $self;
}

sub write {
    my ($self, $item) = @_;
    return $self->{callback}->($item);
}

sub commit {
    my ($self) = @_;
    return $self->{commit}->();
}

1;
