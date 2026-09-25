"""
E-Commerce Data Warehouse - Sample Data Generator and Ingestion
Generates realistic data and ingests it for all staging tables.

Usage:
    pip install faker psycopg2-binary
    python generate_data.py

    OR export to CSV:
    python generate_data.py --csv
"""

import argparse
import csv
import os
import random
from datetime import datetime, timedelta
from pathlib import Path

try:
    from faker import Faker
except ImportError:
    print("Install required packages: pip install faker psycopg2-binary")
    exit(1)

fake = Faker()
Faker.seed(42)
random.seed(42)

# Configuration
NUM_CUSTOMERS = 5000
NUM_PRODUCTS = 500
NUM_STORES = 20
NUM_ORDERS = 50000
NUM_EVENTS = 200000
START_DATE = datetime(2022, 1, 1)
END_DATE = datetime(2025, 12, 31)

OUTPUT_DIR = Path(__file__).parent / "data_output"


# ---------- Helper Functions ----------


def random_date(start=START_DATE, end=END_DATE):
    delta = end - start
    return start + timedelta(days=random.randint(0, delta.days))


def random_timestamp(start=START_DATE, end=END_DATE):
    dt = random_date(start, end)
    return dt.replace(
        hour=random.randint(0, 23),
        minute=random.randint(0, 59),
        second=random.randint(0, 59),
    )


# ---------- Geography Data ----------

REGIONS = {
    "US": {
        "region": "North America",
        "sub_region": "United States",
        "states": [
            ("CA", "California"),
            ("NY", "New York"),
            ("TX", "Texas"),
            ("FL", "Florida"),
            ("WA", "Washington"),
            ("IL", "Illinois"),
            ("PA", "Pennsylvania"),
            ("OH", "Ohio"),
            ("GA", "Georgia"),
            ("NC", "North Carolina"),
        ],
    },
    "GB": {
        "region": "Europe",
        "sub_region": "Western Europe",
        "states": [
            ("LDN", "London"),
            ("MAN", "Manchester"),
            ("BRM", "Birmingham"),
            ("LDS", "Leeds"),
            ("GLA", "Glasgow"),
        ],
    },
    "DE": {
        "region": "Europe",
        "sub_region": "Western Europe",
        "states": [
            ("BY", "Bavaria"),
            ("NW", "North Rhine-Westphalia"),
            ("BE", "Berlin"),
            ("HH", "Hamburg"),
            ("HE", "Hesse"),
        ],
    },
    "IN": {
        "region": "Asia",
        "sub_region": "South Asia",
        "states": [
            ("MH", "Maharashtra"),
            ("KA", "Karnataka"),
            ("TN", "Tamil Nadu"),
            ("DL", "Delhi"),
            ("TG", "Telangana"),
        ],
    },
}

# ---------- Product Catalog ----------

PRODUCT_CATALOG = {
    "Electronics": {
        "Laptops": ["Gaming Laptop", "Business Laptop", "Ultrabook", "Chromebook"],
        "Phones": ["Smartphone Pro", "Smartphone Lite", "Budget Phone"],
        "Audio": ["Wireless Headphones", "Bluetooth Speaker", "Earbuds", "Soundbar"],
        "Accessories": [
            "USB-C Hub",
            "Wireless Mouse",
            "Mechanical Keyboard",
            "Monitor Stand",
        ],
    },
    "Clothing": {
        "Mens": ["T-Shirt", "Jeans", "Jacket", "Hoodie", "Polo Shirt"],
        "Womens": ["Dress", "Blouse", "Skirt", "Cardigan", "Leggings"],
        "Footwear": ["Running Shoes", "Boots", "Sandals", "Sneakers"],
    },
    "Home & Kitchen": {
        "Kitchen": ["Coffee Maker", "Blender", "Air Fryer", "Toaster", "Knife Set"],
        "Furniture": ["Desk", "Office Chair", "Bookshelf", "Side Table"],
        "Decor": ["Wall Art", "Throw Pillow", "Candle Set", "Plant Pot"],
    },
    "Sports & Outdoors": {
        "Fitness": ["Yoga Mat", "Dumbbell Set", "Resistance Bands", "Jump Rope"],
        "Outdoor": ["Tent", "Hiking Backpack", "Water Bottle", "Camping Stove"],
    },
}

