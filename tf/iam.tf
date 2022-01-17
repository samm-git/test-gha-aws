# Github Actions OIDC provider is used for federated auth and role assumption
# See https://github.com/aws-actions/configure-aws-credentials for the
# configuration details

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        var.github_actions_repo
      ]
    }
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
  }
}

# policy to deploy MCS and all related objects
data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    actions = [
      "sts:GetCallerIdentity",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"

      values = [
        "us-east-1"
      ]
    }
    resources = ["*"]
  }
}

# role to deploy things using Github Actions
resource "aws_iam_role" "github_action_deploy" {
  name = "GHARole"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json


  inline_policy {
    name   = "pipeline-deploy"
    policy = data.aws_iam_policy_document.github_actions_deploy.json
  }
}
