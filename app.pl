#!/usr/bin/env perl
use Mojolicious::Lite;
use JSON;
use Data::Dumper;

app->config(hypnotoad => {listen => ['http://*:8081']});

post '/event_handler' => sub {
  my $c = shift;
  print Dumper from_json($c->param{"payload"});
  $c->render(json => $c->req->body);
};

app->start;