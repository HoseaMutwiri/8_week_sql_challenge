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

```sql
SELECT COUNT(DISTINCT(customer_id)) AS unique_customer_orders
FROM pizza_runner.customer_orders;
```
**Results:** unique_customer_orders 5

![q2:](images/q2_pm.PNG)

### Q3. How many successful orders were delivered by each runner?

```SQL
SELECT runner_id, COUNT(*) AS number_of_successful_orders
FROM pizza_runner.runner_orders
WHERE cancellation = 'No Cancellation'
GROUP BY runner_id
ORDER BY number_of_successful_orders;
```
**Results:**

![q3:](images/q3_number_of_successful_orders_by_runner.PNG)

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

![q4:](images/q4_number_of_pizzas_delivered_by_type.PNG)

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

![q5:](images/q5_number_of_pizzas_ordered.PNG)

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

![q6:](images/q6_pm.PNG)

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

![q7:](images/q7_pm.PNG)

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

![q8:](images/q8_pm.PNG)

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

![q9:](images/q9_pm.PNG)

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

![q10:](images/q10_pm.PNG)

## 📈 Key Findings from Pizza Metrics
* **Product Dominance:** Meatlovers (pizza_id: 1) is drastically more popular than Vegetarian, making up 75% of all successful deliveries (9 out of 12 delivered pizzas).

* **Peak Operations:** Saturday and Wednesday see the highest incoming traffic volume (5 orders each), while Friday has the lowest operational footprint.


## Pizza Runner Challenge - Runner and Customer Experience Analytics

## 📊 Solutions and Insights

### Q1: How many runners signed up for each 1-week period? (i.e. week starts 2021-01-01)

```SQL
SELECT 
    registration_week_number,
    COUNT(runner_id) AS count_runners_registered
FROM (
    SELECT 
        runner_id,
        registration_date,
        CONCAT('Week ', EXTRACT(WEEK FROM registration_date)) AS registration_week_number
    FROM pizza_runner.runners
) AS base_query
GROUP BY registration_week_number
ORDER BY registration_week_number;
```

**Results:**

![q1:](images/q1_rce.PNG)

### Q2: What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```SQL
WITH time_calculator AS (
    SELECT 
        r.runner_id,
        ROUND((EXTRACT(EPOCH FROM (r.pickup_time::TIMESTAMP - c.order_time::TIMESTAMP)) / 60), 2) AS time_diff
    FROM pizza_runner.runner_orders AS r
    JOIN pizza_runner.customer_orders AS c ON c.order_id = r.order_id
)
SELECT 
    runner_id, 
    ROUND(AVG(time_diff), 0) AS average_in_minutes
FROM time_calculator
GROUP BY runner_id
ORDER BY runner_id;
```

**Results:**

![q2:](images/q2_rce.PNG)

### Q3: Is there any relationship between the number of pizzas and how long the order takes to prepare?

```SQL
WITH pizza_prep AS (
    SELECT 
        c.pizza_id,
        ROUND((EXTRACT(EPOCH FROM (r.pickup_time::TIMESTAMP - c.order_time::TIMESTAMP)) / 60), 2) AS prep_time
    FROM pizza_runner.runner_orders AS r
    JOIN pizza_runner.customer_orders AS c ON c.order_id = r.order_id
)
SELECT 
    pizza_id,
    COUNT(pizza_id) AS total_number_of_pizzas_ordered,
    ROUND(AVG(prep_time), 0) AS average_prep_time_in_min_from_order_date_to_pick_up_time
FROM pizza_prep
GROUP BY pizza_id;
```
**Results:**

![q3:](images/q3_rce.PNG)


### Q4: What was the average distance travelled for each customer?

```SQL
SELECT 
    c.customer_id,
    CONCAT(ROUND(AVG(r.distance::NUMERIC), 2), ' km') AS avg_distance
FROM pizza_runner.runner_orders AS r
JOIN pizza_runner.customer_orders AS c ON c.order_id = r.order_id
GROUP BY c.customer_id
ORDER BY c.customer_id;
```
**Results:**

![q4:](images/q4_rce.PNG)

### Q5: What was the difference between the longest and shortest delivery times for all orders?
```SQL
SELECT 
    CONCAT((MAX(duration::NUMERIC) - MIN(duration::NUMERIC)), ' MINUTES') AS diff_longest_shortest_delivery_time
FROM pizza_runner.runner_orders;
```

**Results:**


![q5:](images/q5_rce.PNG)

### Q6: What was the average speed for each runner for each delivery and do you notice any trend for these values?

```SQL
-- Formula applied: Speed = (Distance in meters) / (Duration in seconds)
SELECT 
    order_id,
    runner_id,
    CONCAT(ROUND(AVG((distance::NUMERIC * 1000) / (duration::NUMERIC * 60)), 2), ' M/S') AS "speed_in_M/S"
FROM pizza_runner.runner_orders
WHERE distance IS NOT NULL OR duration IS NOT NULL
GROUP BY order_id, runner_id
ORDER BY order_id;
```
**Results:**

![q6:](images/q6_rce.PNG)

#### Observations & Trends

* **Runner 2 Variance:** Runner 2 shows extreme speed variations, starting at a modest `9.75 M/S (Order 4)` and hitting an extraordinarily high speed of `26.00 M/S (Order 8)`.

* **Runner 1 Consistency:** Runner 1 maintains a highly predictable pacing across their initial batches, averaging around `10 - 12 M/S` before shifting gears up to `16.67 M/S` for Order 10.

### Q7: What is the successful delivery percentage for each runner?

```SQL
SELECT 
    runner_id,
    CONCAT(
        ROUND(
            (COUNT(*) FILTER (WHERE status_b = 'No Cancellation')::NUMERIC / COUNT(*)::NUMERIC) * 100, 
            0
        ), 
        '%'
    ) AS successful_delivery_percent
FROM (
    SELECT 
        runner_id,
        cancellation,
        order_id,
        CASE 
            WHEN cancellation IS NULL OR cancellation IN ('', 'null') THEN 'No Cancellation'
            ELSE 'Cancellation'
        END AS status_b
    FROM pizza_runner.runner_orders
) AS sub_query
GROUP BY runner_id
ORDER BY runner_id;
```

**Results:**

![q7:](images/q7_rce.PNG)
