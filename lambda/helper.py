import json
from datetime import datetime

import boto3 
import pandas as pd
from botocore.exceptions import ClientError
from redmail import EmailSender


with open('config.json', 'r') as f:
    config = json.load(f)

class AWS:
    def _get_secret(self, secret_name: str, region_name: str) -> dict:
        # Create a Secrets Manager client
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=region_name
        )

        try:
            get_secret_value_response = client.get_secret_value(
                SecretId=secret_name
            )
        except ClientError as e:
            raise e

        # Decrypts secret using the associated KMS key.
        secret = get_secret_value_response['SecretString']
        secret_dict = json.loads(secret)

        return secret_dict
    
    def open_s3_file(self, path: str) -> list:
        path = path.replace('s3://', '')
        bucket = path.split('/', 1)[0]
        key = path.split('/', 1)[1]

        s3 = boto3.client('s3')
        obj = s3.get_object(Bucket=bucket, Key=key)
        df = pd.read_csv(obj['body'])

        return df


class Email(AWS):

    def __init__(self, email_to: str) -> None:
        self.email_to = email_to
        gmail_credentials = self._get_secret(
            secret_name=config['smtpServerSecret'],
            region_name=config['regionName']
        )
        self._email = EmailSender(
            host=gmail_credentials['host'],
            port=gmail_credentials['port'],
            username=gmail_credentials['smtpUser'],
            password=gmail_credentials['password']
        )

        tdy = datetime.now().strftime('%Y-%m-%d')
        self._subject = f'Weekly price change for {tdy}'

    def send_email(self, html: str, tables: dict) -> None:
        try:
            self._email.send(
                subject=self._subject,
                sender='priceChangeIndex@gmail.com',
                receivers=self.email_to,
                html=html,
                body_tables=tables
            )
            print(f'Email sent successfully to {self.email_to}')
        except Exception as e:
            print(f'Email sending to {self.email_to} failed: {e}')
            raise