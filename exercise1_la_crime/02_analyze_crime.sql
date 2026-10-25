-- ==============================================================================
-- Workload 1: Los Angeles Crime Data Analysis (1M+ Records)
-- Architecture: Apache Hadoop 3.3.6 & Apache Hive 4.0.1
-- Engine: MapReduce (MR3 Execution Framework)
-- Database: crime_data_db
-- ==============================================================================

USE crime_data_db;

-- ------------------------------------------------------------------------------
-- 1. View a Few Records
-- ------------------------------------------------------------------------------
SELECT 
    dr_no, 
    date_occ, 
    area_name, 
    crm_cd_desc, 
    vict_age, 
    vict_sex, 
    weapon_desc
FROM crime_data_raw
WHERE dr_no != 'DR_NO'
LIMIT 10;

-- ------------------------------------------------------------------------------
-- 2. Total Crimes Reported
-- ------------------------------------------------------------------------------
SELECT 
    count(*) AS total_crimes_reported,
    count(DISTINCT dr_no) AS distinct_crimes_reported
FROM crime_data_raw
WHERE dr_no != 'DR_NO';

-- ------------------------------------------------------------------------------
-- 3. Crimes by Area (Ranked descending)
-- ------------------------------------------------------------------------------
SELECT 
    area_name, 
    count(*) AS crime_count
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND area_name IS NOT NULL AND area_name != ''
GROUP BY area_name
ORDER BY crime_count DESC;

-- ------------------------------------------------------------------------------
-- 4. Most Common Crime Descriptions (Top 10)
-- ------------------------------------------------------------------------------
SELECT 
    crm_cd_desc, 
    count(*) AS crime_count
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND crm_cd_desc IS NOT NULL AND crm_cd_desc != ''
GROUP BY crm_cd_desc
ORDER BY crime_count DESC
LIMIT 10;

-- ------------------------------------------------------------------------------
-- 5. Crime Trends by Year
-- ------------------------------------------------------------------------------
SELECT 
    substr(date_occ, 7, 4) AS crime_year, 
    count(*) AS crime_count
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND date_occ IS NOT NULL AND length(date_occ) >= 10
GROUP BY substr(date_occ, 7, 4)
ORDER BY crime_year ASC;

-- ------------------------------------------------------------------------------
-- 6. Filter Crimes with a Specific Weapon
-- ------------------------------------------------------------------------------
-- 6A: Identify Top 10 Most Frequent Weapons
SELECT 
    weapon_desc, 
    count(*) AS weapon_incident_count
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND weapon_desc IS NOT NULL AND trim(weapon_desc) != ''
GROUP BY weapon_desc
ORDER BY weapon_incident_count DESC
LIMIT 10;

-- 6B: Filter Incidents Involving "HAND GUN"
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
LIMIT 10;

-- 6C: Aggregate Total Hand Gun Crimes
SELECT count(*) AS total_hand_gun_crimes
FROM crime_data_raw
WHERE dr_no != 'DR_NO' AND weapon_desc = 'HAND GUN';

-- ------------------------------------------------------------------------------
-- 7. Victim Age Groups
-- ------------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN cast(vict_age as INT) <= 0 OR vict_age IS NULL OR trim(vict_age) = '' THEN 'Unknown / Unrecorded'
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
        WHEN cast(vict_age as INT) <= 0 OR vict_age IS NULL OR trim(vict_age) = '' THEN 'Unknown / Unrecorded'
        WHEN cast(vict_age as INT) < 18 THEN 'Under 18 (Minors)'
        WHEN cast(vict_age as INT) BETWEEN 18 AND 24 THEN '18-24 (Young Adults)'
        WHEN cast(vict_age as INT) BETWEEN 25 AND 34 THEN '25-34 (Adults 25-34)'
        WHEN cast(vict_age as INT) BETWEEN 35 AND 44 THEN '35-44 (Adults 35-44)'
        WHEN cast(vict_age as INT) BETWEEN 45 AND 54 THEN '45-54 (Adults 45-54)'
        WHEN cast(vict_age as INT) BETWEEN 55 AND 64 THEN '55-64 (Adults 55-64)'
        ELSE '65+ (Seniors)'
    END
ORDER BY victim_count DESC;
