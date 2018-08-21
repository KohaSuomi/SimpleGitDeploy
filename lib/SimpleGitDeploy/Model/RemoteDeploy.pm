package SimpleGitDeploy::Model::RemoteDeploy;
use Mojo::UserAgent;

use JSON;
use Try::Tiny;

sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;

    $self->{log} = Mojo::Log->new(path => $self->{"config"}->{"logs"}, level => 'debug');

    return $self;
}


sub start_deployment {
  my $self = shift;
  my ($push_request, $branch, $host, $token) = @_;

  $self->{log}->debug('Starting the deployment');

  my $user = $push_request->{"sender"}->{"login"};

  my $payload = {deploy_state => 'pending', deploy_user => $user};
  my $params = {ref => $branch, payload => $payload, description => "Deploying to production server"};

  my $path = $host.'/repos/'.$push_request->{"repository"}->{"full_name"}.'/deployments';

  return $self->send_deployment($path, $token, $params);
  
}

sub process_deployment {
  my $self = shift;
  my ($deployment, $branch, $host, $token) = @_;

  $self->{log}->debug('Processing the deployment');

  my $deployment_id = $deployment->{"deployment"}->{"id"};

  my $state = $deployment->{"deployment"}->{"payload"}->{"deploy_state"};

  my $params = {state => $state, description => "Deployment state is ".$state};

  my $path = $host.'/repos/'.$deployment->{"repository"}->{"full_name"}.'/deployments/'.$deployment_id.'/statuses';

  return $self->send_deployment($path, $token, $params);

}

sub send_deployment {
  my $self = shift;
  my ($path, $token, $params) = @_;
  try {
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->post($path => {Authorization => 'token '.$token} => json => $params);
    return "success";
  } catch {
    $self->{log}->error($_);
    return $_;
  }
}

1;