use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Digest::SHA;
use Mojo::JSON qw(encode_json);

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

my $config = {
        environment => 'Test',
        repo    => '../SimpleGitDeploy',
        secret  => '1234',
        remote  => 'origin',
        branch  => 'dev',
        host    => 'https://api.example.com',
        token   => '234545366',
        logs    => '../mojo.log',
        log_level => 'debug',
        message_type => 'email',
        emails  => [{
            from => 'test@example.com',
            to   => 'myemail@example.com',
            subject => 'Update finished',
        }],
        pre_scripts => [
            {
            name => 'Load',
            command => 'curl',
            path => 'https://www.google.com'
            }
        ],
        post_scripts => [
            {
            name => 'Load',
            command => 'curl',
            path => 'https://www.google.com'
            }
        ]
    };

my $t = Test::Mojo->new('SimpleGitDeploy', $config);

my $sha;

my $push_event = {
    ref => "/refs/heads/dev", 
    repository => {full_name => "KohaSuomi/SimpleGitDeploy"}, 
    sender => {login => "tester"}
    };

$sha = "sha1=".Digest::SHA::hmac_sha1_hex(encode_json($push_event), $t->app->config->{secret});

my $tx = $t->ua->build_tx(POST => '/api/event_handler' => {"X-GitHub-Event" => "push", "X-HUB-SIGNATURE" => $sha} => json => $push_event);
$t->request_ok($tx)
  ->status_is(200)
  ->json_is({event => 'push', message => "Success"});

my $deployment_event = {
    description => "Deploying to production server",
    environment => "dev", 
    ref => "dev",
    payload => {deploy_user => "tester", deploy_state => "pending"}
    };

my $deployment_status_event = {
    deployment_status => {state => "pending"}
    };

$sha = "sha1=".Digest::SHA::hmac_sha1_hex(encode_json($deployment_event), $t->app->config->{secret});

$tx = $t->ua->build_tx(POST => '/api/event_handler' => {"X-GitHub-Event" => "deployment", "X-HUB-SIGNATURE" => $sha} => json => $deployment_event);
$t->request_ok($tx)
  ->status_is(200)
  ->json_is({event => 'deployment', message => "Success"});
    
$sha = "sha1=".Digest::SHA::hmac_sha1_hex(encode_json($deployment_status_event), $t->app->config->{secret});

$tx = $t->ua->build_tx(POST => '/api/event_handler' => {"X-GitHub-Event" => "deployment_status", "X-HUB-SIGNATURE" => $sha} => json => $deployment_status_event);
$t->request_ok($tx)
  ->status_is(200)
  ->json_is({event => 'deployment_status', message => "Success"});


$sha = "sha1=".Digest::SHA::hmac_sha1_hex(encode_json($deployment_status_event), '4444');

$tx = $t->ua->build_tx(POST => '/api/event_handler' => {"X-GitHub-Event" => "push", "X-HUB-SIGNATURE" => $sha} => json => $push_event);
$t->request_ok($tx)
  ->status_is(401)
  ->json_is({event => 'push', message => "Unauthorized"});

done_testing();
