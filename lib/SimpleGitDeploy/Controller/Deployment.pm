package SimpleGitDeploy::Controller::Deployment;
use Mojo::Base 'Mojolicious::Controller';
use SimpleGitDeploy::Model::RemoteDeploy;
use SimpleGitDeploy::Model::ServerDeploy;
use SimpleGitDeploy::Model::SendMessage;

use Mojo::JSON qw(decode_json encode_json);
use Try::Tiny;
use Digest::SHA;

sub event {
  my $c = shift->openapi->valid_input or return;

  try {
    my $body =  $c->req->body;
    my $event = shift @{$c->req->headers->{"headers"}->{"x-github-event"}};
    my $signature = shift @{$c->req->headers->{"headers"}->{"x-hub-signature"}};
    my $secret = $c->app->config->{"secret"};
    $secret = "sha1=".Digest::SHA::hmac_sha1_hex($body, $secret);
    $body = decode_json($body);
    my $branch = $c->app->config->{"branch"};
    my $host = $c->app->config->{"host"};
    my $token = $c->app->config->{"token"};
    my $ref = (split '/', $body->{ref})[-1];
    my $message;
      
    if ($signature eq $secret) {

      my $deploy = SimpleGitDeploy::Model::RemoteDeploy->new({config => $c->app->config});

      if (defined $ref && $ref eq $branch && $event eq "push") {

        $deploy->start_deployment($body, $branch, $host, $token);
      } elsif ($body->{"deployment"}->{"payload"}->{"deploy_environment"} ne $c->app->config->{"environment"}){
        $c->render(status => 403, openapi => {event => $event, message => 'Forbidden'});
      } elsif ($event eq "deployment") {

        $deploy->process_deployment($body, $branch, $host, $token);

        my $server = SimpleGitDeploy::Model::ServerDeploy->new({config => $c->app->config});
        my $status = $server->pull;

        $body->{"deployment"}->{"payload"}->{"deploy_state"} = $status;
        $deploy->process_deployment($body, $branch, $host, $token);

      } elsif ($event eq "deployment_status") {

        my $sender = SimpleGitDeploy::Model::SendMessage->new({config => $c->app->config});
        $sender->send_message($body);
        if ($body->{"deployment_status"}->{"state"} eq "success") {
          my $server = SimpleGitDeploy::Model::ServerDeploy->new({config => $c->app->config});
          $server->run_scripts('post');
        }

      }
      $c->render(status => 200, openapi => {event => $event, message => "Success"});
    } else {
      $c->render(status => 401, openapi => {event => $event, message => 'Unauthorized'});
    }
  
  } catch {
    my $e = $_;
    $c->app->log->error($e);
    $c->render(status => 500, openapi => {error => $e});
  }
}

1;
