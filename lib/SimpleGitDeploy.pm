package SimpleGitDeploy;
use Mojo::Base 'Mojolicious';

use Mojo::Log;

# This method will run once at server start
sub startup {
  my $self = shift;

  my $config = $self->plugin('Config');
  my $log = Mojo::Log->new(path => $config->{logs}, level => 'debug');
  $self->config($config);
  $self->log($log);

  $self->plugin(OpenAPI => {spec => $self->static->file("api.yaml")->path});
}
1;