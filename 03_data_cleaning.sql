/* =========================================================
   DATA CLEANING OPERATIONS: 
   Remove duplicates, handle missing values,
            standardize text fields, and drop redundant columns
   ========================================================= */

-- Begin transaction to ensure safe rollback if needed
START transaction;
savepoint F1;

SELECT * FROM patient_info;

## Remove duplicate patient records based on contact number
-- Retains the record with the lowest PID
DELETE FROM patient_info
WHERE PID IN (
    SELECT pid_to_delete FROM (
        SELECT p.pid AS pid_to_delete
        FROM patient_info p
        JOIN patient_info p1
          ON p.contact_no = p1.contact_no
         AND p.pid > p1.pid
        WHERE p.contact_no IS NOT NULL
    ) AS temp
);

SELECT * FROM patient_info;

##  Convert blank strings to NULL values for consistency
-- Patient table
UPDATE patient_info
SET 
  address = NULLIF(TRIM(address),'')
WHERE TRIM(address) IN ('', 'NA', 'N/A', 'Unknown');

-- Diagnosis table
UPDATE diagnosis_info
SET 
  investigation = NULLIF(TRIM(investigation),'')
WHERE TRIM(investigation) IN ('', 'NA', 'N/A', 'Unknown');

-- Treatment table
UPDATE treatment_info
SET 
  prescription = NULLIF(TRIM(prescription),'')
WHERE TRIM(prescription) IN ('', 'NA', 'N/A', 'Unknown');

## Data Standardization
UPDATE consultation_info
SET chief_complaint = 'Receding Gums'
WHERE LOWER(TRIM(chief_complaint)) IN ('receeding gums', 'receding gums');

SELECT * FROM consultation_info;

-- Commit changes after validation
COMMIT; 



