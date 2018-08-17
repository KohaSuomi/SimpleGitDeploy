package SimpleGitDeploy::Model::ServerDeploy;

use Modern::Perl;
use Git;
use Try::Tiny;

sub pull {
    my $self = shift;
    my $repo = Git->repository(Directory => $self->app->config->{"repo"});
    my $remote = $self->app->config->{"remote"};
    my $branch = $self->app->config->{"branch"};

    try {
        my $last_commit = $repo->command("rev-parse", "HEAD");
        $last_commit =~ s/^\s+|\s+$//g;
        my $output = $repo->command("pull", $remote, $branch);
        $self->app->log->debug($output);
        my $run = $self->SimpleGitDeploy::Model::ServerDeploy::run_scripts;
        unless ($run) {
            $repo->command('reset', '--hard', $last_commit);
            $self->app->log->warn("Reverted commits!");
            return "failed";
        } else {
            return "success";
        }
    } catch {
        my $e = $_;
        $self->app->log->error($e);
        $self->app->log->error("Conflict while pulling, aborting!");
        return "failed";
    }
}

sub run_scripts {
    my $self = shift;
    my $scripts = $self->app->config->{"scripts"};
    my $logs = $self->app->config->{"logs"};

    try {
        foreach my $script (@{$scripts}) {
            $self->app->log->debug($script->{name});
            my $output = system($script->{path}. '>>'.$logs) == 0 or die "system $script->{name} failed: $?";
        }
        return 1;
    } catch {
        my $e = $_;
        $self->app->log->error($e);
        return 0;
    }
    

}

1;