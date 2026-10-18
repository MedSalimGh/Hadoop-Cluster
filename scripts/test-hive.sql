SHOW DATABASES;
CREATE DATABASE IF NOT EXISTS university_hive;
USE university_hive;
CREATE TABLE IF NOT EXISTS course (id INT, title STRING, credits INT);
INSERT INTO course VALUES (1, 'Big Data Architecture', 4);
SELECT * FROM course;
