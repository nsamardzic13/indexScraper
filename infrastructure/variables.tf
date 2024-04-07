variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "tf-indexads"
}

variable "sns_email_address" {
  type    = string
  default = "nikola.samardzic1997+AWS@gmail.com"
}

variable "lambda_layers" {
  type = list(string)
  default = [
    "arn:aws:lambda:eu-central-1:770693421928:layer:Klayers-p310-pandas:12",
    "arn:aws:lambda:eu-central-1:770693421928:layer:Klayers-p310-numpy:8"
  ]
}