output "elastic_ip" {
  value = aws_eip.mediawiki.public_ip
}
