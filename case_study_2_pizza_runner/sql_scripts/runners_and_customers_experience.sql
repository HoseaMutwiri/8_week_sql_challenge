-- 1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)


SELECT registration_week_number,count(runner_id) AS count_runners_registered
FROM
(SELECT runner_id,registration_date,CONCAT('Week ',EXTRACT(WEEK FROM registration_date))AS registration_week_number
FROM pizza_runner.runners)
GROUP BY registration_week_number
ORDER BY registration_week_number;




-- 2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?


WITH time_calculator AS 
(SELECT runner_id,ROUND((EXTRACT(EPOCH FROM (pickup_time::TIMESTAMP-order_time::TIMESTAMP))/60),2) AS time_diff
FROM
(SELECT r.runner_id,c.order_time,r.pickup_time 
FROM pizza_runner.runner_orders AS r
JOIN pizza_runner.customer_orders AS c
ON c.order_id=r.order_id))
SELECT runner_id, ROUND(AVG(time_diff),0) AS average_in_minutes
FROM time_calculator
GROUP BY runner_id
ORDER BY runner_id,average_in_minutes;


-- 3 Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH pizza_prep AS
(SELECT pizza_id,
ROUND((EXTRACT(EPOCH FROM (pickup_time::TIMESTAMP-order_time::TIMESTAMP))/60),2) AS prep_time
FROM
(SELECT r.runner_id,c.pizza_id,c.order_time,r.pickup_time 
FROM pizza_runner.runner_orders AS r
JOIN pizza_runner.customer_orders AS c
ON c.order_id=r.order_id))
SELECT pizza_id ,COUNT(pizza_id) AS total_number_of_pizzas_ordered,ROUND(AVG(prep_time),0) AS average_prep_time_in_min_from_order_date_to_pick_up_time
FROM pizza_prep
GROUP BY pizza_id;


-- 4 What was the average distance travelled for each customer?

SELECT customer_id,CONCAT((ROUND(AVG(distance::NUMERIC),2)),' km') AS avg_distance
FROM
    (SELECT r.runner_id,r.distance,c.customer_id
    FROM pizza_runner.runner_orders AS r
    JOIN pizza_runner.customer_orders AS c
    ON c.order_id=r.order_id)
GROUP BY customer_id
ORDER BY customer_id;


-- 5 What was the difference between the longest and shortest delivery times for all orders?

SELECT 
    CONCAT((MAX(duration::NUMERIC)- MIN(duration::NUMERIC)),' MINUTES') AS diff_longest_shortest_delivery_time
FROM pizza_runner.runner_orders;

-- 6 What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT * FROM pizza_runner.runner_orders;

--SPEED IS DISTANCE/TIME
SELECT 
    order_id,
    runner_id,
    CONCAT((ROUND((AVG(((distance::NUMERIC*1000)/((duration::NUMERIC)*60)))),2)),' M/S') AS "speed_in_M/S"
FROM pizza_runner.runner_orders
WHERE distance IS NOT NULL OR duration IS NOT NULL
GROUP BY order_id,runner_id;


-- 7 What is the successful delivery percentage for each runner?
SELECT 
    runner_id,
    CONCAT((ROUND((((((COUNT(*) FILTER (WHERE status_b = 'No Cancellation'))::NUMERIC)/COUNT(*)::NUMERIC)*100)),0)),'%') AS successful_delivery_percent
FROM
(SELECT runner_id,cancellation,order_id,
(CASE WHEN cancellation = 'No Cancellation' THEN 'No Cancellation'
    ELSE 'Cancellation'
    END) AS status_b
FROM pizza_runner.runner_orders)
GROUP BY runner_id;