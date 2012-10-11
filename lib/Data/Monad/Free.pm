package Data::Monad::Free;
use strict;
use warnings;
use parent "Data::Monad::Base::Monad";
use Carp ();

sub map_function(&) {
    my $f = shift;
    sub {
        my $fx = shift;
        $fx->map($f);
    };
}

sub new {
    my ($class, $n, @v) = @_;
    bless {n => $n, values => \@v} => $class;
}

sub unit {
    my ($class, @v) = @_;
    $class->new(0, @v);
}

sub flat_map {
    my ($self, $f) = @_;

    my $n = $self->{n};

    my $m;
    my $unwrap = sub {
        my @x = @_;
        my $mx = $f->(@x);

        if (defined $m) {
            die if $m != $mx->{n};
        } else {
            $m = $mx->{n};
        }

        return @{$mx->{values}};
    };
    $unwrap = map_function \&$unwrap for 1 .. $n;

    my @unwraped_values = $unwrap->(@{$self->{values}});
    defined $m or die "FIXME: can't unwrap Free for this monad";

    return (ref $self)->new($n + $m, @unwraped_values);
}

1;
