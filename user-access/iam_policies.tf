data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "user_managed_iam_perms" {
  name        = "user_managed_iam_perms"
  description = "Allows IAM users to manage their own IAM credentials."

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":[
        {
            "Sid": "AllowAllUsersToListAccounts",
            "Effect": "Allow",
            "Action":[
                "iam:GetAccountPasswordPolicy",
                "iam:GetAccountSummary",
                "iam:ListAccount*",
                "iam:ListUsers"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowIndividualUserToSeeAndManageTheirOwnAccountInformation",
            "Effect": "Allow",
            "Action":[
                "iam:ChangePassword",
                "iam:*AccessKey*",
                "iam:*LoginProfile",
                "iam:*SSHPublicKey*"
            ],
            "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
        },
        {
            "Sid": "AllowIndividualUserToListTheirOwnMFA",
            "Effect": "Allow",
            "Action":[
                "iam:ListVirtualMFADevices",
                "iam:ListMFADevices"
            ],
            "Resource":[
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/*",
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
            ]
        },
        {
            "Sid": "AllowIndividualUserToManageTheirOwnMFA",
            "Effect": "Allow",
            "Action":[
                "iam:CreateVirtualMFADevice",
                "iam:DeactivateMFADevice",
                "iam:DeleteVirtualMFADevice",
                "iam:RequestSmsMfaRegistration",
                "iam:FinalizeSmsMfaRegistration",
                "iam:EnableMFADevice",
                "iam:ResyncMFADevice"
            ],
            "Resource":[
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/$${aws:username}",
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "force_mfa_login_policy" {
  name        = "force_mfa_login_policy"
  description = "Forces IAM users to use MFA."

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":[
        {
            "Sid": "BlockAnyAccessOtherThanAboveUnlessSignedInWithMFA",
            "Effect": "Deny",
            "NotAction": "iam:*",
            "Resource": "*",
            "Condition":{ "BoolIfExists":{ "aws:MultiFactorAuthPresent": "false"}}
        }
    ]
}
EOF
}
