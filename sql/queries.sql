--Q1. Total revenue by gender
SELECT 
  gender, 
  SUM(purchase_amount) AS revenue
FROM customer 
GROUP BY gender
ORDER BY revenue DESC;

--Q2. Discount users who spent more than overall average
SELECT 
  customer_id, 
  purchase_amount
FROM customer
WHERE discount_applied = 'Yes'
  AND purchase_amount > (SELECT AVG(purchase_amount) FROM customer)
ORDER BY purchase_amount DESC;

--Q3. Top 5 products by avg rating (min 10 ratings)
SELECT 
  item_purchased, 
  ROUND(AVG(review_rating::numeric), 2) AS avg_rating
FROM customer
GROUP BY item_purchased
HAVING COUNT(review_rating) >= 10
ORDER BY avg_rating DESC
LIMIT 5;

--Q4. Avg purchase amount: Standard vs Express
SELECT
  shipping_type,
  ROUND(AVG(purchase_amount::numeric), 2) AS avg_purchase_amount
FROM customer
WHERE shipping_type IN ('Standard','Express')
GROUP BY shipping_type
ORDER BY avg_purchase_amount DESC;

--Q5. Subscribers vs non-subscribers: avg + total revenue
SELECT
  subscription_status,
  COUNT(DISTINCT customer_id) AS customers,
  COUNT(*) AS orders,
  ROUND(AVG(purchase_amount)::numeric, 2) AS avg_spend,
  ROUND(SUM(purchase_amount)::numeric, 2) AS total_revenue
FROM customer
GROUP BY subscription_status
ORDER BY total_revenue DESC, avg_spend DESC;

--Q6. Top 5 products by discount rate
SELECT
  item_purchased,
  COUNT(*) AS total_orders,
  ROUND(100 * AVG((discount_applied = 'Yes')::int)::numeric, 2) AS discount_rate_pct
FROM customer
GROUP BY item_purchased
ORDER BY discount_rate_pct DESC, total_orders DESC, item_purchased
LIMIT 5;

--Q7. Customer segments by previous purchases
WITH customer_type AS (
  SELECT
    customer_id,
    previous_purchases,
    CASE
      WHEN previous_purchases = 0 THEN 'New'
      WHEN previous_purchases BETWEEN 1 AND 5 THEN 'Returning'
      ELSE 'Loyal'
    END AS customer_segment
  FROM customer
)
SELECT 
  customer_segment, 
  COUNT(*) AS customer_count
FROM customer_type 
GROUP BY customer_segment
ORDER BY customer_count DESC;

--Q8. Top 3 most purchased products within each category
WITH item_counts AS (
  SELECT
    category,
    item_purchased,
    COUNT(*) AS total_orders,
    DENSE_RANK() OVER (
      PARTITION BY category
      ORDER BY COUNT(*) DESC
    ) AS item_rank
  FROM customer
  GROUP BY category, item_purchased
)
SELECT
  category,
  item_rank,
  item_purchased,
  total_orders
FROM item_counts
WHERE item_rank <= 3
ORDER BY category, item_rank, total_orders DESC;

--Q9. Repeat buyers and subscription likelihood
WITH flags AS (
  SELECT
    CASE WHEN previous_purchases > 5 THEN 'Repeat (>5)' ELSE 'Non-repeat (<=5)' END AS buyer_type,
    subscription_status
  FROM customer
)
SELECT
  buyer_type,
  COUNT(*) AS customers,
  SUM((subscription_status = 'Yes')::int) AS subscribed_customers,
  ROUND(100 * AVG((subscription_status = 'Yes')::int)::numeric, 2) AS subscribed_rate_pct
FROM flags
GROUP BY buyer_type
ORDER BY buyer_type;

--Q10. Revenue by age group
SELECT 
  age_group,
  SUM(purchase_amount) AS total_revenue
FROM customer
GROUP BY age_group
ORDER BY total_revenue DESC;
