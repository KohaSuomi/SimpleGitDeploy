package SimpleGitDeploy::Model::ServerDeploy;

use Modern::Perl;
use Git;

sub create {

}

sub push {
    my $self = shift;
    my $repo = Git->repository(Directory => $self->app->config->{"repo"});
    my $environments = $self->app->config->{"environments"};
    my $branch = $self->app->config->{"branch"};
    foreach my $environment (@{$environments}) {
        my $name = $environment->{name};
        $repo->command("push", $name, $branch);
    }
}

1;