import mysql.connector
from db_config import DB_CONFIG
from datetime import datetime, timedelta
import random

def generate_new_billing():
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(dictionary=True)
    
    # Fetch treatments in chronological order
    query = """
    SELECT 
        t.TID,
        t.Treatment_Date,
        d.CID,
        tc.Treatment_Cost,
        c.Consultation_fee,
        i.Payment_Model,
        i.Coverage_Percentage,
        i.Discount_Percentage
    FROM treatment_info t
    JOIN diagnosis_info d ON t.DID = d.DID
    JOIN consultation_info c ON d.CID = c.CID
    JOIN insurance_info i ON c.InsID = i.InsID
    JOIN treatment_costs tc ON t.TCID = tc.TCID
    ORDER BY d.CID, t.Treatment_Date;
    """

    cursor.execute(query)
    rows = cursor.fetchall()

    seen_consultations = set()

    insert_query = """
    INSERT INTO billing_info (
        BID, TID, Billing_Date,
        Treatment_Cost, Consultation_Fee,
        Gross_Amount, Insurance_Amount, Patient_Amount,
        Payment_Model
    )
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """

    for r in rows:

        # Skip if billing already exists
        cursor.execute("SELECT BID FROM billing_info WHERE TID = %s", (r["TID"],))
        if cursor.fetchone():
            continue

        # Consultation fee only once per consultation
        consultation_fee = 0
        if r["CID"] not in seen_consultations:
            consultation_fee = r["Consultation_fee"]
            seen_consultations.add(r["CID"])

        gross = r["Treatment_Cost"] + consultation_fee

        coverage = r["Coverage_Percentage"] or 0
        discount = r["Discount_Percentage"] or 0
        payment_model = r["Payment_Model"].strip().lower()

        # Calculate insurance & patient amount
        insurance_amt = 0
        patient_amt = gross  # default: patient pays all

        if payment_model == "copay":
            insurance_amt = gross * (coverage / 100)
            patient_amt = gross - insurance_amt

        elif payment_model == "dental discount":
            patient_amt = gross * (1 - (discount / 100))

        else:
            # Default: patient pays all
            insurance_amt = 0
            patient_amt = gross    

        # Billing date: 0-7 days after treatment for realism
        billing_date = r["Treatment_Date"] + timedelta(days=random.randint(0,7))

        bid = f"B{r['TID']}"

        cursor.execute(
            insert_query,
            (
                bid,
                r["TID"],
                billing_date,
                r["Treatment_Cost"],
                consultation_fee,
                round(gross, 2),
                round(insurance_amt, 2),
                round(patient_amt, 2),
                r["Payment_Model"]
            )
        )

    conn.commit()
    cursor.close()
    conn.close()

    print("Billing successfully generated.")


if __name__ == "__main__":
    generate_new_billing()

