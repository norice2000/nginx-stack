
tflint {
    required_version = ">= 0.50"
}

config {

}

plugin "aws" {
    enabled = true
    version = "0.33.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}