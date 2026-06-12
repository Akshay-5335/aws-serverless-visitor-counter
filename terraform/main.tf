provider "aws" {
  region = "ap-south-1"
}

resource "aws_dynamodb_table" "visitor_counter" {
  name         = "VisitorCounterTerraform"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
