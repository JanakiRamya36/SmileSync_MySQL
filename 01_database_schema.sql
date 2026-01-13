/* =========================================================
   Design Notes:
   - This is a simplified, realistic version of an Electronic Dental Record (EDR) system.
   - Patients are billed per treatment they actually receive, which reflects how clinics usually operate.
   - Insurance coverage and discounts are not calculated automatically by the database; 
     Instead, they can be handled in SQL views, fact tables, or Python scripts, and the results are stored in billing_info.
   - The schema is designed to be easy to analyze and explore, so it’s perfect for learning, demos, and small-scale projects.
   - While it’s inspired by real-world dental systems, it avoids the full complexity of production software, keeping it simple and clear.
========================================================= */

/* ========================================================
                                    SMILESYNC: Dental Clinic Management Database
   
   Description: Relational database design for managing patient records, consultations, diagnoses,treatments, and billing information
												           ============================================================================= */


-- Creating the SmileSync database
CREATE DATABASE IF NOT EXISTS `SmileSync`;
Use SmileSync;

-- Patient table
CREATE TABLE `patient_info` (
  `PID` char(15) NOT NULL,
  `First_name` varchar(20) DEFAULT NULL,
  `Last_name` varchar(20) DEFAULT NULL,
  `DOB` date DEFAULT NULL,
  `Gender` char(1) DEFAULT NULL,
  `Address` varchar(20) DEFAULT NULL,
  `Contact_No` varchar(15) DEFAULT NULL,
  `Email` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`PID`),
  KEY `in1` (`PID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Department details and specializations offered in the clinic
CREATE TABLE `dept_info` (
  `DeptID` int NOT NULL,
  `Name` varchar(25) DEFAULT NULL,
  `Specialization` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`DeptID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Standard treatment catalog with CDT codes and associated costs
CREATE TABLE `treatment_costs` (
  `TCID` varchar(5) NOT NULL,
  `Treatment` varchar(40) DEFAULT NULL,
  `CDTcode` varchar(6) DEFAULT NULL,
  `Treatment_Cost` DECIMAL(8,2) NOT NULL,
  PRIMARY KEY (`TCID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Insurance details linked to each patient (1:1 relationship)
CREATE TABLE `insurance_info` (
  `InsID` varchar(5) NOT NULL,
  `Company` varchar(25) DEFAULT NULL,
  `Ins_Category` varchar(15) DEFAULT NULL,
  `Payment_Model` varchar(25) DEFAULT NULL,
  `Coverage_Percentage` DECIMAL(5,2) NOT NULL DEFAULT 0,
  `Discount_Percentage` DECIMAL(5,2) NOT NULL DEFAULT 0,
  `Plan` varchar(15) DEFAULT NULL,
  `PID` char(15) DEFAULT NULL,
  PRIMARY KEY (`InsID`),
  UNIQUE KEY `PID` (`PID`),
  CONSTRAINT `insurance_info_ibfk_1` FOREIGN KEY (`PID`) REFERENCES `patient_info` (`PID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Clinical encounter information recorded during patient visits
CREATE TABLE `consultation_info` (
  `CID` varchar(5) NOT NULL,
  `Visit_Date` date DEFAULT NULL,
  `PID` char(15) DEFAULT NULL,
  `InsID` varchar(5) DEFAULT NULL,
  `Consultation_fee` DECIMAL(8,2) NOT NULL,
  `Visit_Type` VARCHAR(25) DEFAULT NULL, 
  `Chief_Complaint` varchar(25) DEFAULT NULL,
  `Medical_History` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`CID`),
  KEY `PID` (`PID`),
  KEY `InsID` (`InsID`),
  CONSTRAINT `consultation_info_ibfk_1` FOREIGN KEY (`PID`) REFERENCES `patient_info` (`PID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `consultation_info_ibfk_2` FOREIGN KEY (`InsID`) REFERENCES `insurance_info` (`InsID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Doctor details including department affiliation
CREATE TABLE `doctor_info` (
  `DocID` varchar(7) NOT NULL,
  `Name` varchar(15) DEFAULT NULL,
  `DeptID` int DEFAULT NULL,
  PRIMARY KEY (`DocID`),
  KEY `DeptID` (`DeptID`),
  CONSTRAINT `doctor_info_ibfk_1` FOREIGN KEY (`DeptID`) REFERENCES `dept_info` (`DeptID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Diagnostic findings and investigation details linked to consultations
CREATE TABLE `diagnosis_info` (
  `DID` varchar(5) NOT NULL,
  `Investigation` varchar(20) DEFAULT NULL,
  `Diagnosis` varchar(40) DEFAULT NULL,
  `CID` varchar(5) DEFAULT NULL,
  `DocID` varchar(7) DEFAULT NULL,
  `Notes` TEXT DEFAULT NULL, 
  PRIMARY KEY (`DID`),
  KEY `CID` (`CID`),
  KEY `DocID` (`DocID`),
  CONSTRAINT `diagnosis_info_ibfk_1` FOREIGN KEY (`CID`) REFERENCES `consultation_info` (`CID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `diagnosis_info_ibfk_2` FOREIGN KEY (`DocID`) REFERENCES `doctor_info` (`DocID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Treatment prescribed based on diagnosis, mapped to treatment catalog
CREATE TABLE `treatment_info` (
  `TID` varchar(5) NOT NULL,
  `Treatment_Date` date DEFAULT NULL,
  `Prescription` varchar(50) DEFAULT NULL,
  `DID` varchar(5) DEFAULT NULL,
  `TCID` varchar(5) NOT NULL,
  PRIMARY KEY (`TID`),
  KEY `DID` (`DID`),
  KEY `TCID` (`TCID`),
  CONSTRAINT `treatment_info_ibfk_1` FOREIGN KEY (`DID`) REFERENCES `diagnosis_info` (`DID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `treatment_info_ibfk_2` FOREIGN KEY (`TCID`) REFERENCES `treatment_costs` (`TCID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Billing information generated for each treatment event
CREATE TABLE billing_info (
  `BID` varchar(10) NOT NULL,
  `TID` varchar(5) NOT NULL,
  `Billing_Date` date NOT NULL,
  `Treatment_Cost` DECIMAL(8,2) NOT NULL,
  `Consultation_Fee` DECIMAL(8,2) NOT NULL,
  `Gross_Amount` DECIMAL(10,2) NOT NULL,
  `Insurance_Amount` DECIMAL(10,2) NOT NULL,
  `Patient_Amount` DECIMAL(10,2) NOT NULL,
  `Payment_Model` varchar(25) NOT NULL,
  PRIMARY KEY (`BID`),
  UNIQUE KEY `TID` (`TID`),
  CONSTRAINT `billing_info_ibfk_1` FOREIGN KEY (`TID`) REFERENCES `treatment_info` (`TID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
