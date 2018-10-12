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

Add content to simple_git_deploy.conf. 

* Define hypnotoad port.
* Secret is for Github authentication.
* Give a name of the environment.
* Which repo you want to update
* Which branch the tool is listening.
* Github's API path.
* Token from Github which is used for authentication. Can be created from your profile.
* Where to write the logs and level.
* Where to send information about the update.
* You can define pre and post scripts which are triggered on at the first stage of the update and when everything is fully finished. Scripts are automatically loaded on the background but there is an option to wait some process to be finished by adding wait parameter.

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
      command => 'sudo',
      name => 'Update database',
      path => '/home/foo/Foo/updatedatabase.sh',
      wait => 1
    }
  ],
  post_scripts => [ {
      name => 'Memcached restart',
      command => 'sudo',
      path => '/etc/init.d/memcached',
      params => 'restart'
    }, {
      name => 'Plack reload',
      command => 'sudo',
      path => '/etc/init.d/koha-plack-daemon',
      params => 'reload'
    }
  ]
}

```

### Adding service to Apache

Service can be added to Apache along other services. You can use proxy pass for this.

```
ProxyPass /event_handler http://localhost:8081/api/event_handler keepalive=On
ProxyPassReverse /event_handler http://localhost:8081/api/event_handler

```


### Install server daemon

```
sudo ln -s /home/foo/SimpleGitDeploy/scripts/simple_git_deploy_daemon.sh /etc/init.d/simple-git-deloy-daemon 
sudo update-rc.d simple-git-deloy-daemon defaults
sudo service simple-git-deloy-daemon start

```

### Setting up Github Webhooks

Go to your repository and find Webhooks from settings.

* Add payload URL
* Content type as application/json
* Add secret from your config file.
* Choose push, deployment and deployment statuses from events' list.

Activate your webhook and you are good to go.