# **Lineman Analytics Engineer Exam**

## **Table of Contents**
- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Testing](#testing)
- [Appendix](#appendix)

## **Overview**
This is a dbt project for **LMWN Analytics Engineer Exam**, Which simulate as AE for Food Delivery to create report for Driver, Marketing and CS team and transform raw data into meaningful insights using **[dbt]**.

## **Installation**
### 1. Clone this repository:

```bash
git clone https://github.com/ppakornnn/lmwn_ae_exam.git
cd lmwn_ae_exam
```
### 2. Setup your environment:
```python
python -m venv venv
source venv/bin/activate  # On Windows use `venv\Scripts\activate`
```

### 3. Install dependencies:
```python
pip install -r requirements.txt
```

### 4. Configure your dbt profile:
Set up your dbt profile (usually located at ~/.dbt/profiles.yml) to connect to your data warehouse.
``` yaml
lmwn_ae_exam:
  outputs:
    dev:
      type: duckdb
      threads: 1
      path: "path/to/your/duckdb/file.db"  # Path to your DuckDB file
    prod:
      type: duckdb
      threads: 4
      path: "path/to/your/duckdb/file.db"  # Path to your DuckDB file
  target: dev
```
## **Usage**
After installation, you can run dbt commands to interact with your models:

- **Run all models**:
``` bash
dbt run
```
- **Test your models**:
``` bash
dbt run --models <model_name>
```
- **Check for model documentation**
``` bash
dbt docs generate
dbt docs serve
```

## **Project Structure**
Quick overview of the structure of lmwn_ae_exam project:
``` bash
lmwn_ae_exam/
│
├── models/                  # Where all the dbt models are stored\
│   ├── dwd/                 # Data warehouse Details (Raw data transformations)
│   ├── dws/                 # DWS where data is summarize and ready for some reports
│   ├── ads/                 # Final models ready for Dashboard
│   └── sources/             # Where raw data from Database metadata are stored
│
├── snapshots/               # Snapshot models for capturing historical data
├── macros/                  # Custom macros
├── tests/                   # Custom tests for data validation
├── analysis/                # Analysis files
├── appendix/                # Contain each requirements description and table
├── dbt_project.yml          # Main dbt configuration file
├── packages.yml             # dbt packages
└── requirements.txt         # Python dependencies
```

## **Dependencies**
### 1. Python
This project uses the following dependencies:
 - **dbt**: The core tool for transforming data in your warehouse.
 - **duckdb**: As main database

To install dependencies:
```bash
pip install -r requirements.txt
```
### 2. dbt packages
 - **dbt-labs/dbt_utils**: For Data Validation
 - **calogica/dbt_date**: To create dim_date

To install dependencies
``` bash
dbt deps
```

## **Testing**
This project includes tests for validating the data transformations and ensuring the quality of your models.

You can run tests using the following dbt command:

``` bash
dbt test
```

## **Appendix**
For each requirements and table can be find in appendix folder

## **Table Lineage**
Can be found in dbt docs
