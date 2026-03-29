-- =====================================================
-- SECTION 1: DATA UNDERSTANDING AND VALIDATION
-- =====================================================


-- 1. Check the total number of rows in the dataset
-- and confirm whether row_id is unique for every record.
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT row_id) AS unique_row_ids
FROM superstore_full;


-- 2. Compare total rows with distinct order IDs
-- to confirm that the dataset is line level and not order level.
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS total_orders
FROM superstore_full;


-- 3. Identify sample orders that contain more than one line item
-- to prove that one order can appear across multiple rows.
SELECT 
    order_id,
    COUNT(*) AS line_count
FROM superstore_full
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY line_count DESC
LIMIT 10;


-- 4. Check for missing values in key columns
-- to make sure important business fields are complete.
SELECT
    SUM(CASE WHEN row_id IS NULL THEN 1 ELSE 0 END) AS null_row_id,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN ship_date IS NULL THEN 1 ELSE 0 END) AS null_ship_date,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END) AS null_discount,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END) AS null_profit
FROM superstore_full;


-- 5. Review the minimum and maximum values of key numeric fields
-- to spot suspicious or extreme values in sales, quantity, discount, and profit.
SELECT
    MIN(sales) AS min_sales,
    MAX(sales) AS max_sales,
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    MIN(discount) AS min_discount,
    MAX(discount) AS max_discount,
    MIN(profit) AS min_profit,
    MAX(profit) AS max_profit
FROM superstore_full;


-- 6. Check whether any records have ship dates earlier than order dates
-- because that would indicate a data quality issue.
SELECT 
    COUNT(*) AS invalid_ship_records
FROM superstore_full
WHERE ship_date < order_date;


-- 7. List all unique category and sub-category combinations
-- to understand the product hierarchy in the dataset.
SELECT DISTINCT
    category,
    sub_category
FROM superstore_full
ORDER BY category, sub_category;


-- =====================================================
-- SECTION 2: CORE BUSINESS METRICS AND OVERALL PERFORMANCE
-- =====================================================

-- 1. Generate a top level KPI summary for the business
-- including total sales, total profit, total quantity sold,
-- total orders, total customers, average order value,
-- and overall profit margin.

SELECT
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS average_order_value,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full;

-- 2. Analyse yearly sales and profit performance
-- to see whether the business is growing over time
-- and whether profit is moving in the same direction as sales.
SELECT
    YEAR(order_date) AS order_year,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY YEAR(order_date)
ORDER BY order_year;

