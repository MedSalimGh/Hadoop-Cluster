#!/usr/bin/env bash
set -e

export HADOOP_HOME=/home/huser/hadoop-3.3.6
export HIVE_HOME=/home/huser/apache-hive-4.0.1-bin
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

OUTPUT_FILE="/vagrant/exercise1_la_crime/analysis_results.txt"
echo "=== Running LA Crime Data Analysis Queries ===" > "$OUTPUT_FILE"
date >> "$OUTPUT_FILE"

beeline -u jdbc:hive2://localhost:10000/crime_data_db -n huser --outputformat=table2 -e "
USE crime_data_db;

-- 1. View a Few Records
SELECT '--- 1. VIEW A FEW RECORDS ---' AS query_header;
SELECT dr_no, date_occ, area_name, crm_cd_desc, vict_age, vict_sex, weapon_desc
FROM crime_data_raw
WHERE dr_no != 'DR_NO'
LIMIT 10;

-- 2. Total Crimes Reported
SELECT '--- 2. TOTAL CRIMES REPORTED ---' AS query_header;
SELECT 
    count(*) AS total_crimes_reported,
    count(DISTINCT dr_no) AS distinct_crimes_reported
FROM crime_data_raw
WHERE dr_no != 'DR_NO';

-- 3. Crimes by Area
SELECT '--- 3. CRIMES BY AREA (TOP 25) ---' AS query_header;
SELECT 
    area_name, 
    count(*) AS crime_count
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND area_name IS NOT NULL AND area_name != ''
GROUP BY area_name
ORDER BY crime_count DESC;

-- 4. Most Common Crime Descriptions
SELECT '--- 4. MOST COMMON CRIME DESCRIPTIONS (TOP 10) ---' AS query_header;
SELECT 
    crm_cd_desc, 
    count(*) AS crime_count
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND crm_cd_desc IS NOT NULL AND crm_cd_desc != ''
GROUP BY crm_cd_desc
ORDER BY crime_count DESC
LIMIT 10;

-- 5. Crime Trends by Year
SELECT '--- 5. CRIME TRENDS BY YEAR ---' AS query_header;
SELECT 
    substr(date_occ, 7, 4) AS crime_year, 
    count(*) AS crime_count
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND date_occ IS NOT NULL AND length(date_occ) >= 10
GROUP BY substr(date_occ, 7, 4)
ORDER BY crime_year ASC;

-- 6. Filter Crimes with a Specific Weapon
SELECT '--- 6A. TOP 10 WEAPONS USED ---' AS query_header;
SELECT 
    weapon_desc, 
    count(*) AS weapon_incident_count
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND weapon_desc IS NOT NULL AND trim(weapon_desc) != ''
GROUP BY weapon_desc
ORDER BY weapon_incident_count DESC
LIMIT 10;

SELECT '--- 6B. FILTER CRIMES WITH WEAPON = HAND GUN ---' AS query_header;
SELECT 
    dr_no, 
    date_occ, 
    area_name, 
    crm_cd_desc, 
    weapon_desc, 
    vict_age, 
    vict_sex
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND weapon_desc = 'HAND GUN'
LIMIT 5;

SELECT '--- 6C. TOTAL HAND GUN CRIMES ---' AS query_header;
SELECT count(*) AS total_hand_gun_crimes
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND weapon_desc = 'HAND GUN';

-- 7. Victim Age Groups
SELECT '--- 7. VICTIM AGE GROUPS ---' AS query_header;
SELECT 
    CASE 
        WHEN cast(vict_age as INT) <= 0 OR vict_age IS NULL OR trim(vict_age) = '' THEN 'Unknown / Unrecorded (<=0 or NULL)'
        WHEN cast(vict_age as INT) < 18 THEN 'Under 18 (Minors)'
        WHEN cast(vict_age as INT) BETWEEN 18 AND 24 THEN '18-24 (Young Adults)'
        WHEN cast(vict_age as INT) BETWEEN 25 AND 34 THEN '25-34 (Adults 25-34)'
        WHEN cast(vict_age as INT) BETWEEN 35 AND 44 THEN '35-44 (Adults 35-44)'
        WHEN cast(vict_age as INT) BETWEEN 45 AND 54 THEN '45-54 (Adults 45-54)'
        WHEN cast(vict_age as INT) BETWEEN 55 AND 64 THEN '55-64 (Adults 55-64)'
        ELSE '65+ (Seniors)'
    END AS victim_age_group,
    count(*) AS victim_count
FROM crime_data_raw
WHERE dr_no != 'DR_NO'
GROUP BY 
    CASE 
        WHEN cast(vict_age as INT) <= 0 OR vict_age IS NULL OR trim(vict_age) = '' THEN 'Unknown / Unrecorded (<=0 or NULL)'
        WHEN cast(vict_age as INT) < 18 THEN 'Under 18 (Minors)'
        WHEN cast(vict_age as INT) BETWEEN 18 AND 24 THEN '18-24 (Young Adults)'
        WHEN cast(vict_age as INT) BETWEEN 25 AND 34 THEN '25-34 (Adults 25-34)'
        WHEN cast(vict_age as INT) BETWEEN 35 AND 44 THEN '35-44 (Adults 35-44)'
        WHEN cast(vict_age as INT) BETWEEN 45 AND 54 THEN '45-54 (Adults 45-54)'
        WHEN cast(vict_age as INT) BETWEEN 55 AND 64 THEN '55-64 (Adults 55-64)'
        ELSE '65+ (Seniors)'
    END
ORDER BY victim_count DESC;
" >> "$OUTPUT_FILE" 2>&1

echo "=== Analysis Queries Finished! Results saved to $OUTPUT_FILE ==="
