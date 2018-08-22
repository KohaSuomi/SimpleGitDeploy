package SimpleGitDeploy::Controller::Deployment;
use Mojo::Base 'Mojolicious::Controller';
use SimpleGitDeploy::Model::RemoteDeploy;
use SimpleGitDeploy::Model::ServerDeploy;
use SimpleGitDeploy::Model::SendMessage;

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
    my $message;
      
    if ($branch && $host && $token) {

      my $deploy = SimpleGitDeploy::Model::RemoteDeploy->new({config => $c->app->config});

      if (defined $ref && $ref eq $branch && $event eq "push") {

        $message = $deploy->start_deployment($body, $branch, $host, $token);

      } elsif ($event eq "deployment") {

        $message = $deploy->process_deployment($body, $branch, $host, $token);

      } elsif ($event eq "deployment_status" && $body->{"deployment_status"}->{"state"} eq "processing") {

        my $server = SimpleGitDeploy::Model::ServerDeploy->new({config => $c->app->config});
        my $status = $server->pull;

        $message = $status;

        my $sender = SimpleGitDeploy::Model::SendMessage->new({config => $c->app->config});
        $sender->send_message($status);

      }
      
      if ($message) {
        $c->render(status => 200, openapi => {event => $event, message => $message});
      } else {
        $c->render(status => 202, openapi => {event => $event, message => "Accepted"});
      }
      

    } else {
      $c->app->log->error("Configuration file missing");
      $c->render(status => 501, openapi => {event => $event, message => 'Not implemented'});
    }
  
  } catch {
    my $e = $_;
    $c->app->log->error($e);
    $c->render(status => 500, openapi => {error => $e});
  }
}

1;
