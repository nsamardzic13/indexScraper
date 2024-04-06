variable "query_cars" {
  type    = string
  default = <<EOT
  WITH current_prices AS (
    SELECT
        url,
        id,
        cijena,
        partitiondate as partitiondate
    FROM \"tf-indexads-database\".\"cars\"
), previous_prices as (
    SELECT
        id,
        cijena,
        min(partitiondate) as partitiondate
    FROM \"tf-indexads-database\".\"cars\"
    group by 1,2
)
SELECT 
    current.url,
    current.id,
    round((current.cijena - previous.cijena) / previous.cijena * 100, 2) as percent_change,
    current.cijena AS current_cijena,
    previous.cijena AS previous_cijena,
    current.partitiondate AS latest_date,
    previous.partitiondate as previous_date
FROM current_prices AS current
INNER JOIN previous_prices AS previous 
    ON current.id = previous.id
WHERE
    current.cijena != previous.cijena
    and date_parse(current.partitiondate, '%Y-%m-%d') >= current_date - interval '7' day
    and current.partitiondate > previous.partitiondate
    and round(current.cijena / previous.cijena, 2) > 0.2
ORDER BY 
    percent_change,
    current.partitiondate desc
;
EOT
}

variable "query_apartments" {
  type    = string
  default = <<EOT
  WITH current_prices AS (
    SELECT
        url,
        id,
        cijena,
        partitiondate as partitiondate
    FROM \"tf-indexads-database\".\"apartments\"
), previous_prices as (
    SELECT
        id,
        cijena,
        min(partitiondate) as partitiondate
    FROM \"tf-indexads-database\".\"apartments\"
    group by 1,2
)
SELECT 
    current.url,
    current.id,
    round((current.cijena - previous.cijena) / previous.cijena * 100, 2) as percent_change,
    current.cijena AS current_cijena,
    previous.cijena AS previous_cijena,
    current.partitiondate AS latest_date,
    previous.partitiondate as previous_date
FROM current_prices AS current
INNER JOIN previous_prices AS previous 
    ON current.id = previous.id
WHERE
    current.cijena != previous.cijena
    and date_parse(current.partitiondate, '%Y-%m-%d') >= current_date - interval '7' day
    and current.partitiondate > previous.partitiondate
    and round(current.cijena / previous.cijena, 2) > 0.2
ORDER BY 
    percent_change,
    current.partitiondate desc
;
EOT
}

variable "query_houses" {
  type    = string
  default = <<EOT
  WITH current_prices AS (
    SELECT
        url,
        id,
        cijena,
        partitiondate as partitiondate
    FROM \"tf-indexads-database\".\"houses\"
), previous_prices as (
    SELECT
        id,
        cijena,
        min(partitiondate) as partitiondate
    FROM \"tf-indexads-database\".\"houses\"
    group by 1,2
)
SELECT 
    current.url,
    current.id,
    round((current.cijena - previous.cijena) / previous.cijena * 100, 2) as percent_change,
    current.cijena AS current_cijena,
    previous.cijena AS previous_cijena,
    current.partitiondate AS latest_date,
    previous.partitiondate as previous_date
FROM current_prices AS current
INNER JOIN previous_prices AS previous 
    ON current.id = previous.id
WHERE
    current.cijena != previous.cijena
    and date_parse(current.partitiondate, '%Y-%m-%d') >= current_date - interval '7' day
    and current.partitiondate > previous.partitiondate
    and round(current.cijena / previous.cijena, 2) > 0.2
ORDER BY 
    percent_change,
    current.partitiondate desc
;
EOT
}