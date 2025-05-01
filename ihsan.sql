-- optimized
SELECT region_name, ROUND(AVG(trip_count), 3) AS avg_monthly_trips
FROM (
  SELECT 
    r.name AS region_name,
    FORMAT_DATE('%Y-%m', t.start_date) AS trip_month,
    COUNT(*) AS trip_count
  FROM 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` t
  JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` s
  ON 
    t.start_station_name = s.name
  JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` r
  ON 
    s.region_id = r.region_id
  GROUP BY 
    r.name, s.name, trip_month
)
GROUP BY region_name
ORDER BY avg_monthly_trips DESC;

-- unoptimized, aggregated
WITH monthly_trip_counts AS (
  SELECT 
    start_station_name,
    FORMAT_DATE('%Y-%m', start_date) AS trip_month,
    COUNT(*) AS trip_count
  FROM 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  GROUP BY 
    start_station_name, trip_month
)

SELECT r.name AS region_name, ROUND(AVG(mtc.trip_count), 3) AS avg_monthly_trips
FROM monthly_trip_counts mtc
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` s 
ON mtc.start_station_name = s.name
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` r 
ON s.region_id = r.region_id
GROUP BY region_name
ORDER BY avg_monthly_trips DESC;

-- Departures on weekends grouped by regions
SELECT r.name AS region_name, COUNT(*) AS weekend_departures
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` t
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` s
ON t.start_station_name = s.name
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` r
ON s.region_id = r.region_id
WHERE EXTRACT(DAYOFWEEK FROM t.start_date) IN (1, 7)
GROUP BY region_name
ORDER BY weekend_departures DESC;
