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


resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "visitor-counter-api"
  protocol_type = "HTTP"
}


resource "aws_apigatewayv2_integration" "lambda_integration" {

  api_id = aws_apigatewayv2_api.visitor_api.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}


resource "aws_apigatewayv2_route" "visit_route" {

  api_id = aws_apigatewayv2_api.visitor_api.id

  route_key = "GET /visit"

  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


resource "aws_apigatewayv2_stage" "prod" {

  api_id = aws_apigatewayv2_api.visitor_api.id

  name = "prod"

  auto_deploy = true
}


resource "aws_lambda_permission" "api_gateway" {

  statement_id = "AllowExecutionFromAPIGateway"
  action       = "lambda:InvokeFunction"

  function_name = aws_lambda_function.visitor_counter.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}


output "api_endpoint" {
  value = aws_apigatewayv2_api.visitor_api.api_endpoint
}
