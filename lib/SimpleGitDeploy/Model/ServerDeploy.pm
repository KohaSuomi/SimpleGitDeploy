package SimpleGitDeploy::Model::ServerDeploy;

use Modern::Perl;
use Git;
use Try::Tiny;

sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;
    
    $self->{log} = Mojo::Log->new(path => $self->{"config"}->{"logs"}, level => 'debug');

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
        $self->{log}->debug($output);
        my $run = $self->SimpleGitDeploy::Model::ServerDeploy::run_scripts;
        unless ($run) {
            $repo->command('reset', '--hard', $last_commit);
            $self->{log}->warn("Reverted commits!");
            return "failed";
        } else {
            return "success";
        }
    } catch {
        my $e = $_;
        $self->{log}->error($e);
        $self->{log}->error("Conflict while pulling, aborting!");
        return "failed";
    }
}

sub run_scripts {
    my $self = shift;
    my $scripts = $self->{config}->{"scripts"};
    my $logs = $self->{config}->{"logs"};

    try {
        foreach my $script (@{$scripts}) {
            $self->{log}->debug($script->{name});
            my $output = system($script->{path}. '>>'.$logs) == 0 or die "system $script->{name} failed: $?";
        }
        return 1;
    } catch {
        my $e = $_;
        $self->{log}->error($e);
        return 0;
    }
    

}

1;