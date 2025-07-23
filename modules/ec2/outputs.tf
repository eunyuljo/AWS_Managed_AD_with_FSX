output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.domain_joined.id
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.domain_joined.private_ip
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.domain_joined.public_ip
}

output "security_group_id" {
  description = "Security group ID for the EC2 instance"
  value       = aws_security_group.ec2.id
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.domain_joined.instance_state
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the EC2 instance"
  value       = aws_iam_role.ec2_domain_join.arn
}