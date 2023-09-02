import scrapy
import re
from datetime import datetime, timedelta

class BaseSpyder(scrapy.Spider):

    custom_settings = {
        'DOWNLOAD_DELAY': 0.1,
        'CONCURRENT_REQUESTS': 500,
        'CONCURRENT_REQUESTS_PER_DOMAIN': 500,
        'CONCURRENT_REQUESTS_PER_IP': 500,
        'LOG_LEVEL': 'INFO',
        'COOKIES_ENABLED': False
    }

    def parse(self, response):
        class_executor_name = type(self).__name__
        if self.mode == 'partial':
            try:
                publish_date = response.css('li.icon-time::text').get()
                if publish_date.startswith('Objava'):
                    publish_date = datetime.strptime(
                        publish_date.replace('Objava ', '').strip(),
                        '%d.%m.%Y.'
                    )
                    self.logger.info(f'Fetched first data on the page is {publish_date}')
                    n_days_ago = datetime.now() - timedelta(days=8)

                    if publish_date <= n_days_ago:
                        self.logger.info(f'Skipping url: {response.url}')
                        return  # skip page

            except AttributeError as e:
                self.logger.info(f'Cannot find published date for page {response.url}: {e}.. Collecting data')
       
        self.logger.info(f'Fetching url: {response.url}')
        hrefs = response.css('a.result::attr(href)').getall()
        if class_executor_name == 'CarSpyder':
            zupanije = response.css('li.icon-marker::text').getall()
            for href, zupanija in zip(hrefs, zupanije):
                yield response.follow(href, self.parse_content, cb_kwargs={"zupanija": zupanija})
        else:
            yield from response.follow_all(hrefs, self.parse_content)
        
        try:
            next_page = response.css('ul.pagination a:contains(">")::attr(href)').get()
            if next_page is not None:
                yield response.follow(next_page, callback=self.parse)
        except Exception as e:
            self.logger.error(f'Exception! {e}')
    
    def parse_content(self, response, zupanija: str = None):
        data_dict = {
            'URL': response.url,
            'Županija': zupanija
        }

        try:
            div_price = response.css('div.price')
            price = re.sub(r'[^0-9]', '', div_price.css('span::text').get())
            data_dict['Cijena'] = price
        except:
            data_dict['Cijena'] = None

        try:
            div_published = response.css('div.published')[0]
            published_text = div_published.css('::text').getall()
            id = published_text[1]
            _, objava, prikaz = re.split(r'I|\|', published_text[-1])
            data_dict['ID'] = id
            data_dict['Objavljeno'] = objava.split(':', maxsplit=1)[-1].strip('\xa0 ')
            data_dict['Broj_Prikaza'] = prikaz.split(':')[-1].strip(' puta')
        except:
            data_dict['ID'] = None
            data_dict['Objavljeno'] = None
            data_dict['Broj_Prikaza'] = None

        try:
            description = response.css('div.oglas_description::text').get()
            data_dict['Opis'] = description
        except:
            data_dict['Opis'] = None

        div_features = response.css('div.features-wrapper')
        for div in div_features:
            uls = div.css('ul')
            for ul in uls:
                li_labels = ul.css('li.labela')
                li_values = ul.css('li:not(.labela)')
                for label, value in zip(li_labels, li_values):
                    label_txt = label.css('::text').get().strip().replace('\r', '').replace('\n', '; ')
                    value_txt = value.css('::text').get().strip().replace('\r', '').replace('\n', '; ')
                    data_dict[label_txt] = value_txt

        
        yield data_dict


class CarSpyder(BaseSpyder):

    name = 'cars'
    start_urls = [
        'https://www.index.hr/oglasi/osobni-automobili/gid/27?pojamZup=-2&tipoglasa=1&sortby=1&elementsNum=100&grad=0&naselje=0&cijenaod=0&cijenado=15750000&num=1',
    ]


class ApartmentSpyder(BaseSpyder):

    name = 'apartments'
    start_urls = [
        'https://www.index.hr/oglasi/prodaja-stanova/gid/3278?pojamZup=-2&tipoglasa=1&sortby=1&elementsNum=100&grad=0&naselje=0&cijenaod=0&cijenado=15000000&num=1',
    ]


class HouseSpyder(BaseSpyder):

    name = 'houses'
    start_urls = [
        'https://www.index.hr/oglasi/prodaja-kuca/gid/3276?pojamZup=-2&tipoglasa=1&sortby=1&elementsNum=100&grad=0&naselje=0&cijenaod=0&cijenado=35000000&num=1',
    ]