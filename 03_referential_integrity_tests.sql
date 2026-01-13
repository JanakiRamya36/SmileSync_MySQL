 /* =========================================================
   Referential Integrity Testing – SmileSync Database
   Purpose: Validate ON DELETE CASCADE behavior across related tables
            (Department → Doctor → Diagnosis)
   ========================================================= */

START TRANSACTION;
SAVEPOINT F1;

-- View data before delete operation
SELECT * FROM dept_info;
SELECT * FROM doctor_info;
SELECT * FROM diagnosis_info;

-- Delete a department to test cascading behavior
DELETE FROM dept_info
WHERE DeptID = 7;

-- Verify that related doctor and diagnosis records are automatically deleted via ON DELETE CASCADE
SELECT * FROM dept_info;
SELECT * FROM doctor_info;
SELECT * FROM diagnosis_info;
-- Result observation:
 # Deleting Department with DeptID = 7  removed 4 associated doctors and 8 related diagnosis records via ON DELETE CASCADE

-- Roll back to preserve original data
ROLLBACK TO F1;

   
   
   
   