resource "aws_s3_bucket" "mediawiki_backup" {
  bucket = var.backup_bucket_name
}

data "aws_iam_policy_document" "upload_backups" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.backup_bucket_name}/*"]
  }
}

resource "aws_iam_role" "upload_backups" {
  name = "upload_backups"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "upload_backups" {
  name = "upload_backups"
  role = aws_iam_role.upload_backups.id
  policy = data.aws_iam_policy_document.upload_backups.json
}

resource "aws_iam_instance_profile" "upload_backups" {
  name = "upload_backups"
  role = aws_iam_role.upload_backups.name
}
