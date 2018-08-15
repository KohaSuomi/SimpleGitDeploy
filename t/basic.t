use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

my $t = Test::Mojo->new('SimpleGitDeploy');
my $json = '{"ref": "/refs/heads/master", "repository":{"full_name":"KohaSuomi/SimpleGitDeploy"}, "sender":{"login":"johannaraisa"}}';
$t->post_ok('/api/event_handler', $json)->status_is(200)->json_is({status => "success"});

done_testing();
