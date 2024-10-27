# SAS Project
## Project Overview
This project was conducted as part of the Advanced SAS course (Magistère 2), focusing on high-dimensional precision matrix estimation and its application in portfolio allocation. The project involved creating and testing various SAS functions for data import, data processing, and analysis across multiple datasets. The project is divided into several sections, covering tasks in SAS BASE, SQL, and macro-programming.

## Table of Contents
1. Project Structure
2. Project Components
3. SAS BASE Functions
4. SAS SQL Analysis
5. Macro Programming
* Requirements
* Usage
* Deliverables
## Project Structure
Macros and Functions: This section contains SAS macros for handling data import, cleaning, and dataset manipulation. These functions streamline the project’s processes, such as data sampling and frequency analysis.
Simulations and Analysis Scripts: Scripts for importing, cleaning, and analyzing data are included, showcasing techniques for dataset preparation and exploratory data analysis.
Output and Results: Contains the results of required analyses, including frequency distributions, survival estimations, and visualizations.
Project Components
1. SAS BASE Functions
File Import Macro: A custom macro %file_import that imports datasets with specified parameters, including file path, file name, table name, and delimiters as needed.
Data Processing:
New Features Creation: Created customers1 table with features like anciennete (membership tenure) and state_groupe (grouping based on customer_state).
PROC FREQ Analysis: Frequency tables (customers21, customers22, customers23) summarize client distributions by state group and membership status.
2. SAS SQL Analysis
Distinct Customer Count: SQL queries to calculate distinct customer counts by state group and card type, with data sorting by customer volume.
Order Analysis: SQL scripts identify order counts and total sales for orders placed in specific periods, filtering for high-weight products and card types.
Revenue and Basket Analysis: Summary statistics for revenue, order count, and average basket size across customer states and UVC averages.
3. Macro Programming for Sampling
Simple Random Sampling (AS):
Created macros (%AS1, %AS2, %AS3, %AS4) for sampling based on user-defined criteria, such as percentage or fixed sample size.
Stratified Sampling (ASTR):
Developed the %ASTR macro series for stratified sampling based on specified strata, including options for stratified random sampling with adjustable rates.
Requirements
Software: SAS 9.4 or SAS Viya
