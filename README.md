## Description

Index Scraper is a scrapy-based crawler used to scrape house, cars and apartments data from Croatian website [Index Oglasi](https://www.index.hr/oglasi/). It collects most important data, cleans it (a little bit :D), and ingesting it to BigQuery on Google Cloud. Make sure to add service_account.json file - standard json key file generated from IAM & Admin -> Service Accounts -> Keys.

Besides BigQuery, the script is also using GCP's Cloud Storage as a Data Lake to store raw parquet files.

## Environment setup

In this case, poetry is used to install all Python libraries needed to execute the code. It is also required to have virtual environment creatd in the project dir:

`poetry config virtualenvs.in-project true `

To install all the dependencies, use standard:

`pip install poetry `

## Scrape data

Note: Right now, code will only work correctly when scraping full dataset. If we want to add partial, we need to make sure query login in load_*.sql is handling MERGE statement accordingly. 

You can use scrape_data.sh script to crawl data.

Example: `cd index_scrapy && bash scrape_data.sh full`

If you are running commands manually, make sure you are in index_scrapy dir

Scrapy commands example:

* `scrapy crawl cars -O cars.json -a mode=full`
* `scrapy crawl apartments -O apartments.json -a mode=full`
* `scrapy crawl houses -O houses.json -a mode=full`
