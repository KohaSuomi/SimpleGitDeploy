use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

my $config = {
        environment => 'Test',
        repo    => '../SimpleGitDeploy',
        remote  => 'origin',
        branch  => 'dev',
        host    => 'https://api.example.com',
        token   => '234545366',
        logs    => '../mojo.log',
        messageType => 'email',
        emails  => [{
            from => 'test@example.com',
            to   => 'myemail@example.com',
            subject => 'Update finished',
        }],
        scripts => [
            {
            name => 'Load',
            path => 'curl https://www.google.com'
            }
        ]
    };

my $t = Test::Mojo->new('SimpleGitDeploy', $config);

my $push_event = {
    ref => "/refs/heads/dev", 
    repository => {full_name => "KohaSuomi/SimpleGitDeploy"}, 
    sender => {login => "tester"}
    };

my $tx = $t->ua->build_tx(POST => '/api/event_handler' => {"X-GitHub-Event" => "push"} => json => $push_event);
$t->request_ok($tx)
  ->status_is(200)
  ->json_is({event => 'push', message => "success"});

my $deployment_event = {
    description => "Deploying to production server","environment", 
    environment => "dev", 
    ref => "dev",
    payload => {deploy_user => "tester", deploy_state => "pending"}
    };
    

$tx = $t->ua->build_tx(POST => '/api/event_handler' => {"X-GitHub-Event" => "deployment"} => json => $deployment_event);
$t->request_ok($tx)
  ->status_is(200)
  ->json_is({event => 'deployment', message => "success"});
    

$tx = $t->ua->build_tx(POST => '/api/event_handler' => {"X-GitHub-Event" => "deployment_status"} => json => $deployment_event);
$t->request_ok($tx)
  ->status_is(200)
  ->json_is({event => 'deployment_status', message => "success"});

$push_event->{ref} = "/refs/heads/master";

$tx = $t->ua->build_tx(POST => '/api/event_handler' => {"X-GitHub-Event" => "push"} => json => $push_event);
$t->request_ok($tx)
  ->status_is(202)
  ->json_is({event => 'push', message => "Accepted"});

$t->app->config->{branch} = undef;


$tx = $t->ua->build_tx(POST => '/api/event_handler' => {"X-GitHub-Event" => "push"} => json => $push_event);
$t->request_ok($tx)
  ->status_is(501)
  ->json_is({event => 'push', message => "Not implemented"});


done_testing();
