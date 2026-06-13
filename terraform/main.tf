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
resource "aws_iam_role" "lambda_role" {
  name = "visitor-counter-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_lambda_function" "visitor_counter" {

  function_name = "VisitorCounterTerraform"

  role = aws_iam_role.lambda_role.arn

  runtime = "python3.13"

  handler = "lambda_function.lambda_handler"

  filename = "../lambda/visitor-counter.zip"

  source_code_hash = filebase64sha256("../lambda/visitor-counter.zip")
}
resource "aws_iam_role_policy" "dynamodb_access" {

  name = "visitor-counter-dynamodb-policy"

  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]

        Resource = aws_dynamodb_table.visitor_counter.arn
      }
    ]
  })
}
