resource "aws_iam_user" "circleci_user" {
  name = "circleci"
}

resource "aws_iam_user_policy_attachment" "circleci_perms" {
  user       = "${aws_iam_user.circleci_user.name}"
  policy_arn = "${aws_iam_policy.circleci_perms.arn}"
}

resource "aws_iam_policy" "circleci_perms" {
  name        = "circleci_perms"
  description = "Lists permissions allowed for the 'circleci' user."

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CircleCIUserPermissions",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:UpdateService",
                "ecs:RegisterTaskDefinition",
                "ecs:RunTask"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}
