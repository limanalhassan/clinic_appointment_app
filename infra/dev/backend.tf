terraform {
  backend "s3" {
    bucket       = "limansachinetestbuckets234"
    key          = "dev/terraform.tfstate"
    region       = "ca-central-1"
    profile      = "terraform"
    encrypt      = true
    use_lockfile = true
  }
}


