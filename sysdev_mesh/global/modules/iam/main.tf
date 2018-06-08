data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      "${var.bucket_arn}",
      "${var.bucket_arn}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_policy" {
  name   = "tinc-hosts-sysdev-mesh"
  path   = "/"
  policy = "${data.aws_iam_policy_document.s3_policy.json}"
}

resource "aws_iam_instance_profile" "s3_policy" {
  name = "tinc-hosts-sysdev-mesh"
  role = "${aws_iam_role.s3_policy.name}"
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = "${aws_iam_role.s3_policy.name}"
  policy_arn = "${aws_iam_policy.s3_policy.arn}"
}

resource "aws_iam_role" "s3_policy" {
  name = "tinc-hosts-sysdev-mesh"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}
