package SimpleGitDeploy::Model::ServerDeploy;

use Modern::Perl;
use Git;
use Try::Tiny;
use Proc::Simple;

sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;
    
    $self->{log} = Mojo::Log->new(path => $self->{"config"}->{"logs"}, level => $self->{"config"}->{"log_level"});

    return $self;
}

sub pull {
    my $self = shift;
    my $repo = Git->repository(Directory => $self->{config}->{"repo"});
    my $remote = $self->{config}->{"remote"};
    my $branch = $self->{config}->{"branch"};

    try {
        my $last_commit = $repo->command("rev-parse", "HEAD");
        $last_commit =~ s/^\s+|\s+$//g;
        my $output = $repo->command("pull", $remote, $branch);
        if ($output =~ /Already up-to-date./i) {
            return "success";
        }
        $self->{log}->info($output);
        my $run = $self->run_scripts('pre');
        unless ($run) {
            $repo->command('reset', '--hard', $last_commit);
            $self->{log}->warn("Rollback commits!");
            return "failure";
        } else {
            return "success";
        }
    } catch {
        my $e = $_;
        $self->{log}->error($e);
        $self->{log}->error("Conflict while pulling, aborting!");
        return "failure";
    }
}

sub run_scripts {
    my $self = shift;
    my ($type) = @_;
    my $scripts = $self->{config}->{$type."_scripts"};
    my $logs = $self->{config}->{"logs"};
    my $myproc = Proc::Simple->new();
    try {
        foreach my $script (@{$scripts}) {
            die "The file $script->{path} does not exist!" unless -e $script->{path};
            $self->{log}->debug($script->{name});
            my $path =  $script->{command} ? $script->{command}.' '.$script->{path} : $script->{path};
            $path = $path.' '.$script->{params} if $script->{params};
            $myproc->start($path);
            $myproc->wait() if $script->{wait};
        }
        return 1;
    } catch {
        my $e = $_;
        $self->{log}->error($e);
        return 0;
    }
    

}

1;