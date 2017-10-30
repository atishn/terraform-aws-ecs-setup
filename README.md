
# Terraform scripts with an example of setting AWS EC2 Container Service infrastructure.

This code instantiates the infrastructure of a sample project with front end and back end containers.

It uses
- AWS Application load balancer
- AES EC2 Container Service
- Terraform scripts
- AWS CLI
- Blackbox for encryption

It has the following folders:

- `user-access` manages the AWS account setup and permissions.
- `provisioning` manages the actual infrastructure.

## Prerequisites

- Install [`terraform`](https://www.terraform.io) version 0.9.11.
- Install AWS CLI

## Getting Started

* Make sure:
  * You have an AWS account.
  * That your AWS account is a member of the necessary group. For `user-access`
    that is `admins`, for `provisioning` that is `power_users`.
* Get an [AWS access key pair](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html).
* Configure an AWS CLI profile:
  ```
  $ aws configure --profile workshop-hub
  AWS Access Key ID [None]: <YOUR ACCESS KEY ID>
  AWS Secret Access Key [None]: <YOUR SECRET ACCESS KEY>
  Default region name [None]: <Enter>
  Default output format [None]: <Enter>
  ```
* Use the `setup-environment` script to unlock secrets and create an AWS session token:
  ```
  $ eval $(./setup-environment)
  AWS IAM login: <AWS login id>
  MFA OTP code: <OTP>
  ```

Your `AWS login id` is usually your email address. Your `OTP` is a One Time
Password that you get from e.g. google authenticator.

This will set credentials, including a session token in environment variables.
So using `terraform` will only work in the same shell this command was executed
in. The session token will expire after 12 hours.

Initialize `terraform`:
```
$ terraform init
$ terraform get
```

## Basic Terraform Workflow

After changing the terraform files, you should be able to inspect the changes
that would cause -- without applying them -- by running:
```
$ terraform plan -out current.plan
```

If you want to actually apply the changes, do:

```
$ terraform apply current.plan
```

`terraform` has pretty good
[documentation](https://www.terraform.io/docs/providers/aws/index.html).

## Secret Management

We use [blackbox](https://github.com/StackExchange/blackbox), a tool that manages secrets in git via multi-key GPG encryption.

### Adding an admin
The new admin should [generate and export an ASCII encoded GPG public key](https://help.github.com/articles/generating-a-new-gpg-key/);

Then the existing admin should do the following:

```
gpg --import thatpublickey.pub

blackbox_addadmin thatnewadmin@email.com

blackbox_update_all_files
```

### Removing an admin

```
blackbox_removeaddmin admin@email.com

blackbox_update_all_files
```
