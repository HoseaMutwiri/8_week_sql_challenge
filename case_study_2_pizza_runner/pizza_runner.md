# 🍕 Case Study #2: Pizza Runner - Pizza Metrics Solutions

This repository contains my SQL solutions for the **Section A: Pizza Metrics** questions from the [Pizza Runner Case Study #2](https://8weeksqlchallenge.com/case-study-2/).

![PIZZA RUNNER:](https://8weeksqlchallenge.com/images/case-study-designs/2.png)

The primary objective of this section is to extract operational insights regarding total pizza order volume, active customer trends, runner delivery success rates, and basic customer behavior patterns using aggregation and string formatting functions.

---

## 🛠️ Tech Stack & Methods
* **Database Engine:** PostgreSQL
* **SQL Techniques Used:** Common Table Expressions (CTEs), Aggregation (`COUNT`, `DISTINCT`), Table Joins (`INNER JOIN`), String/Date Transformation (`TO_CHAR` / Date formatting formatting syntax), Conditional Logic (`CASE WHEN`).
* **Python 3.13.3:** pandas for datacleaning
---

## 📊 Solutions and Insights

### Q1. How many pizzas were ordered?
```sql
SELECT COUNT(pizza_id) AS number_of_pizzas_ordered
FROM pizza_runner.customer_orders;
```
**Results:** number_of_pizzas_ordered 14

![q1:](images/q1_number_of_pizzas_ordered.PNG)

### Q2. How many unique customer orders were made?

``` sql
SQLSELECT COUNT(DISTINCT(customer_id)) AS unique_customer_orders
FROM pizza_runner.customer_orders;
```
**Results:** unique_customer_orders 5

![q2:](images\q2_pm.PNG)

### Q3. How many successful orders were delivered by each runner?

```SQL
SELECT runner_id, COUNT(*) AS number_of_successful_orders
FROM pizza_runner.runner_orders
WHERE cancellation = 'No Cancellation'
GROUP BY runner_id
ORDER BY number_of_successful_orders;
```
**Results:**

![q2:](images\q3_number_of_successful_orders_by_runner.PNG)

### Q4. How many of each type of pizza was delivered?

```SQL
SELECT 
    c.pizza_id,
    COUNT(*) AS number_of_pizza_delivered
FROM pizza_runner.runner_orders AS r
JOIN pizza_runner.customer_orders AS c
  ON r.order_id = c.order_id
WHERE r.cancellation = 'No Cancellation'
GROUP BY c.pizza_id
ORDER BY number_of_pizza_delivered;
```
**Results:**

![q2:](images\q4_number_of_pizzas_delivered_by_type.PNG)

### Q5. How many Vegetarian and Meatlovers were ordered by each customer?

```SQL
SELECT n.pizza_name, c.customer_id, COUNT(*) AS number_of_pizzas_ordered
FROM pizza_runner.pizza_names AS n
JOIN pizza_runner.customer_orders AS c
  ON c.pizza_id = n.pizza_id
GROUP BY n.pizza_name, c.customer_id
ORDER BY c.customer_id;
```
**Results:**

![q5:](images\q5_number_of_pizzas_ordered.PNG)

### Q6. What was the maximum number of pizzas delivered in a single order?

```SQL
SELECT 
    COUNT(*) AS number_of_pizza_delivered
FROM pizza_runner.runner_orders AS r
JOIN pizza_runner.customer_orders AS c
  ON r.order_id = c.order_id
WHERE r.cancellation = 'No Cancellation'
GROUP BY c.order_id
ORDER BY number_of_pizza_delivered DESC
LIMIT 1;
```
**Results:**

![q6:](images\q6_pm.PNG)

### Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```SQL
WITH delivered AS (
    SELECT 
        r.order_id,
        r.cancellation,
        c.customer_id,
        c.pizza_id,
        c.exclusions,
        c.extras
    FROM pizza_runner.runner_orders AS r
    JOIN pizza_runner.customer_orders AS c
      ON r.order_id = c.order_id
    WHERE r.cancellation = 'No Cancellation'
),
casedelivered AS (
    SELECT order_id, customer_id, pizza_id, exclusions, extras,
    (CASE WHEN exclusions = 'None' AND extras = 'None' THEN 'no_change'
          ELSE 'changed'
     END) AS pizza_change
    FROM delivered
)
SELECT customer_id, pizza_change, COUNT(*) AS change_count
FROM casedelivered
GROUP BY customer_id, pizza_change
ORDER BY pizza_change;
```
**Results:**

![q7:](images\q7_pm.PNG)

### Q8. How many pizzas were delivered that had both exclusions and extras?

```SQL
WITH delivered AS
(
SELECT
    r.order_id,
    r.cancellation,
    c.customer_id,
    c.pizza_id,
    c.exclusions,
    c.extras
FROM pizza_runner.runner_orders AS r
JOIN pizza_runner.customer_orders AS c
ON r.order_id = c.order_id
WHERE r.cancellation = 'No Cancellation'),casedelivered AS(
SELECT order_id,customer_id,pizza_id,exclusions,extras,
(CASE WHEN exclusions = 'None' AND extras = 'None' THEN 'no_change'
    WHEN exclusions != 'None' AND extras != 'None' THEN 'both_changed'
ELSE 'changed'
END) AS pizza_change
FROM delivered)
select pizza_change,COUNT(*) AS change_count
FROM casedelivered
WHERE pizza_change = 'both_changed'
GROUP BY pizza_change;
```


**Results:**

![q8:](images\q8_pm.PNG)

### Q9.What was the total volume of pizzas ordered for each hour of the day?

```SQL
WITH hour_data AS
(SELECT *,
    EXTRACT(HOUR FROM order_time) AS hour_ordered 
FROM pizza_runner.customer_orders)
SELECT hour_ordered,COUNT(*) AS total_pizzas
FROM hour_data
GROUP BY hour_ordered
ORDER BY total_pizzas DESC;
```

**Results:**

![q9:](images\q9_pm.PNG)

### Q10. What was the volume of orders for each day of the week?

```SQL
WITH day_data AS
(SELECT *,
    TO_CHAR(order_time,'FMDay') AS day_ordered 
FROM pizza_runner.customer_orders)
SELECT day_ordered,COUNT(*) AS total_pizzas
FROM day_data
GROUP BY day_ordered
ORDER BY total_pizzas DESC;
```

**Results:**

![q10:](images\q10_pm.PNG)

## 📈 Key Findings from Pizza Metrics
* **Product Dominance:** Meatlovers (pizza_id: 1) is drastically more popular than Vegetarian, making up 75% of all successful deliveries (9 out of 12 delivered pizzas).

* **Peak Operations:** Saturday and Wednesday see the highest incoming traffic volume (5 orders each), while Friday has the lowest operational footprint.
