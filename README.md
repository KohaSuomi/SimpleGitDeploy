# Simple Git Deploy

Simple API for updating code on server using Github webhooks

## Getting Started

Clone this repo to your server and set up configuration file simple_git_deploy.conf to the root.

### Prerequisites

Install these CPAN packages to your environment. There is also a script in scripts/installdeps.sh for automating this. 

```
Try::Tiny
Modern::Perl
Git
Mojolicious
Mojolicious::Plugin::OpenAPI
Email::MIME
Email::Sender::Simple
JSON
```