-- 3. Calculate yearly sales and profit growth rates
-- to measure how performance changed from one year to the next.
WITH yearly_performance AS (
    SELECT
        YEAR(order_date) AS order_year,
        ROUND(SUM(sales), 2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit
    FROM superstore_full
    GROUP BY YEAR(order_date)
)
SELECT
    order_year,
    total_sales,
    total_profit,
    ROUND(
        ((total_sales - LAG(total_sales) OVER (ORDER BY order_year)) 
        / LAG(total_sales) OVER (ORDER BY order_year)) * 100, 2
    ) AS sales_growth_percent,
    ROUND(
        ((total_profit - LAG(total_profit) OVER (ORDER BY order_year)) 
        / LAG(total_profit) OVER (ORDER BY order_year)) * 100, 2
    ) AS profit_growth_percent
FROM yearly_performance
ORDER BY order_year;

-- 4. Compare category level performance
-- to identify which categories drive the most sales and profit,
-- and whether strong revenue also translates into strong profitability.
SELECT
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY category
ORDER BY total_sales DESC;

-- 5. Analyse sub-category performance
-- to identify which sub-categories drive sales and profit,
-- and to find weaker areas hidden inside each main category.
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY category, sub_category
ORDER BY total_sales DESC;

-- 6. Identify the top individual products by sales
-- to see which products drive the highest revenue for the business.
SELECT
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY product_name, category, sub_category
ORDER BY total_sales DESC
LIMIT 10;

-- 7. Identify the top individual products by profit
-- to find the products creating the most value for the business.
SELECT
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY product_name, category, sub_category
ORDER BY total_profit DESC
LIMIT 10;

-- 8. Identify the worst individual products by profit
-- to find products that are contributing the largest losses.
SELECT
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY product_name, category, sub_category
ORDER BY total_profit ASC
LIMIT 10;

-- 9. Measure how much total sales and total profit come from the top 10 products by profit
-- to assess whether value creation is concentrated in a small number of products.
WITH product_performance AS (
    SELECT
        product_name,
        ROUND(SUM(sales), 2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit
    FROM superstore_full
    GROUP BY product_name
),
top_10_products AS (
    SELECT *
    FROM product_performance
    ORDER BY total_profit DESC
    LIMIT 10
)
SELECT
    ROUND(SUM(total_sales), 2) AS top_10_sales,
    ROUND(SUM(total_profit), 2) AS top_10_profit,
    ROUND((SUM(total_sales) / (SELECT SUM(sales) FROM superstore_full)) * 100, 2) AS top_10_sales_share_percent,
    ROUND((SUM(total_profit) / (SELECT SUM(profit) FROM superstore_full)) * 100, 2) AS top_10_profit_share_percent
FROM top_10_products;



-- =====================================================
-- SECTION 3: CUSTOMER PERFORMANCE AND VALUE
-- =====================================================

-- 10. Identify the top customers by sales and profit
-- to understand who contributes the most revenue and value.
SELECT
    customer_id,
    customer_name,
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS average_order_value,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY customer_id, customer_name, segment
ORDER BY total_sales DESC
LIMIT 10;

-- 11. Identify the top customers by profit
-- to find the customers creating the most value for the business.
SELECT
    customer_id,
    customer_name,
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS average_order_value,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY customer_id, customer_name, segment
ORDER BY total_profit DESC
LIMIT 10;

-- 12. Measure how much total sales and total profit come from the top 10 customers by profit
-- to assess whether customer value is concentrated in a small number of accounts.
WITH customer_performance AS (
    SELECT
        customer_id,
        customer_name,
        ROUND(SUM(sales), 2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit
    FROM superstore_full
    GROUP BY customer_id, customer_name
),
top_10_customers AS (
    SELECT *
    FROM customer_performance
    ORDER BY total_profit DESC
    LIMIT 10
)
SELECT
    ROUND(SUM(total_sales), 2) AS top_10_sales,
    ROUND(SUM(total_profit), 2) AS top_10_profit,
    ROUND((SUM(total_sales) / (SELECT SUM(sales) FROM superstore_full)) * 100, 2) AS top_10_sales_share_percent,
    ROUND((SUM(total_profit) / (SELECT SUM(profit) FROM superstore_full)) * 100, 2) AS top_10_profit_share_percent
FROM top_10_customers;

-- 13. Compare customer segment performance
-- to understand which segments generate the most sales, profit, and margin.
SELECT
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS average_order_value,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY segment
ORDER BY total_sales DESC;


-- =====================================================
-- SECTION 4: REGIONAL PERFORMANCE
-- =====================================================

-- 14. Compare regional performance
-- to identify which regions generate the most sales, profit, and margin.
SELECT
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS average_order_value,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY region
ORDER BY total_sales DESC;

-- 15. Compare state level performance
-- to identify the best and worst performing states by sales, profit, and margin.
SELECT
    state,
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY state, region
ORDER BY total_sales DESC;

-- 16. Identify the top states by total profit
-- to find the strongest geographic contributors to business value.
SELECT
    state,
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY state, region
ORDER BY total_profit DESC
LIMIT 10;

-- 17. Identify the worst states by total profit
-- to find the largest geographic profit drains in the business.
SELECT
    state,
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY state, region
ORDER BY total_profit ASC
LIMIT 10;



-- =====================================================
-- SECTION 5: DISCOUNT AND PROFITABILITY ANALYSIS
-- =====================================================

-- 18. Compare performance by discount level
-- to see how increasing discount rates affect sales, profit, and margin.
SELECT
    discount,
    COUNT(*) AS transaction_lines,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY discount
ORDER BY discount;

-- 19. Analyse category performance across discount levels
-- to see whether some categories are more exposed to discount driven losses.
SELECT
    category,
    discount,
    COUNT(*) AS transaction_lines,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY category, discount
ORDER BY category, discount;

-- 20. Analyse sub-category performance across discount levels
-- to identify which sub-categories are most vulnerable to discount driven losses.
SELECT
    category,
    sub_category,
    discount,
    COUNT(*) AS transaction_lines,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY category, sub_category, discount
ORDER BY category, sub_category, discount;

-- 21. Compare average discount and profitability by state
-- to test whether major loss making states are also associated with heavier discounting.
SELECT
    state,
    region,
    ROUND(AVG(discount), 2) AS average_discount,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY state, region
ORDER BY total_profit ASC;

-- 22. Identify the weakest category and state combinations
-- to find where major product groups are losing the most money geographically.
SELECT
    state,
    region,
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_percent
FROM superstore_full
GROUP BY state, region, category
HAVING SUM(profit) < 0
ORDER BY total_profit ASC
LIMIT 15;

SELECT *
FROM superstore_full;