# Cleaning, Transformation, and Analytical SQL

## Timestamp conversion

Hive's direct string-to-timestamp conversion expects supported timestamp formats; alternative formats may require parsing functions or a SerDe timestamp format configuration. First inspect actual examples and the Hive version.

A common ISO-like value such as `2024-08-15 13:45:00` may be converted with:

```sql
CAST(NULLIF(TRIM(start_time), '') AS TIMESTAMP)
```

`NULLIF` availability should be verified on older versions. A more portable alternative may be:

```sql
CASE
  WHEN start_time IS NULL OR TRIM(start_time) = '' THEN CAST(NULL AS TIMESTAMP)
  ELSE CAST(TRIM(start_time) AS TIMESTAMP)
END
```

This only works if the source format is accepted by the engine. If values look like `08/15/2024 01:45:00 PM`, use a supported explicit parsing function and test it on representative rows. Do not silently accept a conversion that turns many values into NULL.

Check conversion quality before publishing the cleaned table:

```sql
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN start_time IS NOT NULL AND TRIM(start_time) <> ''
            AND <parsed_start_time> IS NULL THEN 1 ELSE 0 END) AS bad_start_time_rows
FROM <database>.divvy_trips_raw;
```

Replace `<parsed_start_time>` with the tested expression. Repeat for `end_time`. Some Hive versions/functions do not support all SQL conveniences; test first.

## String normalization

For station names:
```sql
UPPER(TRIM(start_station_name))
```

Decide whether blank station names should become NULL. Do not convert all missing values to strings such as `'NULL'`. Preserve source fields if the normalization could erase meaningful distinctions.

## Duration metrics

For trip duration in minutes, define the metric explicitly. A typical expression for timestamp columns is:

```sql
(UNIX_TIMESTAMP(end_time) - UNIX_TIMESTAMP(start_time)) / 60.0
```

Verify function behavior and timestamp timezone settings. For fractional precision, consider whether second-level precision is enough. Check nulls and negative durations. Do not silently clamp negative durations to zero.

Useful data-quality checks:
- null start/end timestamps;
- end before start;
- zero-duration trips;
- implausibly long durations;
- missing user/customer category;
- missing bike type;
- blank station names.

For mean duration, decide whether invalid/negative durations are excluded and state that in the report.

## Analysis patterns

Use the actual field names discovered from the CSV. These are patterns, not a promise that the example identifiers exist.

Average trip duration:
```sql
SELECT AVG((UNIX_TIMESTAMP(end_time) - UNIX_TIMESTAMP(start_time)) / 60.0)
       AS avg_trip_minutes
FROM <database>.divvy_trips_cleaned
WHERE start_time IS NOT NULL
  AND end_time IS NOT NULL
  AND end_time >= start_time;
```

Distinct bike types:
```sql
SELECT COUNT(DISTINCT bike_type) AS unique_bike_types
FROM <database>.divvy_trips_cleaned
WHERE bike_type IS NOT NULL;
```

Top start stations:
```sql
SELECT start_station_name, COUNT(*) AS trip_count
FROM <database>.divvy_trips_cleaned
WHERE start_station_name IS NOT NULL
GROUP BY start_station_name
ORDER BY trip_count DESC, start_station_name ASC
LIMIT 5;
```

Trips per month:
```sql
SELECT YEAR(start_time) AS trip_year,
       MONTH(start_time) AS trip_month,
       COUNT(*) AS trip_count
FROM <database>.divvy_trips_cleaned
WHERE start_time IS NOT NULL
GROUP BY YEAR(start_time), MONTH(start_time)
ORDER BY trip_year, trip_month;
```

Busiest starting hour:
```sql
SELECT HOUR(start_time) AS start_hour, COUNT(*) AS trip_count
FROM <database>.divvy_trips_cleaned
WHERE start_time IS NOT NULL
GROUP BY HOUR(start_time)
ORDER BY trip_count DESC, start_hour ASC
LIMIT 1;
```

Average duration by rider category:
```sql
SELECT <rider_category>, AVG(<duration_minutes>) AS avg_trip_minutes
FROM <database>.divvy_trips_cleaned
WHERE <valid_duration_predicate>
GROUP BY <rider_category>
ORDER BY <rider_category>;
```

Top routes:
```sql
SELECT start_station_name, end_station_name, COUNT(*) AS trip_count
FROM <database>.divvy_trips_cleaned
WHERE start_station_name IS NOT NULL
  AND end_station_name IS NOT NULL
GROUP BY start_station_name, end_station_name
ORDER BY trip_count DESC, start_station_name ASC, end_station_name ASC
LIMIT 10;
```

Longest duration for each start station:
```sql
SELECT start_station_name,
       MAX(<duration_minutes>) AS longest_trip_minutes
FROM <database>.divvy_trips_cleaned
WHERE start_station_name IS NOT NULL
  AND <valid_duration_predicate>
GROUP BY start_station_name
ORDER BY longest_trip_minutes DESC, start_station_name ASC;
```

Replace placeholders with tested expressions. If the requirement is to return the full trip row for the longest trip at each station, use a window function such as `ROW_NUMBER()` only after checking version support and tie semantics.

## LA Crime Data analytical definitions

- Total crimes reported: usually `COUNT(*)` after determining whether each row represents one report/incident.
- Crimes by area: group by the verified area field; decide how to present missing area values.
- Most common descriptions: group by the verified crime-description field, trim/canonicalize only if appropriate, and include a deterministic tie-breaker.
- Trends by year: extract year from the correct date field; distinguish report date from occurrence date if both exist.
- Specific weapon: inspect actual weapon-related field and value vocabulary; do not assume exact label casing or code semantics.
- Victim age groups: inspect age type, missing/zero/sentinel values, and assignment's intended bands. State bin boundaries explicitly and avoid silently treating invalid ages as real ages.

## General analytical best practices

- Define the denominator for every percentage or average.
- Distinguish records, incidents, bikes, stations, victims, and unique identifiers.
- Handle NULL and blank values intentionally.
- Use deterministic secondary sort keys for ranked results.
- Check whether dates are local time or UTC.
- Avoid over-interpreting correlation or descriptive trends as causation.
