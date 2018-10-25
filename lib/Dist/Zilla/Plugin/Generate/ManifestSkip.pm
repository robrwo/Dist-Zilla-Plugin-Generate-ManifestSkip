package Dist::Zilla::Plugin::Generate::ManifestSkip;

use v5.10;

use Moose;
with qw/
    Dist::Zilla::Role::FileGatherer
  /;

use List::Util  1.33 qw/ any /;
use Module::Manifest::Skip ();
use MooseX::MungeHas;
use Types::Standard -types;

use namespace::autoclean;

has mms => (
    is => 'lazy',
    isa => InstanceOf['Module::Manifest::Skip'],
    builder => sub { Module::Manifest::Skip->new },
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

    # TODO: apply user adds and removes

    require Dist::Zilla::File::InMemory;
    $self->add_file(
        Dist::Zilla::File::InMemory->new(
            {
                name    => 'MANIFEST.SKIP',
                content => $mms->text,
            }
        )
    );

    return;
}

__PACKAGE__->meta->make_immutable;
