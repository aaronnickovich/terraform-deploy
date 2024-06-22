resource "aws_s3_bucket" "testbucket" {
  bucket = "${var.service}-${terraform.workspace}-${var.domain}"

  tags = {
    Name        = "${var.service}-${terraform.workspace}-${var.domain}"
    Environment = "${terraform.workspace}"
  }
}
