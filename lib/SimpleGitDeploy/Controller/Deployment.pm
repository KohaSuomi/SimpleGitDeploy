package SimpleGitDeploy::Controller::Deployment;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::UserAgent;
use SimpleGitDeploy::Model::ServerDeploy;

use JSON;
use Try::Tiny;

sub event {
  my $c = shift->openapi->valid_input or return;
  try {
    my $body =  $c->req->body;
    my $event = shift @{$c->req->headers->{"headers"}->{"x-github-event"}};
    $body = from_json($body);
    my $branch = $c->app->config->{"branch"};
    my $host = $c->app->config->{"host"};
    my $token = $c->app->config->{"token"};
    my $ref = (split '/', $body->{ref})[-1];
    if ($ref eq $branch && $event eq "push") {
      $c->start_deployment($body, $branch, $host, $token);
    } elsif ($event eq "deployment") {
      $c->process_deployment($body, $branch, $host, $token);
    } elsif ($event eq "deployment_status") {
      $c->SimpleGitDeploy::Model::ServerDeploy::push;
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
  my ($push_request, $branch, $host, $token) = @_;

  $self->app->log->debug('Starting the deployment');

  my $user = $push_request->{"sender"}->{"login"};

  my $payload = {deploy_state => 'pending', deploy_user => $user};
  my $params = {ref => $branch, payload => $payload, description => "Deploying to production server"};

  my $path = $host.'/repos/'.$push_request->{"repository"}->{"full_name"}.'/deployments';

  $self->send_deployment($path, $token, $params);
  
}

sub process_deployment {
  my $self = shift;
  my ($deployment, $branch, $host, $token) = @_;

  $self->app->log->debug('Processing the deployment');

  my $deployment_id = $deployment->{"deployment"}->{"id"};

  my $state = $deployment->{"deployment"}->{"payload"}->{"deploy_state"};

  my $params;

  if($state) {
    $params = {state => $state, description => "Pending deployment"};
  } else {
    $params = {state => "success", description => "Deployment succesfully finished!"};
  }

  my $path = $host.'/repos/'.$deployment->{"repository"}->{"full_name"}.'/deployments/'.$deployment_id.'/statuses';

  $self->send_deployment($path, $token, $params);

}

sub send_deployment {
  my $self = shift;
  my ($path, $token, $params) = @_;
  try {
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->post($path => {Authorization => 'token '.$token} => json => $params);
    print Data::Dumper::Dumper $tx->res->body;
  } catch {
    $self->app->log->error($_);
  }
}

1;
