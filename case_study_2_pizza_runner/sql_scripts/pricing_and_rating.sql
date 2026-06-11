/* 
If a Meat Lovers pizza costs $12 and Vegetarian costs $10 
there were no charges for changes 
-how much money has Pizza Runner made so far if there are no delivery fees?
*/

WITH cte AS
(SELECT r.order_id,c.pizza_id,c.customer_id,r.cancellation,
    (CASE WHEN c.pizza_id = 1 THEN 12
            WHEN c.pizza_id =2 THEN 10
            END) AS price
FROM pizza_runner.customer_orders AS c
JOIN pizza_runner.runner_orders AS r
ON r.order_id=c.order_id)
SELECT
SUM(Price) FILTER(WHERE cancellation = 'No Cancellation') AS "total cost for both pizza_type"
FROM cte
;

/*2. What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 
*/

WITH cte AS
(SELECT 
r.order_id,
c.pizza_id,
c.customer_id,
r.cancellation,
c.extras,
ARRAY_LENGTH(ARRAY_REMOVE(STRING_TO_ARRAY(REGEXP_REPLACE(c.extras::TEXT, '\s+', '', 'g'), ','),'None'),1) AS extraa,
(CASE WHEN c.pizza_id = 1 THEN 12 WHEN c.pizza_id =2 THEN 10 END) AS price
FROM pizza_runner.customer_orders AS c
JOIN pizza_runner.runner_orders AS r
ON r.order_id=c.order_id)
SELECT SUM(extraa) FILTER(WHERE cancellation = 'No Cancellation') + SUM(price) FILTER(WHERE cancellation = 'No Cancellation') AS "total cost with additional $1 charge"
FROM cte;


/*The Pizza Runner team now wants to add an additional ratings system
that allows customers to rate their runner, how would you 
design an additional table for this new dataset - generate 
a schema for this new table and insert 
your own data for ratings for each successful customer order between 1 to 5.
*/


CREATE TABLE pizza_runner.runner_ratings (
    order_id INT,
    customer_id INT,
    pizza_id INT,
    runner_id INT,
    rating INT
);
INSERT INTO pizza_runner.runner_ratings 
    (order_id, customer_id, pizza_id, runner_id, rating)
VALUES
    (1, 101, 1, 1, 3),
    (2, 101, 1, 1, 3),
    (3, 102, 1, 1, 4),
    (3, 102, 2, 1, 4),
    (4, 103, 1, 2, 3),
    (4, 103, 2, 2, 2),
    (5, 104, 1, 3, 4),
    (7, 105, 2, 2, 3),
    (8, 102, 1, 2, 4),
    (10, 104, 1, 1, 5);

SELECT * FROM pizza_runner.runner_ratings;


/*
Using your newly generated table - 
can you join all of the information together to form a 
table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas
*/


SELECT 
    co.customer_id,
    co.order_id,
    ro.runner_id,
    rr.rating,
    co.order_time,
    ro.pickup_time::TIMESTAMP AS pickup_time,
    
    -- 1. Calculate time difference between order and pickup
    EXTRACT('MINUTES' FROM (ro.pickup_time::TIMESTAMP - co.order_time))AS time_between_order_and_pickup,
    
    -- 2. Clean and display delivery duration
    TRIM(REGEXP_REPLACE(ro.duration, '[a-zA-Z]+', '', 'g'))::NUMERIC AS delivery_duration_minutes,
    
    -- 3. Calculate average speed (Distance in km / (Duration in minutes / 60))
    ROUND(
        (TRIM(REGEXP_REPLACE(ro.distance, '[a-zA-Z]+', '', 'g'))::NUMERIC) / 
        ((TRIM(REGEXP_REPLACE(ro.duration, '[a-zA-Z]+', '', 'g'))::NUMERIC) / 60.0), 
        2
    ) AS average_speed_km_h,
    
    -- 4. Count total number of pizzas in the order
    COUNT(co.pizza_id) AS total_number_of_pizzas

FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
-- Left join ratings as some orders may not have been rated yet
LEFT JOIN pizza_runner.runner_ratings rr ON co.order_id = rr.order_id AND co.pizza_id = rr.pizza_id

-- Filter out cancelled orders to only include successful deliveries
WHERE ro.cancellation = 'No Cancellation'

GROUP BY 
    co.customer_id,
    co.order_id,
    ro.runner_id,
    rr.rating,
    co.order_time,
    ro.pickup_time,
    ro.duration,
    ro.distance
ORDER BY co.order_id;



/*
If a Meat Lovers pizza was $12 and Vegetarian $10 
fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
-how much money does Pizza Runner have left over after these deliveries?
*/

WITH cte AS
(SELECT 
    co.customer_id,
    co.order_id,
    ro.runner_id,
    rr.rating,
    co.order_time,
    co.pizza_id,
    ro.pickup_time::TIMESTAMP AS pickup_time,
    TRIM(REGEXP_REPLACE(ro.distance, '[a-zA-Z]+', '', 'g'))::NUMERIC AS delivery_duration_km,
    (CASE WHEN co.pizza_id = 1 THEN 12
        ELSE 10
        END) AS price
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id

LEFT JOIN pizza_runner.runner_ratings rr ON co.order_id = rr.order_id AND co.pizza_id = rr.pizza_id
WHERE ro.cancellation = 'No Cancellation')
SELECT SUM(price)-SUM((delivery_duration_km*0.3)) AS total_after_delivary_fee
FROM cte; 




INSERT INTO
  pizza_runner.pizza_names ("pizza_id", "pizza_name")
VALUES
  (3, 'Supreme');
INSERT INTO
  pizza_runner.pizza_recipes ("pizza_id", "toppings")
VALUES
  (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');


SELECT
  *
FROM
  pizza_runner.pizza_names AS n
  JOIN pizza_runner.pizza_recipes AS r ON n.pizza_id = r.pizza_id