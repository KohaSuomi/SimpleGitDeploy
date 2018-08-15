package SimpleGitDeploy::Controller::Deployment;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::UserAgent;

use JSON;
use Try::Tiny;

sub event {
  my $c = shift->openapi->valid_input or return;

  try {
    my $body =  $c->req->body;
    my $event = $c->req->headers->{"headers"}->{"x-github-event"};
    $body = from_json($body);
    my $branch = $c->app->config->{"branch"};
    my $host = $c->app->config->{"host"};
    if (@{$event} eq 'push' && $body->{ref} eq "/refs/heads/".$branch) {
      $c->start_deployment($body, $branch, $host);
    }
    $c->render(status => 200, openapi => {message => "success"});
  } catch {
    my $e = $_;
    $c->app->log->error($e);
    $c->render(status => 500, openapi => {error => $e});
  }
}

sub start_deployment {
  my $self = shift;
  my ($push_request, $branch, $host) = @_;

  $self->app->log->debug('Starting the deployment');

  my $user = $push_request->{"sender"}->{"login"};

  my $payload = {environment => $branch, deploy_user => $user};
  my $params = {ref => $branch, payload => $payload, description => "Deploying to production server"};

  my $path = $host.'/repos/'.$push_request->{"repository"}->{"full_name"}.'/deployments';

  $self->create_deployment($path, $params);
  
}

sub create_deployment {
  my $self = shift;
  my ($path, $params) = @_;
  try {
    my $ua = Mojo::UserAgent->new;
    print Data::Dumper::Dumper $params;
    my $tx = $ua->post($path => json => $params);
  } catch {
    $self->app->log->error($_);
  }
}

1;
