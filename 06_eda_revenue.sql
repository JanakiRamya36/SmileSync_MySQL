/* =========================================================
   Revenue EDA – SmileSync Database
   Purpose: Examine billing distribution, insurance payments,
            and revenue impact of treatment utilization.
   ========================================================= */

--- SECTION 1: REVENUE OVERVIEW & MIX
-- Total revenue snapshot
SELECT 
    ROUND(SUM(Gross_Amount), 2) AS Total_Gross_Revenue,
    ROUND(SUM(Insurance_Amount), 2) AS Insurance_Revenue,
    ROUND(SUM(Patient_Amount), 2) AS Patient_Revenue
FROM billing_info;

-- Revenue mix percentage
SELECT
    ROUND(SUM(Insurance_Amount) / SUM(Gross_Amount) * 100, 2) 
        AS Insurance_Revenue_Pct,
    ROUND(SUM(Patient_Amount) / SUM(Gross_Amount) * 100, 2) 
        AS Patient_Revenue_Pct
FROM billing_info;


--- SECTION 2: REVENUE BY PAYMENT MODEL
-- Impact of copay vs dental discount
SELECT
    Payment_Model,
    COUNT(*) AS Total_Bills,
    ROUND(SUM(Gross_Amount), 2) AS Gross_Revenue,
    ROUND(SUM(Insurance_Amount), 2) AS Insurance_Revenue,
    ROUND(SUM(Patient_Amount), 2) AS Patient_Revenue,
	ROUND(AVG(Gross_Amount), 2) AS Avg_Bill_Amount
FROM billing_info
GROUP BY Payment_Model
ORDER BY Gross_Revenue DESC;

-- Max/Min bill per payment model
SELECT 
    Payment_Model,
    ROUND(MAX(Gross_Amount),2) AS Max_Bill,
    ROUND(MIN(Gross_Amount),2) AS Min_Bill
FROM billing_info
GROUP BY Payment_Model;


--- SECTION 3: TREATMENT-LEVEL REVENUE PERFORMANCE
-- Revenue contribution by treatment
SELECT
    tc.Treatment,
    COUNT(b.BID) AS Times_Performed,
    ROUND(SUM(b.Gross_Amount), 2) AS Total_Revenue,
    ROUND(AVG(b.Gross_Amount), 2) AS Avg_Revenue_Per_Treatment
FROM billing_info b
JOIN treatment_info t 
	ON b.TID = t.TID
JOIN treatment_costs tc 
	ON t.TCID = tc.TCID
GROUP BY tc.Treatment
ORDER BY Total_Revenue DESC;

-- Top 5 revenue-generating treatments
SELECT
    tc.Treatment,
    ROUND(SUM(b.Gross_Amount), 2) AS Revenue
FROM billing_info b
JOIN treatment_info t 
	ON b.TID = t.TID
JOIN treatment_costs tc 
	ON t.TCID = tc.TCID
GROUP BY tc.Treatment
ORDER BY Revenue DESC
LIMIT 5;


--- SECTION 4: PATIENT-LEVEL REVENUE DISTRIBUTION
-- Revenue per patient
SELECT
    p.PID,
    CONCAT(p.First_name, ' ', p.Last_name) AS Patient_Name,
    COUNT(b.BID) AS Total_Treatments,
    ROUND(SUM(b.Gross_Amount), 2) AS Total_Billed,
	ROUND(SUM(b.Insurance_Amount),2) AS Insurance_Revenue,
    ROUND(SUM(b.Patient_Amount),2) AS Patient_Expense
FROM billing_info b
JOIN treatment_info t 
	ON b.TID = t.TID
JOIN diagnosis_info d 
	ON t.DID = d.DID
JOIN consultation_info c 
	ON d.CID = c.CID
JOIN patient_info p 
	ON c.PID = p.PID
GROUP BY p.PID
ORDER BY Total_Billed DESC;

-- Highest and lowest individual bills
SELECT *
FROM (
    SELECT
        'Highest Bill' AS Category,
        BID,
        Gross_Amount
    FROM billing_info
    ORDER BY Gross_Amount DESC
    LIMIT 1
) high

UNION ALL

SELECT *
FROM (
    SELECT
        'Lowest Bill' AS Category,
        BID,
        Gross_Amount
    FROM billing_info
    ORDER BY Gross_Amount ASC
    LIMIT 1
) low;
