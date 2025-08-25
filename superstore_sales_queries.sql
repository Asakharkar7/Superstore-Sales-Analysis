DROP TABLE IF EXISTS superstore_sales;

CREATE TABLE superstore_sales (
    row_id INT,
    order_id VARCHAR(50),
    order_date TEXT,     -- keep as text first
    ship_date TEXT,      -- keep as text first
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(200),
    sales NUMERIC,
    quantity INT,
    discount NUMERIC,
    profit NUMERIC
);


Select * from superstore_sales

SELECT COUNT(*) FROM superstore_sales;
SELECT * FROM superstore_sales LIMIT 10;


ALTER TABLE superstore_sales
ALTER COLUMN order_date TYPE DATE USING order_date::DATE,
ALTER COLUMN ship_date  TYPE DATE USING ship_date::DATE;


SELECT order_id, order_date, ship_date
FROM superstore_sales
LIMIT 5;


-- Row count
SELECT COUNT(*) AS rows FROM superstore_sales;

-- Date range
SELECT MIN(order_date) AS min_order_date, MAX(order_date) AS max_order_date
FROM superstore_sales;

-- Nulls overview
SELECT
  SUM((order_id      IS NULL)::int) AS n_order_id_nulls,
  SUM((order_date    IS NULL)::int) AS n_order_date_nulls,
  SUM((ship_date     IS NULL)::int) AS n_ship_date_nulls,
  SUM((customer_id   IS NULL)::int) AS n_customer_id_nulls,
  SUM((product_id    IS NULL)::int) AS n_product_id_nulls,
  SUM((sales         IS NULL)::int) AS n_sales_nulls,
  SUM((profit        IS NULL)::int) AS n_profit_nulls
FROM superstore_sales;


SELECT
  ROUND(SUM(sales),2)                                    AS total_sales,
  COUNT(DISTINCT order_id)                               AS total_orders,
  COUNT(DISTINCT customer_id)                            AS total_customers,
  ROUND(SUM(profit),2)                                   AS total_profit,
  ROUND(SUM(sales)::numeric / NULLIF(COUNT(DISTINCT order_id),0),2) AS aov,
  ROUND(SUM(profit)::numeric / NULLIF(SUM(sales),0),4)   AS profit_margin_ratio
FROM superstore_sales;



WITH m AS (
  SELECT
    date_trunc('month', order_date)::date AS month,
    SUM(sales)                            AS sales,
    SUM(profit)                           AS profit,
    COUNT(DISTINCT order_id)              AS orders
  FROM superstore_sales
  GROUP BY 1
)
SELECT
  month,
  sales,
  profit,
  orders,
  ROUND(sales / NULLIF(orders,0), 2)                               AS aov,
  LAG(sales, 12)  OVER (ORDER BY month)                            AS sales_last_year,
  ROUND( (sales - LAG(sales,12) OVER (ORDER BY month))
         / NULLIF(LAG(sales,12) OVER (ORDER BY month),0) , 4)      AS sales_yoy_pct
FROM m
ORDER BY month;



-- Region
SELECT region,
       ROUND(SUM(sales),2)  AS sales,
       ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)::numeric/NULLIF(SUM(sales),0),4) AS margin
FROM superstore_sales
GROUP BY region
ORDER BY sales DESC;

-- Category / Sub-category
SELECT category, sub_category,
       ROUND(SUM(sales),2)  AS sales,
       ROUND(SUM(profit),2) AS profit
FROM superstore_sales
GROUP BY category, sub_category
ORDER BY sales DESC;


SELECT ship_mode,
       ROUND(AVG(ship_date - order_date),2) AS avg_delivery_days,
       COUNT(*)                             AS shipments
FROM superstore_sales
GROUP BY ship_mode
ORDER BY shipments DESC;



WITH first_order AS (
  SELECT customer_id, MIN(order_date) AS first_order_date
  FROM superstore_sales
  GROUP BY customer_id
),
orders AS (
  SELECT date_trunc('month', s.order_date)::date AS month,
         CASE WHEN s.order_date = f.first_order_date THEN 'New' ELSE 'Repeat' END AS cust_type,
         SUM(s.sales) AS sales
  FROM superstore_sales s
  JOIN first_order f USING (customer_id)
  GROUP BY 1,2
)
SELECT month,
       SUM(CASE WHEN cust_type='New'    THEN sales END) AS new_sales,
       SUM(CASE WHEN cust_type='Repeat' THEN sales END) AS repeat_sales
FROM orders
GROUP BY month
ORDER BY month;



CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT
  date_trunc('month', order_date)::date AS month,
  SUM(sales)   AS sales,
  SUM(profit)  AS profit,
  COUNT(DISTINCT order_id) AS orders
FROM superstore_sales
GROUP BY 1;

CREATE OR REPLACE VIEW vw_region_sales AS
SELECT region,
       SUM(sales)  AS sales,
       SUM(profit) AS profit
FROM superstore_sales
GROUP BY region;

CREATE OR REPLACE VIEW vw_category_sales AS
SELECT category, sub_category,
       SUM(sales)  AS sales,
       SUM(profit) AS profit
FROM superstore_sales
GROUP BY category, sub_category;

CREATE OR REPLACE VIEW vw_shipmode_delivery AS
SELECT ship_mode,
       AVG(ship_date - order_date) AS avg_delivery_days,
       COUNT(*) AS shipments
FROM superstore_sales
GROUP BY ship_mode;



CREATE INDEX idx_orders_date ON superstore_sales(order_date);
CREATE INDEX idx_orders_region ON superstore_sales(region);
CREATE INDEX idx_orders_category ON superstore_sales(category, sub_category);

SELECT current_database();              -- shows your current DB
SHOW port;                              -- shows the PostgreSQL port (usually 5432)
SHOW listen_addresses;                  -- should include localhost


ALTER USER postgres WITH PASSWORD 'NewSecurePassword123';


