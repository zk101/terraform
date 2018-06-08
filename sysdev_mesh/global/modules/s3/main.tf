resource "aws_s3_bucket" "tinc-hosts" {
  bucket        = "tinc-hosts-sysdev-mesh"
  acl           = "private"
  force_destroy = true

  tags {
    Name = "Tinc Hosts - sysdev-mesh"
  }
}

resource "aws_s3_bucket" "kops-state" {
  bucket        = "kops-state-sysdev-mesh"
  acl           = "private"
  force_destroy = true

  tags {
    Name = "Tinc Hosts - sysdev-mesh"
  }
}
