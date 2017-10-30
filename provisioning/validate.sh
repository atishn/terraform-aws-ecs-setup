#!/usr/bin/env bash

set -o errexit

for x in . ./web-service ./environment ./ecs-cluster ./web-service/ecs-service ./vpc ./ecr-repo ./web-service/alb ./web-service/config ; do
  echo validating $x
  terraform validate $x
done
echo success
