package Plack::Middleware::Dev::Compass;

use strict;
use warnings;

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw/compass_project target_directory sass_directory/;
use File::Find::Rule;

my $compass_bin;

sub call {
  my ( $self, $env ) = @_;

  goto NOOP unless $ENV{PLACK_ENV} and $ENV{PLACK_ENV} eq 'development';

  $compass_bin ||= do {
    my $finder = File::Find::Rule->new;
    $finder->executable->file->name( 'compass' );
    my $binary = $finder->start( '/var/lib/gems/' );
    $binary->match;
  };

  die 'Compass executable not found'
    unless $compass_bin and -x $compass_bin;

  my $project_root = $self->compass_project
    or die "project_root not specified";

  die "Invalid Compass project ${project_root}"
    unless -d $project_root and -r $project_root
      and -r File::Spec->catfile( $project_root, 'config.rb' );

  my $sass_root = $self->sass_directory;
  my $css_root  = $self->target_directory;

  die "Invalid SASS directory ${sass_root}"
    if $sass_root and not ( -d $sass_root and -r $sass_root );

  die "Invalid CSS directory ${css_root}"
    if $css_root and not ( -d $css_root and -r $css_root );


  system( $compass_bin, compile => (
    $self->compass_project,
    $sass_root ? ( '--sass-dir' => $sass_root ) : (),
    $css_root  ? ( '--css-dir'  => $css_root  ) : (),
  ));

 NOOP:

  return $self->app->( $env );
}

1;
