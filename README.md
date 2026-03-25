# end-to-end-healthcare-data-cleaning

# 🏥 Healthcare Data Cleaning Project (Excel + SQL)

## 📊 Overview
This project demonstrates end-to-end data cleaning of a messy healthcare dataset containing 1000 patient records using both **Microsoft Excel and SQL Server**.

The dataset contained real-world data quality issues such as missing values, duplicates, inconsistent formats, invalid entries, and mixed currencies.

---
## 📄 Project Report
👉 [View Full Report](report/Healthcare_Data_Cleaning_Report_Adekunle_Ojo.pdf)

----

## 🎯 Objectives
- Clean and standardize raw healthcare data
- Handle missing, invalid, and inconsistent values
- Perform data cleaning using both Excel and SQL
- Prepare dataset for analysis and reporting

---

## 🧾 Dataset Description
The dataset includes:
- Patient ID, Name, Gender, Age
- Contact details (Phone, Email, Address)
- Admission & Discharge Dates
- Diagnosis, Doctor, Department
- Treatment Cost, Billing Amount
- Insurance Provider, Medication

---

## ⚠️ Data Issues Identified
- Missing values
- Duplicate records
- Inconsistent text formatting
- Mixed date formats
- Invalid emails and phone numbers
- Negative and unrealistic costs
- Mixed currencies (NGN, USD, GBP)
- Billing mismatches
- Logical errors (discharge before admission)

---

# 🧹 Data Cleaning Approach

## 🔷 Excel Cleaning
In Excel, I performed:

- Removed duplicates using Patient ID
- Replaced missing names with "Not Registered"
- Standardized text using TRIM and PROPER
- Fixed gender inconsistencies
- Standardized date formats
- Extracted cost values and currencies
- Converted all currencies to USD using lookup table
- Validated billing vs treatment cost

---

## 🔷 SQL Cleaning
The same dataset was cleaned in SQL Server to demonstrate advanced data manipulation skills.

👉 Full SQL Script: [View SQL File](data_cleaning.sql)

### Key SQL Techniques Used:
- `UPDATE` for handling missing values
- `LTRIM()` / `RTRIM()` for whitespace cleaning
- `CASE` statements for standardization
- `ROW_NUMBER()` to remove duplicates
- `JOIN` with exchange rate table for currency conversion
- `TRY_CAST()` and `DATEADD()` for date standardization
- Window functions (`LEAD`) for filling missing values
- Data validation queries for identifying errors

---

## 🛠 Tools Used
- Microsoft Excel
- SQL Server (SSMS)

---

## 📈 Outcome
- Clean, structured dataset ready for analysis
- Improved data consistency and reliability
- Eliminated duplicates and errors
- Standardized financial data to USD
- Demonstrated both spreadsheet and database cleaning techniques

---

## 🧠 Key Skills Demonstrated
- Data Cleaning & Preprocessing
- Data Validation
- SQL Data Manipulation
- Excel Functions
- Problem Solving
- Data Standardization

---

## 🚀 Future Improvements
- Automate cleaning using Python (Pandas)
- Build Power BI dashboard
- Implement real-time data validation


