resource "aws_s3_bucket" "testbucket" {
  bucket = "${var.service}-${terraform.workspace}-${var.domain}"

  tags = {
    Name        = "${var.service}-${terraform.workspace}-${var.domain}"
    Environment = "${terraform.workspace}"
  }
}

#Block public access
resource "aws_s3_bucket_public_access_block" "testbucket" {
  bucket = aws_s3_bucket.testbucket.id
  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}