BRANDS = [
    "TechPro",
    "UrbanStyle",
    "HomeEssentials",
    "FitLife",
    "NatureTrek",
    "EliteGear",
    "ComfortPlus",
    "SwiftTech",
    "PureDesign",
    "ActiveWear",
]

SEGMENTS = ["Premium", "Standard", "Basic"]
LOYALTY_TIERS = ["Gold", "Silver", "Bronze", None]
CHANNELS = ["Organic", "Paid Search", "Social Media", "Email", "Referral", "Direct"]
PAYMENT_METHODS = ["Credit Card", "Debit Card", "PayPal", "Apple Pay", "COD"]
SHIPPING_METHODS = ["Standard", "Express", "Next-Day", "Store Pickup"]
ORDER_STATUSES = [
    "Delivered",
    "Delivered",
    "Delivered",
    "Delivered",
    "Shipped",
    "Processing",
    "Cancelled",
    "Returned",
]
EVENT_TYPES = [
    "page_view",
    "page_view",
    "page_view",
    "add_to_cart",
    "add_to_cart",
    "purchase",
    "review",
    "support_ticket",
    "wishlist_add",
    "search",
]
DEVICE_TYPES = ["desktop", "mobile", "mobile", "tablet"]
BROWSERS = ["Chrome", "Safari", "Firefox", "Edge"]
REFERRERS = ["google", "direct", "email", "facebook", "instagram", "twitter", None]


# ---------- Data Generators ----------


def generate_geography():
    rows = []
    geo_id = 1
    for country_code, info in REGIONS.items():
        for state_code, state_name in info["states"]:
            for _ in range(random.randint(2, 5)):
                rows.append(
                    {
                        "geography_key": geo_id,
                        "postal_code": fake.zipcode()
                        if country_code == "US"
                        else fake.postcode(),
                        "city": fake.city(),
                        "state_province": state_name,
                        "state_code": state_code,
                        "country": {
                            "US": "United States",
                            "GB": "United Kingdom",
                            "DE": "Germany",
                            "IN": "India",
                        }[country_code],
                        "country_code": country_code,
                        "region": info["region"],
                        "sub_region": info["sub_region"],
                        "latitude": float(fake.latitude()),
                        "longitude": float(fake.longitude()),
                        "timezone": fake.timezone(),
                    }
                )
                geo_id += 1
    return rows


def generate_customers(geography_data):
    rows = []
    geo_keys = [g["geography_key"] for g in geography_data]
    for i in range(1, NUM_CUSTOMERS + 1):
        acq_date = random_date(START_DATE, END_DATE - timedelta(days=90))
        geo = random.choice(geography_data)
        rows.append(
            {
                "customer_id": i,
                "first_name": fake.first_name(),
                "last_name": fake.last_name(),
                "email": fake.email(),
                "phone": fake.phone_number()[:20],
                "customer_segment": random.choices(SEGMENTS, weights=[15, 55, 30])[0],
                "loyalty_tier": random.choices(LOYALTY_TIERS, weights=[10, 20, 30, 40])[
                    0
                ],
                "postal_code": geo["postal_code"],
                "city": geo["city"],
                "state_province": geo["state_province"],
                "country_code": geo["country_code"],
                "acquisition_channel": random.choice(CHANNELS),
                "acquisition_date": acq_date.strftime("%Y-%m-%d"),
            }
        )
    return rows


def generate_products():
    rows = []
    product_id = 1
    for department, categories in PRODUCT_CATALOG.items():
        for category, items in categories.items():
            for item_name in items:
                for variant in range(random.randint(1, 3)):
                    price = round(random.uniform(9.99, 999.99), 2)
                    cost = round(price * random.uniform(0.3, 0.7), 2)
                    rows.append(
                        {
                            "product_id": product_id,
                            "sku": f"SKU-{department[:3].upper()}-{product_id:05d}",
                            "product_name": f"{random.choice(BRANDS)} {item_name}"
                            + (f" V{variant + 1}" if variant > 0 else ""),
                            "description": fake.sentence(nb_words=12),
                            "brand": random.choice(BRANDS),
                            "department": department,
                            "category": category,
                            "subcategory": item_name,
                            "unit_price": price,
                            "unit_cost": cost,
                            "weight_kg": round(random.uniform(0.1, 15.0), 3),
                            "supplier_id": random.randint(1, 50),
                            "supplier_name": fake.company(),
                            "is_active": random.random() > 0.05,
                            "launch_date": random_date(
                                START_DATE, START_DATE + timedelta(days=365)
                            ).strftime("%Y-%m-%d"),
                        }
                    )
                    product_id += 1
    return rows


