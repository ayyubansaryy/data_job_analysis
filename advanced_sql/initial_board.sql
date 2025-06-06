/*
INSERT INTO job_applied(
    job_id,
    application_sent_date,
    custom_resume,
    resume_file_name,
    cover_letter_sent,
    cover_letter_file_name,
    status
)

VALUES 
(
    1,
    '2024-02-01',
    true,
    'resume_01.pdf',
    true,
    'cover_letter_01.pdf',
    'submitted'
),
(
    2,
    '2024-02-04',
    false,
    'resume_02.pdf',
    false,
    NULL,
    'submitted'
),
(
    3,
    '2024-02-08',
    true,
    'resume_03.pdf',
    true,
    'cover_letter_03.pdf',
    'interview scheduled'
),
(
    4,
    '2024-02-08',
    true,
    'resume_03.pdf',
    false,
    NULL,
    'rejected'
);


SELECT *
FROM job_applied

ALTER TABLE job_applied
ADD contact VARCHAR(50);

ALTER TABLE job_applied
RENAME COLUMN contact TO contact_name;

UPDATE job_applied
SET contcat = 'Shima Das'
WHERE job_id = 1;

*/


SELECT
    job_title_short AS job,
    job_location AS location, 
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST' AS date_time,
    EXTRACT (MONTH FROM job_posted_date) AS date_month
    

FROM job_postings_fact

LIMIT 10;


SELECT
    COUNT (job_id) AS job_posted_count,
    EXTRACT (MONTH FROM job_posted_date) AS job_month

FROM job_postings_fact

WHERE
    job_title_short = 'Data Analyst'

GROUP BY job_month

ORDER BY
    job_posted_count DESC;


-- TIME PP 01 ----------------------------------------------

SELECT 
    job_schedule_type,
    AVG (salary_year_avg) AS yearly_avg,
    AVG (salary_hour_avg) AS hourly_avg
    

FROM job_postings_fact

WHERE
    EXTRACT (MONTH FROM job_posted_date) >= 6
    AND 
    EXTRACT (DAY FROM job_posted_date) >= 1

GROUP BY
    job_schedule_type;


-- Self PP 01 ----------------------------------------------
SELECT 
    job_dim.job_id,
    job_dim.job_title_short,
    job_dim.salary_year_avg,
    EXTRACT (MONTH FROM job_posted_date) AS posted_month,
    EXTRACT (DAY FROM job_posted_date) AS posted_day,

    -- show after left join with 'company_dim'
    company_dim.name AS company_name
    
FROM job_postings_fact AS job_dim

LEFT JOIN company_dim ON 
    company_dim.company_id = job_dim.company_id

WHERE
    EXTRACT (MONTH FROM job_posted_date) = 6
    AND 
    EXTRACT (DAY FROM job_posted_date) BETWEEN 1 AND 10
    AND
    salary_year_avg IS NOT NULL
    AND
    job_title_short = 'Data%Analyst'

ORDER BY
    salary_year_avg DESC;


-- TIME PP 02 ----------------------------------------------

SELECT
    COUNT (job_id) AS job_posted_count,
    EXTRACT (MONTH FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York') AS job_month

FROM job_postings_fact

GROUP BY
    job_month

ORDER BY
    job_posted_count;


-- TIME PP 03 ----------------------------------------------

SELECT DISTINCT --> removing duplicates (GROUP BY is not needed)
    job_dim.company_id,
    company_dim.name AS company_name,
    job_dim.job_health_insurance

FROM job_postings_fact AS job_dim

LEFT JOIN company_dim ON 
    company_dim.company_id = job_dim.company_id

WHERE
    job_dim.job_health_insurance = TRUE
    AND
    EXTRACT (MONTH FROM job_dim.job_posted_date) BETWEEN 4 AND 6

ORDER BY
    company_name ASC


-- Create new tables for each month ------------------

-- January
CREATE TABLE jobs_january AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT (MONTH FROM job_posted_date) = 1;

-- February
CREATE TABLE jobs_february AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT (MONTH FROM job_posted_date) = 2;

-- March
CREATE TABLE jobs_march AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT (MONTH FROM job_posted_date) = 3;


-- CASE WHEN PP --------------------------------------------

SELECT
    COUNT(job_id) AS number_of_jobs,
    CASE
        WHEN salary_year_avg >=100000 THEN 'High'
        WHEN salary_year_avg BETWEEN 40000 AND 99999 THEN 'Medium'
        ELSE 'Low'
    END AS salary_category

FROM job_postings_fact

WHERE
    salary_year_avg IS NOT NULL

GROUP BY
    salary_category

ORDER BY
    number_of_jobs DESC;


-- Sub Query Example ---------------------------------------

SELECT *

FROM (
    SELECT *
    FROM job_postings_fact
    WHERE
        EXTRACT (MONTH FROM job_posted_date) = 1
) AS jobs_january;


-- CTE Example --------------------------------------------

WITH jobs_january AS ( -- CTE starts here
    SELECT *
    FROM job_postings_fact
    WHERE
        EXTRACT (MONTH FROM job_posted_date) = 1 -- CTE ends here
) 

SELECT *

FROM jobs_january

WHERE
    job_title_short = 'Data Analyst' -- adding conditions (not mandatory)
    AND salary_year_avg IS NOT NULL

ORDER BY
    salary_year_avg DESC;


-- CTE & SubQuery PP 01 ------------------------------------

/*
Problem:: Identify the top 5 skills that are most frequently 
mentioned in job postings. Use a subquery to find the skill IDs 
with the highest counts in the 'skills_job_dim' table and then 
join this result with the 'skills_dim' table to get the skill names. 
*/

WITH skill_jobs_count AS (
    SELECT
        skill_id,
        COUNT(job_id) AS jobs_number
    FROM 
        skills_job_dim
    GROUP BY
        skill_id
)

SELECT 
    skill_jobs_count.skill_id,
    skills_dim.skills AS skill_name,
    skill_jobs_count.jobs_number,
    skills_dim.type AS skill_type

FROM skill_jobs_count

LEFT JOIN skills_dim ON
    skills_dim.skill_id = skill_jobs_count.skill_id

ORDER BY 
    jobs_number DESC

LIMIT 5;


-- CTE & SubQuery PP 02 ------------------------------------

WITH company_jobs_count AS (
    SELECT
        company_id,
        COUNT(*) AS jobs_number -- / 'COUNT (job_id) AS jobs_number' does the same thing
    FROM 
        job_postings_fact
    GROUP BY
        company_id
    ORDER BY
        company_id ASC
)
SELECT 
    company_jobs_count.company_id,
    company_dim.name AS company_name,
    company_jobs_count.jobs_number,
    CASE
    /*  adding a new column below named company category 
        by incorporating CASE expression.   */
        WHEN company_jobs_count.jobs_number > 50 THEN 'Large'
        WHEN company_jobs_count.jobs_number BETWEEN 10 AND 50 THEN 'Medium'
        ELSE 'Small'
    END AS company_category

FROM company_dim

LEFT JOIN company_jobs_count ON
    company_dim.company_id = company_jobs_count.company_id

-- must use order by company_id to see for sure that all the companies are included
ORDER BY
    company_dim.company_id ASC

LIMIT 1000;















