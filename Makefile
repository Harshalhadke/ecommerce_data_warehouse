.PHONY: help setup clean test lint db-create db-drop db-reset schema seed etl analytics quality

# Database configuration
DB_NAME ?= ecommerce_dw
DB_USER ?= $(USER)
DB_HOST ?= localhost
DB_PORT ?= 5432

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m # No Color

help: ## Show this help message
	@echo '${GREEN}E-Commerce Data Warehouse - Make Commands${NC}'
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${NC} ${GREEN}<target>${NC}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${YELLOW}%-20s${NC} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: db-create schema seed ## Complete setup (create DB, schema, load seed data)
	@echo "${GREEN}✅ Setup complete! Database ready.${NC}"
	@echo "Run 'make test' to verify installation"

db-create: ## Create the database
	@echo "${GREEN}Creating database: ${DB_NAME}${NC}"
	@createdb ${DB_NAME} || echo "Database already exists"
	@psql -d ${DB_NAME} -c "CREATE SCHEMA IF NOT EXISTS staging;"
	@psql -d ${DB_NAME} -c "CREATE SCHEMA IF NOT EXISTS analytics;"

db-drop: ## Drop the database (⚠️  destructive)
	@echo "${YELLOW}⚠️  Dropping database: ${DB_NAME}${NC}"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		dropdb ${DB_NAME}; \
		echo "${GREEN}Database dropped${NC}"; \
	fi

db-reset: db-drop db-create ## Reset database (drop and recreate)

schema: ## Create all schemas (dimensions, facts, staging)
	@echo "${GREEN}Creating dimension tables...${NC}"
	@psql -d ${DB_NAME} -f infrastructure/01_schema/dimensions/001_dim_date.sql
	@psql -d ${DB_NAME} -f infrastructure/01_schema/dimensions/002_dim_geography.sql
	@psql -d ${DB_NAME} -f infrastructure/01_schema/dimensions/003_dim_customers.sql
	@psql -d ${DB_NAME} -f infrastructure/01_schema/dimensions/004_dim_products.sql
	@psql -d ${DB_NAME} -f infrastructure/01_schema/dimensions/005_dim_stores.sql
	@echo "${GREEN}Creating staging tables...${NC}"
	@psql -d ${DB_NAME} -f infrastructure/01_schema/staging/001_staging_tables.sql
	@echo "${GREEN}Creating fact tables...${NC}"
	@psql -d ${DB_NAME} -f infrastructure/01_schema/facts/001_fact_orders.sql
	@psql -d ${DB_NAME} -f infrastructure/01_schema/facts/002_fact_order_items.sql
	@psql -d ${DB_NAME} -f infrastructure/01_schema/facts/003_fact_inventory.sql
	@psql -d ${DB_NAME} -f infrastructure/01_schema/facts/004_fact_customer_events.sql
	@echo "${GREEN}Creating indexes...${NC}"
	@psql -d ${DB_NAME} -f infrastructure/01_schema/indexes/001_indexes.sql
	@echo "${GREEN}✅ Schema created successfully${NC}"

seed: ## Generate and load seed data
	@echo "${GREEN}Generating seed data...${NC}"
	@python ingestion/02_seed_data/generate_data.py
	@echo "${GREEN}✅ Seed data loaded${NC}"

etl: ## Run ETL pipelines
	@echo "${GREEN}Running SCD Type 2 for customers...${NC}"
	@psql -d ${DB_NAME} -f legacy_sql_reference/03_etl/scd/scd_type2_customers.sql
	@psql -d ${DB_NAME} -f legacy_sql_reference/03_etl/scd/scd_type2_products.sql
	@echo "${GREEN}Running incremental loads...${NC}"
	@psql -d ${DB_NAME} -f legacy_sql_reference/03_etl/incremental_loads/load_fact_orders.sql
	@psql -d ${DB_NAME} -f legacy_sql_reference/03_etl/incremental_loads/load_fact_order_items.sql
	@echo "${GREEN}✅ ETL complete${NC}"

analytics: ## Run analytics queries
	@echo "${GREEN}Running analytics...${NC}"
	@psql -d ${DB_NAME} -f legacy_sql_reference/04_analytics/cohort_analysis/monthly_cohorts.sql
	@psql -d ${DB_NAME} -f legacy_sql_reference/04_analytics/revenue_attribution/attribution_models.sql
	@echo "${GREEN}✅ Analytics complete${NC}"

quality: ## Run data quality checks
	@echo "${GREEN}Running data quality validation...${NC}"
	@psql -d ${DB_NAME} -f observability/05_data_quality/validation_rules/data_profiling.sql
	@echo "${GREEN}✅ Data quality checks complete${NC}"

test: ## Verify database setup
	@echo "${GREEN}Running verification tests...${NC}"
	@psql -d ${DB_NAME} -c "SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM dim_date UNION ALL SELECT 'dim_customers', COUNT(*) FROM dim_customers UNION ALL SELECT 'dim_products', COUNT(*) FROM dim_products UNION ALL SELECT 'fact_orders', COUNT(*) FROM fact_orders;"
	@echo "${GREEN}✅ Tests complete${NC}"

lint: ## Lint SQL files with SQLFluff
	@echo "${GREEN}Linting SQL files...${NC}"
	@sqlfluff lint infrastructure/01_schema/ legacy_sql_reference/03_etl/ legacy_sql_reference/04_analytics/ || echo "SQLFluff not installed. Run: pip install sqlfluff"

clean: ## Clean temporary files
	@echo "${GREEN}Cleaning temporary files...${NC}"
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@find . -type f -name ".DS_Store" -delete
	@find . -type f -name "*.log" -delete
	@echo "${GREEN}✅ Cleanup complete${NC}"

status: ## Show database status
	@echo "${GREEN}Database Status:${NC}"
	@psql -d ${DB_NAME} -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema') ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;"

connect: ## Connect to database with psql
	@psql -d ${DB_NAME}

backup: ## Backup database to SQL file
	@echo "${GREEN}Backing up database to backup_$(shell date +%Y%m%d_%H%M%S).sql${NC}"
	@pg_dump ${DB_NAME} > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "${GREEN}✅ Backup complete${NC}"

# Python environment setup
venv: ## Create Python virtual environment
	@python -m venv venv
	@echo "${GREEN}Virtual environment created. Activate with: source venv/bin/activate${NC}"

install: ## Install Python dependencies
	@pip install -r requirements.txt || echo "${YELLOW}requirements.txt not found${NC}"

# Development helpers
watch: ## Watch for SQL file changes and run linting
	@echo "${GREEN}Watching for changes... (requires fswatch)${NC}"
	@fswatch -o infrastructure/01_schema/ legacy_sql_reference/03_etl/ legacy_sql_reference/04_analytics/ | xargs -n1 -I{} make lint

docs: ## Generate documentation
	@echo "${GREEN}Generating documentation...${NC}"
	@psql -d ${DB_NAME} -c "\dt" > docs/tables_list.txt
	@psql -d ${DB_NAME} -c "\d+ dim_customers" > docs/schema_examples.txt
	@echo "${GREEN}✅ Documentation generated in docs/${NC}"
