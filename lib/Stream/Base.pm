package Stream::Base;

use strict;
use warnings;

use MRO::Compat;

=head1 NAME

Stream::Base - base class for In, Out and Filter classes

=head1 DESCRIPTION

C<Stream::In>, C<Stream::Out> and C<Stream::Filter> all inherit C<caps()> method from this class.

Caps, or capabilities, are optional features which stream class (or object) is capable of.
Since we want to have many various implementations of streams, it would be impossible to require them all to support all features, so they have to be optional.

Some utilities, like C<process()> function from L<Stream::Utils>, will make use of these capabilities and adapt their behavior appropriately.

=head1 METHODS

=over

=item B<cap($name)>

Get one capability value.

Currently it's just a shortcut to C<< caps()->{$name} >>, but if there'll be LOTS of caps, may be one day it'll be optimized somehow.

=cut

sub cap($$) {
    my ($self, $cap) = @_;
    return $self->caps()->{$cap};
}

=item B<caps()>

Get all capabilities as hashref.

Caps can be boolean, or have more complex values. To add more caps to your stream class, you should implement C<class_caps()> method. C<caps()> method will find all classes implementing C<class_caps()> method in your hierarchy, and merge their results appropriately.

=cut
sub caps($) {
    my $self = shift;
    my $linear = mro::get_linear_isa($self, 'c3');
    my $caps = {};
    for my $class (@$linear) {
        next unless $class->can('class_caps');
        my $class_caps = $class->class_caps;
        $caps = { %$caps, %$class_caps };
    }
    return $caps;
}

=item B<class_caps()>

This method should be implemented in your stream class if you want to add capabilities. It must return hashref.

=back

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=cut

1;

