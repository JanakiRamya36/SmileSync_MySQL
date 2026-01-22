 /* =========================================================
   Referential Integrity Testing – SmileSync Database
   Purpose: 
   - Validate ON DELETE CASCADE behavior across related tables
     (Department → Doctor → Diagnosis)
   - Demonstrate safe testing with rollback and dynamic selection
========================================================= */

START TRANSACTION;
SAVEPOINT F1;

-- Current counts before delete operation
SELECT COUNT(*) AS total_departments FROM dept_info;
SELECT COUNT(*) AS total_doctors FROM doctor_info;
SELECT COUNT(*) AS total_diagnoses FROM diagnosis_info;

-- Select a department to test cascading delete
SET @dept_to_delete = (SELECT DeptID FROM dept_info LIMIT 1);

-- View department before being deleted
SELECT * FROM dept_info WHERE DeptID = @dept_to_delete;

-- Perform delete to test ON DELETE CASCADE
DELETE FROM dept_info
WHERE DeptID = @dept_to_delete;

-- Verify cascading behavior: associated doctors and diagnoses should be removed
SELECT COUNT(*) AS remaining_departments FROM dept_info;
SELECT COUNT(*) AS remaining_doctors FROM doctor_info;
SELECT COUNT(*) AS remaining_diagnoses FROM diagnosis_info;

-- Rollback to preserve original data
ROLLBACK TO F1;

-- Confirm rollback: all records restored
SELECT COUNT(*) AS dept_count_after_rollback FROM dept_info;
SELECT COUNT(*) AS doctor_count_after_rollback FROM doctor_info;
SELECT COUNT(*) AS diagnosis_count_after_rollback FROM diagnosis_info;

-- Note: Deleting a department should automatically remove all related doctors and diagnoses due to ON DELETE CASCADE

   
   
   
