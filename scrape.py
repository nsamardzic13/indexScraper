import os
import json
from datetime import datetime

import boto3
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from scrapy.crawler import CrawlerProcess
from unidecode import unidecode

from index_scrapy.index_scrapy.spiders.index_spider import *


with open('config.json', 'r', encoding='utf-8') as f:
    config = json.load(f) 

def clean_data(name: str, df: pd.DataFrame) -> pd.DataFrame:
    with open(f'index_scrapy/DDL/{name}.json', 'r') as f:
        config = json.load(f)
        rename = config['rename']
        types = config['setTypes']
    
    df.rename(columns=lambda x: unidecode(x.lower()).replace(' ', '_'), inplace=True)
    df.rename(columns=rename, inplace=True)

    columns_to_keep = [key for key in types.keys() if key in df.columns]
    df = df[columns_to_keep]
    
    for col, dtype in types.items():
        if col in df.columns:
            if dtype == "float":
                df[col] = pd.to_numeric(df[col], errors='coerce')  # Convert to numeric, preserving NaN
            elif dtype == "int":
                df[col] = pd.to_numeric(df[col], errors='coerce').astype('Int64')  # Convert to nullable integer, preserving NaN
            else:
                df[col] = df[col].astype(dtype)
    
    # Drop duplicate columns keeping only the first occurrence
    df = df.loc[:, ~df.columns.duplicated()]
    return df

# json to parquet
def json_to_parquet(data_filename: str, name: str) -> str:
    df = pd.read_json(data_filename)
    
    # Convert DataFrame to Arrow Table
    table = pa.Table.from_pandas(df)
    # clean data
    df = clean_data(
        name=name,
        df=df
    )
    # Write Arrow Table to Parquet file
    parquet_filename = data_filename.replace('.json', '.parquet')
    pq.write_table(table, parquet_filename)

    return parquet_filename

# due to scrapy limitation, multiple processes are being used
def crawl_spider(spider_cls, mode, name, data_filename):
    # Add the output settings for JSON file
    settings = spider_cls.custom_settings
    settings['FEED_URI'] = data_filename
    process = CrawlerProcess(settings=settings)
    process.crawl(spider_cls, mode=mode)
    process.start()

    parquet_filename = json_to_parquet(
        data_filename=data_filename, 
        name=name
    )
    # Extract year, month, and day from the current date
    today = datetime.today()
    year = today.strftime('%Y')
    month = today.strftime('%m')
    day = today.strftime('%d')

    object_name = f'{name}/year={year}/month={month}/day={day}/mode={mode}/{os.path.basename(parquet_filename)}'
    # upload file
    s3_client = boto3.client('s3')
    try:
        s3_client.upload_file(
            parquet_filename, 
            config['bucketName'],
            object_name
        )
        print(f'<LOG>{object_name}: upload successful')
    except Exception as e:
        print(f'<LOG>Upload failed for {parquet_filename}: {e}')

def main():
    # create data dir
    DATA_DIR = 'data'
    if not os.path.exists(DATA_DIR):
        os.mkdir(DATA_DIR)

    # set env variables
    NAME = os.environ.get('NAME', default='apartments')

    week_of_year = datetime.today().isocalendar()[1]
    MODE = 'full' if week_of_year % 4 == 0 else 'partial'

    TODAY = datetime.today().strftime('%Y-%m-%d')

    # list of available spiders
    available_spiders = {
        'houses': HouseSpyder, 
        'apartments': ApartmentSpyder, 
        'cars': CarSpyder
    }
    
    # prepare and start scraping
    spider_cls = available_spiders[NAME]
    
    print(f'<LOG> {TODAY} Starting crawling for {NAME} - mode: {MODE}')
    data_filename = f'{DATA_DIR}/{NAME}_{TODAY}_{MODE}.json'
    crawl_spider(spider_cls, MODE, NAME, data_filename)

if __name__ == "__main__":
    main()