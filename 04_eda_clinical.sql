/* =========================================================
   Exploratory Data Analysis (EDA) – SmileSync Database
   Purpose: Analyze patient demographics, clinical patterns,
         visit behavior, diagnosis trends, and treatment utilization
   Database: MySQL
   ========================================================= */
--- Note:
-- This EDA focuses on clinical workflow, patient journey,
-- and provider utilization rather than purely descriptive statistics.

--- SECTION 1: PATIENT DEMOGRAPHICS 
-- Total number of patients
SELECT COUNT(*) AS total_patients
FROM patient_info;

-- Gender distribution of patients
SELECT 
	gender, 
    COUNT(*) AS patient_count 
FROM patient_info
GROUP BY gender;
   
-- Age distribution (calculated from DOB)
SELECT
    CASE
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) < 18 THEN '<18'
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 18 AND 35 THEN '18–35'
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 36 AND 55 THEN '36–55'
        ELSE '56+'
    END AS age_group,
    COUNT(*) AS patients
FROM patient_info
GROUP BY age_group
ORDER BY age_group;
   
-- Patient distribution by location
SELECT
    address,
    COUNT(*) AS patient_count
FROM patient_info
WHERE address IS NOT NULL
GROUP BY address
ORDER BY patient_count DESC;


--- SECTION 2: VISIT & UTILIZATION PATTERNS   
-- Visits by month
SELECT
    DATE_FORMAT(Visit_Date, '%m-%Y') AS month,
    COUNT(*) AS visits
FROM consultation_info
GROUP BY month
ORDER BY month;

-- Avg treatments per visit
SELECT ROUND(AVG(t_cnt), 2) AS avg_treatments
FROM (
    SELECT c.CID, COUNT(t.TID) AS t_cnt
    FROM consultation_info c
    JOIN diagnosis_info d 
		ON c.cid = d.cid
	JOIN treatment_info t 
		ON d.did = t.did
    GROUP BY c.cid
) x;
  

---  SECTION 3: CLINICAL PATTERNS
-- Frequently reported chief complaints
SELECT 
	chief_complaint, 
    COUNT(*) AS freq
FROM consultation_info
WHERE Chief_Complaint IS NOT NULL
GROUP BY chief_complaint
ORDER BY freq DESC
LIMIT 5;
 
 -- Diagnosis frequency
SELECT 
	diagnosis, 
    COUNT(*) AS cases
FROM diagnosis_info
GROUP BY diagnosis
ORDER BY cases DESC;

-- Diagnoses that resulted in treatment vs not
WITH dx_summary AS (
    SELECT
        d.DID,
        d.diagnosis,
        CASE 
			WHEN t.TID IS NOT NULL THEN 1 ELSE 0 
		END AS treated
    FROM diagnosis_info d
    LEFT JOIN treatment_info t 
		ON d.DID = t.DID
)
SELECT
    diagnosis,
    COUNT(*) AS total_cases,
    SUM(treated) AS treated_cases,
    ROUND(SUM(treated) / COUNT(*) * 100, 2) AS treatment_rate_pct
FROM dx_summary
GROUP BY diagnosis
ORDER BY treatment_rate_pct DESC;


--- SECTION 4: CARE DELIVERY & PATIENT JOURNEY ANALYSIS  
-- Patient journey funnel: visits → diagnoses → treatments
WITH journey AS (
    SELECT
        p.PID,
        COUNT(DISTINCT c.CID) AS visits,
        COUNT(DISTINCT d.DID) AS diagnoses,
        COUNT(DISTINCT t.TID) AS treatments
    FROM patient_info p
    LEFT JOIN consultation_info c 
			ON p.PID = c.PID
    LEFT JOIN diagnosis_info d 
			ON c.CID = d.CID
    LEFT JOIN treatment_info t 
			ON d.DID = t.DID
    GROUP BY p.PID
)
SELECT
    COUNT(*) AS total_patients,
    SUM(visits > 0) AS patients_with_visits,
    SUM(diagnoses > 0) AS patients_with_diagnosis,
    SUM(treatments > 0) AS patients_with_treatment
FROM journey;

-- Average delay between consultation and treatment by treatment type
SELECT
    tc.Treatment,
    ROUND(AVG(DATEDIFF(t.Treatment_Date, c.Visit_Date)), 1) 
		AS avg_days_to_treatment,
    COUNT(*) AS total_cases
FROM consultation_info c
JOIN diagnosis_info d 
    ON c.CID = d.CID
JOIN treatment_info t 
    ON d.DID = t.DID
JOIN treatment_costs tc 
    ON t.TCID = tc.TCID
WHERE t.Treatment_Date IS NOT NULL
GROUP BY tc.Treatment
ORDER BY avg_days_to_treatment DESC;

-- Diagnosis burden by age group
WITH age_groups AS (
    SELECT
        p.PID,
        d.diagnosis,
        CASE
            WHEN TIMESTAMPDIFF(YEAR, p.DOB, CURDATE()) < 18 THEN '<18'
            WHEN TIMESTAMPDIFF(YEAR, p.DOB, CURDATE()) BETWEEN 18 AND 35 THEN '18-35'
            WHEN TIMESTAMPDIFF(YEAR, p.DOB, CURDATE()) BETWEEN 36 AND 55 THEN '36-55'
            ELSE '56+'
        END AS age_group
    FROM patient_info p
    JOIN consultation_info c 
		ON p.PID = c.PID
    JOIN diagnosis_info d 
		ON c.CID = d.CID
)
SELECT
    age_group,
    diagnosis,
    COUNT(*) AS cases
FROM age_groups
GROUP BY age_group, diagnosis
ORDER BY age_group, cases DESC;

 
--- SECTION 5: PROVIDER WORKLOAD & PERFORMANCE 
-- Workload per doctor
SELECT 
	dep.name AS department, 
    doc.name AS doctor_name, 
    COUNT(d.did) AS total_cases
FROM dept_info dep
JOIN doctor_info doc 
		ON dep.deptid=doc.deptid
LEFT JOIN diagnosis_info d 
		ON doc.docid=d.docid
GROUP BY doc.name, dep.name
HAVING COUNT(d.did)>1
ORDER BY total_cases DESC;
 
-- Doctors with no diagnosed cases
SELECT 
	doc.name AS doctor_name, 
    dep.name AS department
FROM dept_info dep
JOIN doctor_info doc 
		ON dep.deptid=doc.deptid
LEFT JOIN diagnosis_info d 
		ON doc.docid=d.docid
GROUP BY doc.Name, dep.Name 
HAVING COUNT(d.did)= 0;