def generate_stores(geography_data):
    rows = []
    store_types = [
        "Physical",
        "Physical",
        "Physical",
        "Online",
        "Marketplace",
        "Mobile",
    ]
    for i in range(1, NUM_STORES + 1):
        geo = random.choice(geography_data)
        store_type = random.choice(store_types)
        rows.append(
            {
                "store_id": i,
                "store_name": f"{fake.company()} {'Store' if store_type == 'Physical' else store_type}",
                "store_type": store_type,
                "geography_key": geo["geography_key"],
                "store_size_sqft": random.randint(1000, 50000)
                if store_type == "Physical"
                else None,
                "open_date": random_date(datetime(2018, 1, 1), START_DATE).strftime(
                    "%Y-%m-%d"
                ),
                "close_date": None,
                "is_active": True,
                "manager_name": fake.name(),
                "employee_count": random.randint(5, 200)
                if store_type == "Physical"
                else random.randint(2, 20),
                "annual_revenue_target": round(random.uniform(500000, 10000000), 2),
            }
        )
    return rows


def generate_orders(customers, products, stores):
    orders = []
    order_items = []
    inventory_movements = []

    product_ids = [p["product_id"] for p in products]
    store_ids = [s["store_id"] for s in stores]
    inv_id = 1

    for order_id in range(1, NUM_ORDERS + 1):
        customer = random.choice(customers)
        order_date = random_timestamp()
        status = random.choice(ORDER_STATUSES)

        ship_date = None
        delivery_date = None
        if status in ("Shipped", "Delivered"):
            ship_date = order_date + timedelta(days=random.randint(1, 3))
        if status == "Delivered":
            delivery_date = ship_date + timedelta(days=random.randint(1, 7))

        num_items = random.choices([1, 2, 3, 4, 5], weights=[35, 30, 20, 10, 5])[0]
        selected_products = random.sample(products, min(num_items, len(products)))

        gross = 0
        for idx, prod in enumerate(selected_products, 1):
            qty = random.choices([1, 2, 3], weights=[60, 30, 10])[0]
            disc_pct = random.choices([0, 5, 10, 15, 20], weights=[50, 20, 15, 10, 5])[
                0
            ]
            line_total = round(qty * prod["unit_price"] * (1 - disc_pct / 100), 2)
            line_cost = round(qty * prod["unit_cost"], 2)
            gross += line_total

            order_items.append(
                {
                    "order_item_id": idx,
                    "order_id": order_id,
                    "product_id": prod["product_id"],
                    "quantity": qty,
                    "unit_price": prod["unit_price"],
                    "discount_pct": disc_pct,
                    "line_total": line_total,
                }
            )

            if status not in ("Cancelled",):
                inventory_movements.append(
                    {
                        "inventory_id": inv_id,
                        "product_id": prod["product_id"],
                        "store_id": random.choice(store_ids),
                        "movement_type": "SALE",
                        "quantity": -qty,
                        "movement_date": order_date.strftime("%Y-%m-%d %H:%M:%S"),
                        "reference_id": order_id,
                    }
                )
                inv_id += 1

        discount_amount = round(gross * random.uniform(0, 0.1), 2)
        net = round(gross - discount_amount, 2)
        tax = round(net * 0.08, 2)
        shipping = round(random.uniform(0, 15.99), 2) if random.random() > 0.3 else 0
        total = round(net + tax + shipping, 2)

        orders.append(
            {
                "order_id": order_id,
                "customer_id": customer["customer_id"],
                "store_id": random.choice(store_ids),
                "order_date": order_date.strftime("%Y-%m-%d %H:%M:%S"),
                "ship_date": ship_date.strftime("%Y-%m-%d %H:%M:%S")
                if ship_date
                else None,
                "delivery_date": delivery_date.strftime("%Y-%m-%d %H:%M:%S")
                if delivery_date
                else None,
                "order_status": status,
                "payment_method": random.choice(PAYMENT_METHODS),
                "shipping_method": random.choice(SHIPPING_METHODS),
                "discount_amount": discount_amount,
                "shipping_cost": shipping,
                "tax_amount": tax,
                "total_amount": total,
                "currency_code": "USD",
            }
        )

    # Add RECEIPT inventory movements (stock replenishment)
    for prod in products:
        for _ in range(random.randint(3, 10)):
            inventory_movements.append(
                {
                    "inventory_id": inv_id,
                    "product_id": prod["product_id"],
                    "store_id": random.choice(store_ids),
                    "movement_type": "RECEIPT",
                    "quantity": random.randint(10, 500),
                    "movement_date": random_timestamp().strftime("%Y-%m-%d %H:%M:%S"),
                    "reference_id": None,
                }
            )
            inv_id += 1

    return orders, order_items, inventory_movements


