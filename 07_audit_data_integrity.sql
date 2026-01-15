/* =========================================================
   Data Quality & Revenue Integrity Audit – SmileSync
   Purpose:
   - Identify documentation gaps
   - Detect revenue leakage
   - Validate insurance and billing logic
   - Provide actionable insights for follow-up
   ========================================================= */

--- SECTION 1: DIAGNOSIS FOLLOW-UP CHECK
-- Patients with diagnoses that have not yet received treatment
SELECT 
    p.PID,
    CONCAT(p.First_name, ' ', p.Last_name) AS Patient_Name,
    d.Diagnosis,
    d.Notes AS Diagnosis_Notes,
    doc.Name AS Doctor_Name,
    c.Visit_Date
FROM patient_info p
JOIN consultation_info c 
	ON p.PID = c.PID
JOIN diagnosis_info d 
	ON c.CID = d.CID
LEFT JOIN treatment_info t 
	ON d.DID = t.DID
LEFT JOIN doctor_info doc 
	ON d.DocID = doc.DocID
WHERE t.TID IS NULL
ORDER BY p.PID, d.Diagnosis;


--- SECTION 2: TREATMENT & BILLING INTEGRITY
-- Treatments with no billing record
SELECT
    t.TID,
    tc.Treatment,
    t.Treatment_Date,
    c.PID,
    CONCAT(p.First_name, ' ', p.Last_name) AS Patient_Name
FROM treatment_info t
JOIN diagnosis_info d 
	ON t.DID = d.DID
JOIN consultation_info c 
	ON d.CID = c.CID
JOIN patient_info p 
	ON c.PID = p.PID
JOIN treatment_costs tc 
	ON t.TCID = tc.TCID
LEFT JOIN billing_info b 
	ON t.TID = b.TID
WHERE b.BID IS NULL;

-- Duplicate billing check
SELECT 
    b.TID,
    COUNT(*) AS Billing_Count,
    GROUP_CONCAT(b.BID) AS Duplicate_BIDs,
    p.PID,
    CONCAT(p.First_name, ' ', p.Last_name) AS Patient_Name
FROM billing_info b
JOIN treatment_info t 
	ON b.TID = t.TID
JOIN diagnosis_info d 
	ON t.DID = d.DID
JOIN consultation_info c 
	ON d.CID = c.CID
JOIN patient_info p 
	ON c.PID = p.PID
GROUP BY b.TID, p.PID
HAVING COUNT(*) > 1;

-- Billing date before treatment date (with patient & treatment info)
SELECT
    b.BID,
    t.TID,
    tc.Treatment,
    b.Billing_Date,
    t.Treatment_Date,
    p.PID,
    CONCAT(p.First_name, ' ', p.Last_name) AS Patient_Name
FROM billing_info b
JOIN treatment_info t 
	ON b.TID = t.TID
JOIN diagnosis_info d 
	ON t.DID = d.DID
JOIN consultation_info c 
	ON d.CID = c.CID
JOIN patient_info p 
	ON c.PID = p.PID
JOIN treatment_costs tc 
	ON t.TCID = tc.TCID
WHERE b.Billing_Date < t.Treatment_Date;


--- SECTION 3: INSURANCE & PAYMENT LOGIC
-- Insurance paid when coverage is zero
SELECT
    b.BID,
    p.PID,
    CONCAT(p.First_name, ' ', p.Last_name) AS Patient_Name,
    tc.Treatment,
    i.Company AS Insurance_Company,
    i.Payment_Model,
    i.Coverage_Percentage,
    b.Insurance_Amount
FROM billing_info b
JOIN treatment_info t 
	ON b.TID = t.TID
JOIN diagnosis_info d 
	ON t.DID = d.DID
JOIN consultation_info c 
	ON d.CID = c.CID
JOIN insurance_info i 
	ON c.InsID = i.InsID
JOIN patient_info p 
	ON c.PID = p.PID
JOIN treatment_costs tc 
	ON t.TCID = tc.TCID
WHERE i.Coverage_Percentage = 0
	AND b.Insurance_Amount > 0;

-- Patient amount negative or zero check
SELECT
    b.BID,
    t.TID,
    p.PID,
    CONCAT(p.First_name, ' ', p.Last_name) AS Patient_Name,
    tc.Treatment,
    b.Patient_Amount,
    b.Gross_Amount
FROM billing_info b
JOIN treatment_info t 
	ON b.TID = t.TID
JOIN diagnosis_info d 
	ON t.DID = d.DID
JOIN consultation_info c 
	ON d.CID = c.CID
JOIN patient_info p 
	ON c.PID = p.PID
JOIN treatment_costs tc 
	ON t.TCID = tc.TCID
WHERE b.Patient_Amount <= 0
ORDER BY b.BID;


--- SECTION 4: PAYMENT TIMING & DELAYS
-- Average, min, and max delay between consultation and treatment
SELECT 
    t.TCID,
    tc.Treatment,
    COUNT(*) AS Total_Cases,
    ROUND(AVG(DATEDIFF(t.Treatment_Date, c.Visit_Date)), 2) AS Avg_Delay_Days,
    MAX(DATEDIFF(t.Treatment_Date, c.Visit_Date)) AS Max_Delay_Days,
    MIN(DATEDIFF(t.Treatment_Date, c.Visit_Date)) AS Min_Delay_Days
FROM treatment_info t
JOIN diagnosis_info d 
	ON t.DID = d.DID
JOIN consultation_info c 
	ON d.CID = c.CID
JOIN treatment_costs tc 
	ON t.TCID = tc.TCID
WHERE t.Treatment_Date IS NOT NULL
GROUP BY t.TCID, tc.Treatment
ORDER BY Avg_Delay_Days DESC;

