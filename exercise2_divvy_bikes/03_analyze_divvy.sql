-- ==============================================================================
-- Workload 2: Divvy Bikes Trip Data Analysis (~800K Records)
-- Architecture: Apache Hadoop 3.3.6 & Apache Hive 4.0.1
-- Engine: MapReduce (MR3 Execution Framework)
-- Database: divvy_db
-- ==============================================================================

USE divvy_db;

-- ------------------------------------------------------------------------------
-- PART 3: DATA ANALYSIS
-- ------------------------------------------------------------------------------

-- Question 1: What is the average trip duration in minutes?
SELECT 
    '--- Q1: AVERAGE TRIP DURATION (MINUTES) ---' AS query_header;
SELECT 
    round(avg((unix_timestamp(end_time) - unix_timestamp(start_time)) / 60.0), 2) AS avg_duration_minutes,
    round(min((unix_timestamp(end_time) - unix_timestamp(start_time)) / 60.0), 2) AS min_duration_minutes,
    round(max((unix_timestamp(end_time) - unix_timestamp(start_time)) / 60.0), 2) AS max_duration_minutes
FROM divvy_trips_cleaned
WHERE end_time >= start_time;

-- Question 2: How many unique bike types are in the dataset?
SELECT 
    '--- Q2: UNIQUE BIKE TYPES ---' AS query_header;
SELECT 
    count(DISTINCT rideable_type) AS unique_bike_types_count
FROM divvy_trips_cleaned;

SELECT 
    rideable_type, 
    count(*) AS trip_count
FROM divvy_trips_cleaned
GROUP BY rideable_type
ORDER BY trip_count DESC;

-- Question 3: What are the top 5 most popular start stations?
SELECT 
    '--- Q3: TOP 5 MOST POPULAR START STATIONS ---' AS query_header;
SELECT 
    start_station_name, 
    count(*) AS trip_count
FROM divvy_trips_cleaned
WHERE start_station_name IS NOT NULL AND start_station_name != ''
GROUP BY start_station_name
ORDER BY trip_count DESC
LIMIT 5;

-- Question 4: What is the number of trips per month?
SELECT 
    '--- Q4: TRIPS PER MONTH ---' AS query_header;
SELECT 
    year(start_time) AS trip_year,
    month(start_time) AS trip_month,
    count(*) AS total_trips
FROM divvy_trips_cleaned
GROUP BY year(start_time), month(start_time)
ORDER BY trip_year, trip_month;

-- Question 5: What is the busiest hour of the day for starting a trip?
SELECT 
    '--- Q5: BUSIEST HOUR OF THE DAY ---' AS query_header;
SELECT 
    hour(start_time) AS trip_hour,
    count(*) AS trip_count
FROM divvy_trips_cleaned
GROUP BY hour(start_time)
ORDER BY trip_count DESC
LIMIT 1;

-- All 24 hours breakdown for reporting
SELECT 
    hour(start_time) AS trip_hour,
    count(*) AS trip_count
FROM divvy_trips_cleaned
GROUP BY hour(start_time)
ORDER BY trip_hour ASC;

-- Question 6: What is the average trip duration for "Subscribers" versus "Customers"?
SELECT 
    '--- Q6: AVG TRIP DURATION: SUBSCRIBERS VS CUSTOMERS ---' AS query_header;
SELECT 
    CASE 
        WHEN member_casual = 'member' THEN 'Subscriber (Annual Member)'
        WHEN member_casual = 'casual' THEN 'Customer (Casual Rider)'
        ELSE member_casual 
    END AS user_type,
    count(*) AS total_trips,
    round(avg((unix_timestamp(end_time) - unix_timestamp(start_time)) / 60.0), 2) AS avg_duration_minutes
FROM divvy_trips_cleaned
WHERE end_time >= start_time
GROUP BY member_casual;

-- Question 7: What are the top 10 most frequent trip routes?
SELECT 
    '--- Q7: TOP 10 MOST FREQUENT TRIP ROUTES ---' AS query_header;
SELECT 
    start_station_name,
    end_station_name,
    count(*) AS route_trip_count
FROM divvy_trips_cleaned
WHERE start_station_name IS NOT NULL AND start_station_name != ''
  AND end_station_name IS NOT NULL AND end_station_name != ''
GROUP BY start_station_name, end_station_name
ORDER BY route_trip_count DESC
LIMIT 10;

-- Question 8: What is the longest trip duration for each start station?
SELECT 
    '--- Q8: LONGEST TRIP DURATION PER START STATION (TOP 15) ---' AS query_header;
SELECT 
    start_station_name,
    round(max((unix_timestamp(end_time) - unix_timestamp(start_time)) / 60.0), 2) AS longest_trip_minutes
FROM divvy_trips_cleaned
WHERE start_station_name IS NOT NULL AND start_station_name != ''
  AND end_time >= start_time
GROUP BY start_station_name
ORDER BY longest_trip_minutes DESC
LIMIT 15;
