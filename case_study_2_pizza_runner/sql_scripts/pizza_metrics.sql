-- 1 How many pizzas were ordered?

SELECT COUNT(pizza_id) AS number_of_pizzas_ordered
FROM pizza_runner.customer_orders;


-- 2 How many unique customer orders were made?

SELECT COUNT(DISTINCT(customer_id)) AS  unique_customer_orders
FROM pizza_runner.customer_orders;



-- How many successful orders were delivered by each runner?

SELECT runner_id,COUNT(*) AS number_of_successful_orders
FROM pizza_runner.runner_orders
WHERE cancellation = 'No Cancellation'
GROUP BY runner_id
ORDER BY number_of_successful_orders;



-- How many of each type of pizza was delivered?
SELECT 
    c.pizza_id,
    COUNT(*) AS number_of_pizza_delivered
FROM pizza_runner.runner_orders AS r
JOIN pizza_runner.customer_orders AS c
ON r.order_id = c.order_id
WHERE r.cancellation = 'No Cancellation'
GROUP BY c.pizza_id
ORDER BY number_of_pizza_delivered;




-- How many Vegetarian and Meatlovers were ordered by each customer?

SELECT n.pizza_name,c.customer_id,COUNT(*) AS number_of_pizzas_ordered
FROM pizza_runner.pizza_names AS n
JOIN pizza_runner.customer_orders AS c
ON c.pizza_id = n.pizza_id
GROUP BY n.pizza_name,c.customer_id
ORDER BY c.customer_id;


-- 6 What was the maximum number of pizzas delivered in a single order?

SELECT
    COUNT(*) AS number_of_pizza_delivered
FROM pizza_runner.runner_orders AS r
JOIN pizza_runner.customer_orders AS c
ON r.order_id = c.order_id
WHERE r.cancellation = 'No Cancellation'
GROUP BY c.order_id
ORDER BY number_of_pizza_delivered DESC
LIMIT 1;


-- 7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
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
ELSE 'changed'
END) AS pizza_change
FROM delivered)
select customer_id,pizza_change,count(*) AS change_count
FROM casedelivered
GROUP BY customer_id,pizza_change
ORDER BY pizza_change;

-- 8 How many pizzas were delivered that had both exclusions and extras?

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



-- What was the total volume of pizzas ordered for each hour of the day?

WITH hour_data AS
(SELECT *,
    EXTRACT(HOUR FROM order_time) AS hour_ordered 
FROM pizza_runner.customer_orders)
SELECT hour_ordered,COUNT(*) AS total_pizzas
FROM hour_data
GROUP BY hour_ordered
ORDER BY total_pizzas DESC
;

-- What was the volume of orders for each day of the week?


WITH day_data AS
(SELECT *,
    TO_CHAR(order_time,'FMDay') AS day_ordered 
FROM pizza_runner.customer_orders)
SELECT day_ordered,COUNT(*) AS total_pizzas
FROM day_data
GROUP BY day_ordered
ORDER BY total_pizzas DESC;