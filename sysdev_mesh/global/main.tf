provider "aws" {
  region                  = "${var.region}"
  shared_credentials_file = "${var.homedir}/.aws/creds"
}

module "s3" {
  source = "modules/s3"
}

module "iam" {
  source     = "modules/iam"
  bucket_arn = "${module.s3.bucket_arn}"
}
