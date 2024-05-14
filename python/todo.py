import boto3
import json

def lambda_handler(event, context):
    s3 = boto3.client("s3")
    bucket = "c2-g4-tf-us-west-2-962804699607"
    key = "todo-data.json"
    response = s3.get_object(Bucket=bucket, Key=key)
    json_data = response["Body"].read().decode("utf-8")
    json_content = json.loads(json_data)
    return {
        'statusCode': 200,
        'body': json_content
    }