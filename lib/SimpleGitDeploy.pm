package SimpleGitDeploy;
use Mojo::Base 'Mojolicious';

use Mojo::Log;

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->mode("production");
  my $config = $self->plugin('Config');
  my $log = Mojo::Log->new(path => $config->{logs}, level => $config->{log_level});
  $self->config($config);
  $self->log($log);

  $self->plugin(OpenAPI => {spec => $self->static->file("api.yaml")->path});
}
1;