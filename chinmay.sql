-- Query 1: Find the most popular 20 routes (start to end) in the bikeshare dataset

SELECT
    start_station_name,
    end_station_name,
    COUNT(*) AS trip_count
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
WHERE start_station_name IS NOT NULL
AND end_station_name IS NOT NULL
GROUP BY start_station_name, end_station_name
ORDER BY trip_count DESC
LIMIT 20;


-- Query 2: Find the most popular stations for trips during rush hour, alongside their capacity and distribution
-- of trips departing from during morning and night

SELECT
    si.name AS station_name,
    si.capacity,
    COUNT(*) AS rush_hour_trips,
    COUNTIF(EXTRACT(HOUR FROM t.start_date) BETWEEN 7 AND 9) AS morning_trips,
    COUNTIF(EXTRACT(HOUR FROM t.start_date) BETWEEN 16 AND 18) AS evening_trips
FROM
    bigquery-public-data.san_francisco_bikeshare.bikeshare_trips t
JOIN
    bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info si ON CAST(t.start_station_id AS STRING) = si.station_id
WHERE
    (EXTRACT(HOUR FROM t.start_date) BETWEEN 7 AND 9 OR
     EXTRACT(HOUR FROM t.start_date) BETWEEN 16 AND 18)
    AND EXTRACT(DAYOFWEEK FROM t.start_date) BETWEEN 2 AND 6  -- Monday(2) to Friday(6)
GROUP BY
    si.name, si.capacity
ORDER BY
    rush_hour_trips DESC
LIMIT 15;


-- Query 2 Optimized using CTEs and filtering early

WITH rush_hour_trips AS (
  SELECT
    CAST(start_station_id AS STRING) AS station_id,
    COUNT(*) AS total_trips,
    COUNTIF(EXTRACT(HOUR FROM start_date) BETWEEN 7 AND 9) AS am_trips,
    COUNTIF(EXTRACT(HOUR FROM start_date) BETWEEN 16 AND 18) AS pm_trips
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE
    (EXTRACT(HOUR FROM start_date) BETWEEN 7 AND 9 OR
     EXTRACT(HOUR FROM start_date) BETWEEN 16 AND 18)
    AND EXTRACT(DAYOFWEEK FROM start_date) BETWEEN 2 AND 6  -- Monday(2) to Friday(6)
  GROUP BY
    CAST(start_station_id AS STRING)
)
SELECT
  si.name AS station_name,
  si.capacity,
  rht.total_trips AS rush_hour_trips,
  rht.am_trips AS morning_trips,
  rht.pm_trips AS evening_trips
FROM
  rush_hour_trips rht
JOIN
  `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` si ON rht.station_id = si.station_id
ORDER BY
  rush_hour_trips DESC
LIMIT 15;

