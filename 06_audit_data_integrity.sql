/* =========================================================
   Data Quality & Revenue Integrity Audit – SmileSync
   Purpose:
   - Identify documentation gaps
   - Detect revenue leakage
   - Validate insurance and billing logic
   ========================================================= */

--- SECTION 1: DIAGNOSIS FOLLOW-UP CHECK
-- Patients with diagnoses that have not yet received treatment
SELECT 
    p.PID,
    CONCAT(p.First_name, ' ', p.Last_name) 
		AS Patient_Name,
    d.Diagnosis,
    c.Visit_Date
FROM patient_info p
JOIN consultation_info c 
    ON p.PID = c.PID
JOIN diagnosis_info d
    ON c.CID = d.CID
LEFT JOIN treatment_info t
    ON d.DID = t.DID
WHERE t.TID IS NULL
ORDER BY p.PID, d.Diagnosis;

--- SECTION 2: TREATMENT & BILLING INTEGRITY
-- Treatments with no billing record
SELECT
    t.TID,
    t.Treatment_Date,
    tc.Treatment
FROM treatment_info t
LEFT JOIN billing_info b ON t.TID = b.TID
JOIN treatment_costs tc ON t.TCID = tc.TCID
WHERE b.BID IS NULL;

-- Duplicate billing check (same treatment billed more than once)
SELECT 
    TID,
    COUNT(*) AS billing_count
FROM billing_info
GROUP BY TID
HAVING COUNT(*) > 1;

-- Billing date before treatment date
SELECT
    b.BID,
    b.Billing_Date,
    t.Treatment_Date
FROM billing_info b
JOIN treatment_info t ON b.TID = t.TID
WHERE b.Billing_Date < t.Treatment_Date;

--- SECTION 3: INSURANCE & PAYMENT LOGIC
-- Insurance paid when coverage is zero
SELECT
    b.BID,
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
WHERE i.Coverage_Percentage = 0
  AND b.Insurance_Amount > 0;

-- Patient amount negative or zero check
SELECT
    BID,
    TID,
    Patient_Amount,
    Gross_Amount
FROM billing_info
WHERE Patient_Amount <= 0
ORDER BY BID;

--- SECTION 4: PAYMENT TIMING & DELAYS
-- Average delay between consultation and treatment
SELECT 
    t.TCID,
    tc.Treatment,
    ROUND(AVG(DATEDIFF(t.Treatment_Date, c.Visit_Date)), 2) 
		AS Avg_Delay_Days
FROM treatment_info t
JOIN diagnosis_info d 
	ON t.DID = d.DID
JOIN consultation_info c 
	ON d.CID = c.CID
JOIN treatment_costs tc 
	ON t.TCID = tc.TCID
GROUP BY t.TCID, tc.Treatment
ORDER BY Avg_Delay_Days DESC;


/* 
Note:
- This dataset contains clean, controlled dummy data.
- In a real-world implementation, these queries help track:
    ~ Untreated diagnoses for patient follow-ups
    ~ Treatments not billed to prevent revenue leakage
    ~ Insurance miscalculations
	~ Incorrect billing dates or duplicate bills
    ~ Payment anomalies (negative patient amounts) 
*/