def generate_customer_events(customers):
    rows = []
    customer_ids = [c["customer_id"] for c in customers]

    for event_id in range(1, NUM_EVENTS + 1):
        cust_id = random.choice(customer_ids)
        event_ts = random_timestamp()
        event_type = random.choice(EVENT_TYPES)

        category_map = {
            "page_view": "browsing",
            "add_to_cart": "transaction",
            "purchase": "transaction",
            "review": "engagement",
            "support_ticket": "support",
            "wishlist_add": "engagement",
            "search": "browsing",
        }

        rows.append(
            {
                "event_id": event_id,
                "customer_id": cust_id,
                "event_type": event_type,
                "event_timestamp": event_ts.strftime("%Y-%m-%d %H:%M:%S"),
                "session_id": f"sess_{cust_id}_{event_ts.strftime('%Y%m%d')}_{random.randint(1, 5)}",
                "page_url": f"/{random.choice(['home', 'products', 'cart', 'checkout', 'account', 'search'])}",
                "device_type": random.choice(DEVICE_TYPES),
                "browser": random.choice(BROWSERS),
                "referrer_source": random.choice(REFERRERS),
                "event_properties": "{}",
            }
        )

    return rows


# ---------- Output Functions ----------


def write_csv(data, filename, fieldnames):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    filepath = OUTPUT_DIR / filename
    with open(filepath, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    print(f"  Written {len(data):,} rows to {filepath}")


def write_insert_sql(data, table_name, filename):
    """Generate SQL INSERT statements for loading without Python DB connection."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    filepath = OUTPUT_DIR / filename

    if not data:
        return

    columns = list(data[0].keys())
    col_str = ", ".join(columns)

    with open(filepath, "w") as f:
        f.write(f"-- Auto-generated data for {table_name}\n")
        f.write(f"-- Generated: {datetime.now().isoformat()}\n")
        f.write(f"-- Row count: {len(data):,}\n\n")

        batch_size = 500
        for i in range(0, len(data), batch_size):
            batch = data[i : i + batch_size]
            f.write(f"INSERT INTO {table_name} ({col_str}) VALUES\n")
            values = []
            for row in batch:
                vals = []
                for col in columns:
                    v = row[col]
                    if v is None:
                        vals.append("NULL")
                    elif isinstance(v, bool):
                        vals.append("TRUE" if v else "FALSE")
                    elif isinstance(v, (int, float)):
                        vals.append(str(v))
                    else:
                        vals.append("'" + str(v).replace("'", "''") + "'")
                values.append(f"  ({', '.join(vals)})")
            f.write(",\n".join(values))
            f.write(";\n\n")

    print(f"  Written {len(data):,} rows to {filepath}")


def build_connection_string(args):
    if args.database_url:
        return args.database_url

    env_database_url = os.environ.get("DATABASE_URL")
    if env_database_url:
        return env_database_url

    parts = [
        f"dbname={args.db_name}",
        f"user={args.db_user}",
        f"host={args.db_host}",
        f"port={args.db_port}",
    ]

    if args.db_password:
        parts.append(f"password={args.db_password}")

    return " ".join(parts)


def load_to_postgres(data, table_name, columns, conn_str):
    """Load data directly into PostgreSQL staging tables."""
    try:
        import psycopg2
        from psycopg2.extras import execute_values
    except ImportError:
        print("  psycopg2 not installed, skipping DB load")
        return False

    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        cur.execute(f"TRUNCATE TABLE {table_name}")

        values = [[row[col] for col in columns] for row in data]
        col_str = ", ".join(columns)
        insert_sql = f"INSERT INTO {table_name} ({col_str}) VALUES %s"
        execute_values(cur, insert_sql, values, page_size=1000)

        conn.commit()
        print(f"  Loaded {len(data):,} rows into {table_name}")
        cur.close()
        conn.close()
        return True
    except Exception as e:
        print(f"  DB load failed for {table_name}: {e}")
        return False


# ---------- Main ----------


def main():
    parser = argparse.ArgumentParser(description="Generate e-commerce sample data")
    parser.add_argument("--csv", action="store_true", help="Export as CSV files")
    parser.add_argument("--sql", action="store_true", help="Export as SQL INSERT files")
    parser.add_argument(
        "--db", action="store_true", help="Load directly into PostgreSQL"
    )
    parser.add_argument(
        "--database-url", help="Full PostgreSQL DSN. Overrides individual DB args"
    )
    parser.add_argument(
        "--db-name", default="ecommerce_dw", help="PostgreSQL database name"
    )
    parser.add_argument("--db-user", default="postgres", help="PostgreSQL username")
    parser.add_argument("--db-password", help="PostgreSQL password (optional)")
    parser.add_argument("--db-host", default="localhost", help="PostgreSQL host")
    parser.add_argument("--db-port", default="5432", help="PostgreSQL port")
    args = parser.parse_args()

    if not any([args.csv, args.sql, args.db]):
        args.csv = True
        args.sql = True

    print("=" * 60)
    print("E-Commerce Data Warehouse - Data Generator")
    print("=" * 60)

    print("\n[1/6] Generating geography data...")
    geography = generate_geography()
    print(f"  Generated {len(geography):,} geography records")

    print("\n[2/6] Generating customer data...")
    customers = generate_customers(geography)
    print(f"  Generated {len(customers):,} customer records")

    print("\n[3/6] Generating product data...")
    products = generate_products()
    print(f"  Generated {len(products):,} product records")

    print("\n[4/6] Generating store data...")
    stores = generate_stores(geography)
    print(f"  Generated {len(stores):,} store records")

    print("\n[5/6] Generating orders and inventory...")
    orders, order_items, inventory = generate_orders(customers, products, stores)
    print(f"  Generated {len(orders):,} orders")
    print(f"  Generated {len(order_items):,} order items")
    print(f"  Generated {len(inventory):,} inventory movements")

    print("\n[6/6] Generating customer events...")
    events = generate_customer_events(customers)
    print(f"  Generated {len(events):,} customer events")

    # Export
    if args.csv:
        print("\n--- Exporting CSV files ---")
        write_csv(geography, "geography.csv", geography[0].keys())
        write_csv(customers, "customers.csv", customers[0].keys())
        write_csv(products, "products.csv", products[0].keys())
        write_csv(stores, "stores.csv", stores[0].keys())
        write_csv(orders, "orders.csv", orders[0].keys())
        write_csv(order_items, "order_items.csv", order_items[0].keys())
        write_csv(inventory, "inventory.csv", inventory[0].keys())
        write_csv(events, "customer_events.csv", events[0].keys())

    if args.sql:
        print("\n--- Exporting SQL INSERT files ---")
        write_insert_sql(geography, "dim_geography", "load_geography.sql")
        write_insert_sql(customers, "staging.stg_customers", "load_customers.sql")
        write_insert_sql(products, "staging.stg_products", "load_products.sql")
        write_insert_sql(stores, "dim_stores", "load_stores.sql")
        write_insert_sql(orders, "staging.stg_orders", "load_orders.sql")
        write_insert_sql(order_items, "staging.stg_order_items", "load_order_items.sql")
        write_insert_sql(inventory, "staging.stg_inventory", "load_inventory.sql")
        write_insert_sql(events, "staging.stg_customer_events", "load_events.sql")

    if args.db:
        print("\n--- Loading into PostgreSQL ---")
        conn_str = build_connection_string(args)
        load_to_postgres(
            geography, "dim_geography", list(geography[0].keys()), conn_str
        )
        load_to_postgres(
            customers, "staging.stg_customers", list(customers[0].keys()), conn_str
        )
        load_to_postgres(
            products, "staging.stg_products", list(products[0].keys()), conn_str
        )
        load_to_postgres(stores, "dim_stores", list(stores[0].keys()), conn_str)
        load_to_postgres(orders, "staging.stg_orders", list(orders[0].keys()), conn_str)
        load_to_postgres(
            order_items,
            "staging.stg_order_items",
            list(order_items[0].keys()),
            conn_str,
        )
        load_to_postgres(
            inventory, "staging.stg_inventory", list(inventory[0].keys()), conn_str
        )
        load_to_postgres(
            events, "staging.stg_customer_events", list(events[0].keys()), conn_str
        )

    print("\n" + "=" * 60)
    print("Data generation complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
