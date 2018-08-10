#!/usr/bin/env perl
use Mojolicious::Lite;
use JSON;
use Data::Dumper;

app->config(hypnotoad => {listen => ['http://*:8081']});

post '/event_handler' => sub {
  my $c = shift;
  my $params =  $c->req->params->to_hash;
  print Dumper $params->{"payload"};
  $c->render(json => {status => "success"});
};

app->start;