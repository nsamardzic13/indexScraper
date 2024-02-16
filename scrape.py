import os
import json
from datetime import datetime

import boto3
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from scrapy.crawler import CrawlerProcess

from index_scrapy.index_scrapy.spiders.index_spider import *


with open('config.json', 'r', encoding='utf-8') as f:
    config = json.load(f) 

# json to parquet
def json_to_parquet(data_filename: str) -> str:
    df = pd.read_json(data_filename)

    # Convert DataFrame to Arrow Table
    table = pa.Table.from_pandas(df)

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

    parquet_filename = json_to_parquet(data_filename)
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