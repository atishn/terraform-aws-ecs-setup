# Admins
resource "aws_iam_group" "admins" {
  name = "admins"
}

resource "aws_iam_group_policy_attachment" "admins_attachment" {
  group      = "${aws_iam_group.admins.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "admins_force_mfa_policy" {
  group      = "${aws_iam_group.admins.name}"
  policy_arn = "${aws_iam_policy.force_mfa_login_policy.arn}"
}

# Power users
resource "aws_iam_group" "power_users" {
  name = "power_users"
}

resource "aws_iam_group_policy_attachment" "power_users_attachment" {
  group      = "${aws_iam_group.power_users.name}"
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_group_policy_attachment" "power_users_iam_perms" {
  group      = "${aws_iam_group.power_users.name}"
  policy_arn = "${aws_iam_policy.user_managed_iam_perms.arn}"
}

resource "aws_iam_group_policy_attachment" "power_users_force_mfa_policy" {
  group      = "${aws_iam_group.power_users.name}"
  policy_arn = "${aws_iam_policy.force_mfa_login_policy.arn}"
}
