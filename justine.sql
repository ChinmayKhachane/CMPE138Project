-- Query 1: Average trip duration between 'Subscribers' and 'Customers'
SELECT
  subscriber_type,
  COUNT(*) AS total_trips,
  AVG(TIMESTAMP_DIFF(end_date, start_date, MINUTE)) AS avg_duration
FROM bigquery-public-data.san_francisco_bikeshare.bikeshare_trips
WHERE subscriber_type IN ('Subscriber', 'Customer')
GROUP BY subscriber_type;

-- Query 2 (Unoptimized): Finding the most popular start station per region
WITH trip_counts AS (
  SELECT start_station_id, start_station_name,
  COUNT(*) AS trip_count FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  GROUP BY start_station_id, start_station_name
),
region_stations AS (
  SELECT
    (SELECT name FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` r
     WHERE r.region_id = s.region_id) AS region_name, s.station_id FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` s
),
stations_with_regions AS (
  SELECT rs.region_name, tc.start_station_name, tc.trip_count FROM trip_counts tc
  JOIN region_stations rs ON CAST(tc.start_station_id AS STRING) = rs.station_id
),
ranked_stations AS (
  SELECT region_name, start_station_name, trip_count, 
  ROW_NUMBER() OVER (PARTITION BY region_name ORDER BY trip_count DESC) AS rank FROM stations_with_regions
)
SELECT region_name, start_station_name, trip_count FROM ranked_stations
  WHERE rank = 1
  ORDER BY region_name;

  -- Query 2 (Optimzed):
SELECT
  r.name AS region_name,
  t.start_station_name,
  COUNT(*) AS trip_count
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` t
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` s
  ON CAST(t.start_station_id AS STRING) = s.station_id
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` r
  ON s.region_id = r.region_id
GROUP BY region_name, t.start_station_name
QUALIFY ROW_NUMBER() OVER (PARTITION BY region_name ORDER BY COUNT(*) DESC) = 1
ORDER BY region_name