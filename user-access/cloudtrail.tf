# Activate Cloudtrail on this AWS account.
resource "aws_cloudtrail" "audit_trail" {
  name           = "workshop-cloudtrail"
  s3_bucket_name = "${aws_s3_bucket.audit_trail.id}"
}

resource "aws_s3_bucket" "audit_trail" {
  bucket        = "workshop-cloudtrail"
  force_destroy = true

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::workshop-cloudtrail"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::workshop-cloudtrail/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF
}
