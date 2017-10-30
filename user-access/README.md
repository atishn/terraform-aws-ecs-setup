# AWS Users and Groups Setup

## Purpose
This does two things:
* IAM initialization
    * It creates the `circleci` user
    * It creates a set of IAM groups into which you can slot team members:
        * `admins` - can manage everything (including deploying from this directory)
        * `power_users` - can manage everything except users and groups
* CloudTrail initialization
    * This is the audit trail for the AWS account used to log all console and API actions.
    * If necessary, review the logs to determine any issues within the account.

For logging in and a basic `terraform` workflow, see [the readme in the parent directory](../README.md).
