"""
AWS Serverless Visitor Counter

API Gateway -> Lambda -> DynamoDB
"""
import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('VisitorCounterTerraform')

def lambda_handler(event, context):

    response = table.get_item(
        Key={
            'id': 'visitor'
        }
    )

    count = int(response['Item']['count'])

    count += 1

    table.update_item(
        Key={
            'id': 'visitor'
        },
        UpdateExpression='SET #c = :val',
        ExpressionAttributeNames={
            '#c': 'count'
        },
        ExpressionAttributeValues={
            ':val': count
        }
    )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'visitor_count': count
        })
    }
