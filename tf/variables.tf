variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "github_actions_repo" {
  description = "Repository name to trust for the AssumeRole in the Github Action"
  default     = "repo:samm-git/test-gha-aws:*"
}

