import os
import json
from datetime import datetime

import boto3
from scrapy.crawler import CrawlerProcess

from index_scrapy.index_scrapy.spiders.index_spider import *


with open('config.json', 'r') as f:
    config = json.load(f) 

# due to scrapy limitation, multiple processes are being used
def crawl_spider(spider_cls, mode, data_filename, object_name):
    # Add the output settings for JSON file
    settings = spider_cls.custom_settings
    settings['FEED_URI'] = data_filename
    process = CrawlerProcess(settings=settings)
    process.crawl(spider_cls, mode=mode)
    process.start()

    # upload file
    s3_client = boto3.client('s3')
    try:
        s3_client.upload_file(
            data_filename, 
            config['bucketName'],
            object_name
        )
    except Exception as e:
        print(f'Upload failed for {data_filename}: {e}')

def main():
    # create data dir
    DATA_DIR = 'data'
    if not os.path.exists(DATA_DIR):
        os.mkdir(DATA_DIR)

    # set env variables
    NAME = os.environ.get('NAME', default='apartments')

    week_of_year = datetime.today().isocalendar()[1]
    MODE = 'full' if week_of_year % 4 == 0 or week_of_year == 6 else 'partial'

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
    object_name = f'{NAME}/{os.path.basename(data_filename)}'
    crawl_spider(spider_cls, MODE, data_filename, object_name)

if __name__ == "__main__":
    main()