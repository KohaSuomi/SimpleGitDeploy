#!/bin/bash

DEPS=( \
  "Try::Tiny" \
  "Modern::Perl" \
  "Git" \
  "Mojolicious" \
  "Mojolicious::Plugin::OpenAPI" \
  "Email::MIME" \
  "Email::Sender::Simple" \
  "JSON" \
  "Proc::Simple" \
  
)

for dep in "${DEPS[@]}"
do
  sudo cpanm $dep
done