import os
from datetime import datetime, timedelta

from src.helper import DataFrameHelper, GCPHelper, config, logger

# global variables
key_path = 'service_account.json'
today = datetime.now().strftime('%Y%m%d')

DATA_FOLDER = 'data/'
QUERY_FOLDER = 'queries/'
LOGS_FOLDER = 'logs/'

# class istances
dfh = DataFrameHelper()
gcph = GCPHelper(key_path=key_path)

# check all files and ingest them to staging
table_data = config['categories']
for file in os.listdir(DATA_FOLDER):
    for key in table_data.keys():
        if key in file and today in file:
            table_name = table_data[key]['stgTable']
            parquet_file = f'{table_name}-{today}.parquet.gzip'
            blob_name = f'{table_name}-{today}.parquet.gzip'

            logger.info(f'Cleaning table {table_name}')
            dfh.read_json(os.path.join(DATA_FOLDER, file))
            dfh.clean_df()

            logger.info('Saving data to parquet')
            dfh.to_parquet(file=parquet_file)

            logger.info(f'Uploading data to storage')
            gcph.upload_file_to_storage(
                blob_name=blob_name,
                file_name=parquet_file
            )

            logger.info(f'Droping table if exists {table_name}')
            gcph.drop_table_if_exists(table_name)
            
            logger.info(f'Inserting data to {table_name}')
            gcph.insert_data_to_staging(
                blob_name=blob_name,
                table_name=table_name
            )

            logger.info(f'Moving processed data to folder: {blob_name}')
            gcph.move_to_processed(blob_name=blob_name)
      
            # Remove local Parquet file
            logger.info('Deleting local parquet')
            os.remove(parquet_file)

            # stop loop if key found - move to the next file
            break

# load
for file in os.listdir(QUERY_FOLDER):
    for key in table_data.keys():
        if key in file:
            file = os.path.join(QUERY_FOLDER, file)
            logger.info(f'Executing query for {file}')
            gcph.execute_from_file(file_name=file)

# purge cgp storage
DAYS = 21
gcph.purge_storage(days=DAYS)

# clean local data and logs
for dir in (DATA_FOLDER, LOGS_FOLDER):
    for file in os.listdir(dir):
        file = os.path.join(dir, file)
        file_ts = datetime.fromtimestamp(os.path.getctime(file))
        if file_ts < datetime.now() - timedelta(days=DAYS):
            logger.info(f'Removing file: {file}')
            os.remove(file)