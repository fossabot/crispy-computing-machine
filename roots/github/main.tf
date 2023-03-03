provider "aws" {}

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "iot4-tfstate"
    key    = "roots/github/github.tfstate"
    region = "us-east-1"
  }
}

# Configure the GitHub Provider
provider "github" {}

resource "github_repository_webhook" "newrelic" {
  repository = data.github_repository.ccm.name
  configuration {
    url          = "https://security-ingest-processor.service.newrelic.com/v1/security/webhooks/dependabot?Api-Key=${var.newrelic_token}"
    content_type = "json"
    insecure_ssl = false
  }
  active = true
  events = ["repository_vulnerability_alert"]

}
