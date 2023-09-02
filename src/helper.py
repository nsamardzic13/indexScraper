import os
import json
import logging
from datetime import datetime, timedelta, timezone

import pandas as pd
from google.cloud import bigquery
from google.cloud import storage
from google.oauth2 import service_account

config_file_path = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), 
    'config.json'
)
with open(config_file_path, 'r', encoding='utf-8') as f:
    config = json.load(f)

today = datetime.now().strftime('%Y%m%d%H%M%S')
logger = logging
logger.basicConfig(filename= f'./logs/mainLog-{today}.log', format='%(asctime)s - %(levelname)s - %(message)s', level=logging.INFO)

class DataFrameHelper:

    def __init__(self) -> None:
        self.df = None

    def read_json(self, path: str):
        self.df = pd.read_json(path)

    def to_parquet(self, file: str, compression: str ='gzip'):
        self.df.to_parquet(
            file, 
            compression=compression,
            index=False
        )

    def drop_columns(self) -> None:
        for column_name in config['dropColumns']:
            if column_name in list(self.df.columns):
                self.df.drop(column_name, inplace=True)

    def delete_null(self) -> None:
        self.df.dropna(
            subset=config['nonNullColumns'],
            inplace=True
        )

    def remove_string(self) -> None:
        self.df.replace("\r", "", inplace=True)

    def rename_columns(self) -> None:
        for col in self.df.columns:
            col_renamed = col.lower()
            # special chars
            col_renamed = col_renamed.replace(' ', '_').replace(':', '').replace('/', '_')
            # croatian letters
            col_renamed = col_renamed.replace('č', 'c').replace('ć', 'c').replace('đ', 'd').replace('š', 's').replace('ž', 'z')
            self.df.rename(
                columns={
                    col: col_renamed
                },
                errors='ignore',
                inplace=True
            )

    def set_types(self) -> None:
        self.df = self.df.convert_dtypes()

    def clean_df(self) -> None:
        self.drop_columns()
        self.delete_null()
        self.remove_string()
        self.set_types()
        self.rename_columns()
        self.df.reset_index(drop=True)


class GCPHelper:
    
    def __init__(self, key_path: str) -> None:
        self.credentials = service_account.Credentials.from_service_account_file(
            key_path,
            scopes=["https://www.googleapis.com/auth/cloud-platform"],
        )
        
        self.bigquery_client = bigquery.Client(
            credentials=self.credentials, 
            project=self.credentials.project_id
        )
        self.storage_client = storage.Client(
            credentials=self.credentials,
            project=self.credentials.project_id
        )
        
        self.job_config = bigquery.LoadJobConfig(source_format=bigquery.SourceFormat.PARQUET)
        self.bucket = self.storage_client.get_bucket(config['bucketName'])

    def execute_from_file(self, file_name: str):
        with open(file_name, 'r') as f:
            full_file = f.read()
        
        queries = full_file.split(';')
        queries = [query.strip() for query in queries if query.strip()]
        for query in queries:
            logger.info(f'Executing query {query[:100]}')
            q = self.bigquery_client.query(query)
            q.result()
    
    def upload_file_to_storage(self, blob_name: str, file_name: str, content_type: str = 'application/parquet') -> None:
        blob = self.bucket.blob(blob_name)
        blob.upload_from_filename(
            filename=file_name,
            content_type=content_type
        )

    def insert_blobs_manually(self) -> None:
        table_data = config['categories']
        blobs = self.bucket.list_blobs()
        for blob in blobs:
            name = blob.name
            if not name.startswith('processed/'):
                for key in table_data.keys():
                    if key in name:
                        table_name = table_data[key]['stgTable']
                        logger.info(f'Droping table if exists {table_name}')
                        self.drop_table_if_exists(table_name)

                        logger.info(f'Inserting data to {table_name}')
                        self.insert_data_to_staging(
                            blob_name=name,
                            table_name=table_name
                        )

                        logger.info(f'Moving processed data to folder: {name}')
                        self.move_to_processed(blob_name=name)
                        break

    def drop_table_if_exists(self, table_name: str) -> None:
        q = self.bigquery_client.query(f"DROP TABLE IF EXISTS {table_name}")
        q.result()
        
    def insert_data_to_staging(self, blob_name: str, table_name: str) -> None:
        q= self.bigquery_client.load_table_from_uri(
            source_uris=f"gs://{config['bucketName']}/{blob_name}",
            destination=table_name,
            job_config=self.job_config
        )
        q.result()

    def move_to_processed(self, blob_name: str) -> None:
        self.bucket.rename_blob(
            blob=self.bucket.blob(blob_name),
            new_name=f'processed/{blob_name}'
        )

    def purge_storage(self, days: int) -> None:
        blobs = self.bucket.list_blobs()
        threshold_time = datetime.now(timezone.utc) - timedelta(days=days)
        for blob in blobs:
            if blob.time_created < threshold_time:
                logger.info(f'Deleting blob {blob}')
                blob.delete()