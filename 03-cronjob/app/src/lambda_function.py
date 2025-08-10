import boto3
import os
import json
from datetime import datetime
import logging
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')

BUCKET_NAME = os.environ['BUCKET_NAME']

def lambda_handler(event, context):

    logger.info(f"Received event: {json.dumps(event)}")

    try:
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        file_name = f"daily_file_{timestamp}.txt"
        
        file_content = (
            f"Automatically generated file\n"
            f"Date/Time: {timestamp}\n"
            f"Lambda Function: {context.function_name}\n"
            f"Request ID: {context.aws_request_id}"
        )

        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=file_name,
            Body=file_content.encode("utf-8"),
            ContentType="text/plain",
            Metadata={
                'CreatedBy': 'Lambda',
                'Timestamp': timestamp
            }
        )

        logger.info(f"File {file_name} successfully uploaded to {BUCKET_NAME}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f"File {file_name} successfully uploaded",
                'bucket': BUCKET_NAME,
                'file': file_name
            })
        }

    except ClientError as e:
        error_message = f"Error uploading file to S3: {str(e)}"
        logger.error(error_message)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_message})
        }
    
    except Exception as e:
        error_message = f"Unexpected error: {str(e)}"
        logger.error(error_message)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_message})
        }