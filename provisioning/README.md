# provisioning

## Overview
This folder contains `terraform` code to setup the basic infrastructure.

## Purpose

* Setup VPC
* Setup EC2 Container Service
* Setup Docker container repository in ECR
* Setup Application Load Balancer
* Setup Service and Task definition

For logging in and a basic `terraform` workflow, see [the readme in the parent directory](../README.md).

## Logging into ECS Hosts

In the event that you need to SSH into the ECS Container instances, you can do the following:

- `blackbox_decrypt_all_files`
- `chmod 600 ssh-keys/workshop-key.pem`
- grab the IP address of the container instance on the EC2 dashboard
- `ssh -i ssh-keys/workshop-key.pem ec2-user@IP_ADDRESS_OF_CONTAINER_INSTANCE`
- when you are done, `blackbox_shred_all_files`
