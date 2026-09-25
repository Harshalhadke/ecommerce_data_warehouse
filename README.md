# 🏢 E-Commerce Data Warehouse

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue.svg)](https://www.postgresql.org/)
[![dbt](https://img.shields.io/badge/dbt-Core-orange.svg)](https://www.getdbt.com/)
[![Python](https://img.shields.io/badge/Python-3.9+-green.svg)](https://www.python.org/)

An e-commerce data warehouse that ingests synthetic transactional data into PostgreSQL, models it into a **Kimball star schema**, and uses **dbt** to build staging models, SCD Type 2 dimensions, incremental fact tables, and analytical models like **RFM customer segmentation**.

## 📂 Project Structure

| Directory | What it does |
|-----------|-------------|
| `ingestion/` | Python + Faker data generation (~50K orders, 5K customers) loaded into PostgreSQL |
| `infrastructure/` | DDL for star schema (dimensions, facts, staging), indexes, partitioning, migrations |
| `transform/` | dbt models — staging (`stg_*`), snapshots (`snp_customers`), `dim_customers`, `fact_orders` (incremental), `customer_segmentation` (RFM analysis) |
| `observability/` | Data quality validation, anomaly detection, audit logging |
| `docs/` | Architecture diagrams and design decisions |

## 🧰 Tech Stack

**PostgreSQL 15+** · **dbt Core + dbt_utils** · **Python / Faker** · **SQLFluff** · **Make**

## 📄 License

MIT
