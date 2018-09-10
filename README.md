# Simple Git Deploy

Simple API for updating code on server using Github webhooks.

## Getting Started

Clone this repo to your server and set up configuration file simple_git_deploy.conf to the root.

### Prerequisites

Install these CPAN packages to your environment. There is also a script in ./scripts/installdeps.sh for automating this. 

```
Try::Tiny
Modern::Perl
Git
Mojolicious
Mojolicious::Plugin::OpenAPI
Email::MIME
Email::Sender::Simple
JSON
Proc::Simple

```

### Config file

Add content to simple_git_deploy.conf. You can define pre and post scripts which are triggered on at the first stage of the update and when everything is fully finished.

```
{
  hypnotoad => {listen => ['http://*:8081']},
  secret  => 'mysecret',
  environment => 'My enviroment',
  repo    => '/home/foo/Foo/',
  remote  => 'origin',
  branch  => 'production',
  host    => 'https://api.github.com',
  token   => '123456789',
  logs    => '/home/foo/mojo.log',
  log_level => 'debug',
  message_type => 'email',
  emails  => [{
    from => 'foo@example.com',
    to   => 'bar@myemail.com',
    subject => 'Update status',
  }],
  pre_scripts => [
    {
      name => 'Update database',
      path => '/home/foo/Foo/updatedatabase.sh'
    }
  ],
  post_scripts => [
    {
      name => 'Reload server',
      path => '/home/foo/Foo/server-reload.sh'
    }
  ]
}

```

### Install server daemon

```
sudo ln -s /home/foo/SimpleGitDeploy/scripts/simple_git_deploy_daemon.sh /etc/init.d/simple-git-deloy-daemon 
sudo update-rc.d simple-git-deloy-daemon defaults
sudo service simple-git-deloy-daemon start

```
