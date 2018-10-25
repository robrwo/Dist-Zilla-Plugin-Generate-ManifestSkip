package Dist::Zilla::Plugin::Generate::ManifestSkip;

use v5.10;

use Moose;
extends 'Dist::Zilla::Plugin::ManifestSkip';
with qw/
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::FilePruner
  /;

use List::Util  1.33 qw/ any /;
use Module::Manifest::Skip ();
use MooseX::MungeHas;
use Types::Standard -types;

use namespace::autoclean;

our $VERSION = 'v0.1.0';

sub mvp_multivalue_args { qw/ add remove / }

has mms => (
    is => 'lazy',
    isa => InstanceOf['Module::Manifest::Skip'],
    builder => sub { Module::Manifest::Skip->new },
    init_arg => undef,
);

has add => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
);

has remove => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
);

sub gather_files {
    my ($self) = @_;

    my $zilla = $self->zilla;

    my @files = @{ $zilla->files };
    my $mms = $self->mms;

    $mms->text;

    $mms->add( "# Added by " . __PACKAGE__ );
    $mms->add( '\.build/' );
    $mms->add( $zilla->name . '-.*/' );
    $mms->add( $zilla->name . '-.*\.tar\.gz' );

    $mms->remove('^MANIFEST\.SKIP$');
    $mms->remove('^dist.ini$');
    $mms->remove('^weaver.ini$');

    $mms->add('cpanfile\.snapshot$') if any { $_->name eq 'cpanfile' } @files;
    $mms->add('_alien/') if any { $_->name eq 'alienfile' } @files;

    foreach my $file (@{ $self->add }) {
        $mms->add($file);
    }

    foreach my $file (@{ $self->remove }) {
        $mms->remove($file);
    }

    $self->log([ 'writing %s', $self->skipfile ]);

    require Dist::Zilla::File::InMemory;
    $self->add_file(
        Dist::Zilla::File::InMemory->new(
            {
                name    => $self->skipfile,
                content => $mms->text,
            }
        )
    );

    return;
}

__PACKAGE__->meta->make_immutable;
