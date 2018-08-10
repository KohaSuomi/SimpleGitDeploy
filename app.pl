#!/usr/bin/env perl
use Mojolicious::Lite;
use Data::Dumper;



app->config(hypnotoad => {listen => ['http://*:8081']});

post '/event_handler' => sub {
  my $c = shift;
  $c->render(json => $c->req->body);
};

app->start;