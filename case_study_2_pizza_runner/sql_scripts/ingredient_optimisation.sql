-- 1. What are the standard ingredients for each pizza?
WITH cte AS
((SELECT i.pizza_id,n.pizza_name,t.topping_id,t.topping_name
FROM pizza_runner.pizza_toppings t
JOIN
(SELECT pizza_id,TRIM(string_to_table(toppings,',')) AS topping_id
FROM pizza_runner.pizza_recipes) AS i
ON t.topping_id = i.topping_id::NUMERIC
JOIN pizza_runner.pizza_names n
ON n.pizza_id = i.pizza_id))
SELECT pizza_name,STRING_AGG(topping_name,',') AS toppings_name
FROM cte
GROUP BY pizza_name


-- 2.What was the most commonly added extra?
SELECT topping_name,COUNT(*) as times_add_extra_requests
FROM
((SELECT *,
TRIM(string_to_table(co.exra,',')) AS toppings_extra 
FROM pizza_runner.customer_orders AS co) as c
JOIN pizza_runner.pizza_toppings t
ON t.topping_id = c.toppings_extra::INT)
WHERE toppings_extra::VARCHAR != 'None'
GROUP BY topping_name
ORDER BY times_add_extra_requests Desc
LIMIT 1
;


-- 3.What was the most common exclusion?

SELECT topping_name,COUNT(*) as times_add_exclusions_requests
FROM
((SELECT *,
TRIM(string_to_table(co.exclusions,',')) AS toppings_exclusions 
FROM pizza_runner.customer_orders AS co) as c
JOIN pizza_runner.pizza_toppings t
ON t.topping_id = c.toppings_exclusions::INT)
WHERE toppings_exclusions::VARCHAR != 'None'
GROUP BY topping_name
ORDER BY times_add_exclusions_requests Desc
LIMIT 1
;

-- 4 Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH cte as 
(SELECT *,
CASE WHEN pizza_id = 1 AND toppings_extra = 'None' AND toppings_exclusions = 'None' THEN 'Meat Lovers'
    WHEN pizza_id = 1 AND toppings_extra = 'None' AND toppings_exclusions = '3' THEN 'Meat Lovers - Exclude Beef'
    WHEN pizza_id = 1 AND toppings_extra = '1' AND toppings_exclusions = 'None' THEN 'Meat Lovers - Extra Bacon'
    WHEN pizza_id = 1 AND (toppings_extra::VARCHAR IN ('4','2','6') AND toppings_exclusions::VARCHAR IN ('5','1','6')) THEN 
'Meat Lovers - Exclude Cheese, BBQ, Mushrooms - Extra Chicken, Bacon,Mushrooms'
    WHEN pizza_id = 1 AND (toppings_extra IN ('9','6') OR toppings_exclusions IN ('4')) THEN 'Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers'
    WHEN pizza_id = 2 THEN 'Vegetarian'
END AS category
FROM
((SELECT *,
TRIM(string_to_table(co.exclusions,',')) AS toppings_exclusions,
TRIM(string_to_table(co.extras,',')) AS toppings_extra
FROM pizza_runner.customer_orders AS co)))
SELECT pizza_id,exclusions,extras,category
FROM cte
WHERE category IS NOT NULL
;

SELECT * FROM pizza_runner.pizza_toppings

-- 5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients

WITH cte AS (
    SELECT 
        i.pizza_id,
        n.pizza_name,
        t.topping_id,
        t.topping_name,
        c.order_id
    FROM pizza_runner.pizza_toppings t
    JOIN (
        SELECT 
            pizza_id,
            TRIM(string_to_table(toppings, ',')) AS topping_id
        FROM pizza_runner.pizza_recipes
    ) AS i ON t.topping_id = i.topping_id::NUMERIC
    JOIN pizza_runner.pizza_names n ON n.pizza_id = i.pizza_id
    JOIN pizza_runner.customer_orders AS c ON c.pizza_id = i.pizza_id
),

nestcte AS (
    SELECT 
        order_id,
        topping_name,
        COUNT(topping_name) OVER(PARTITION BY order_id, topping_name) AS ingcount
    FROM cte
),

nestedcte2 AS (
    SELECT 
        order_id,
        topping_name,
        CASE
            WHEN ingcount > 1 THEN ingcount || 'x ' || topping_name
            ELSE topping_name
        END AS ingredient
    FROM nestcte
)

SELECT 
    order_id,
    STRING_AGG(DISTINCT ingredient, ', ' ORDER BY ingredient ASC) AS ingredient_list_for_each_pizza_order
FROM nestedcte2
GROUP BY order_id;


-- 6.a What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH cte AS (
    SELECT 
        i.pizza_id,
        n.pizza_name,
        t.topping_id,
        t.topping_name,
        c.order_id,
        r.cancellation
    FROM pizza_runner.pizza_toppings t
    JOIN (
        SELECT 
            pizza_id,
            TRIM(string_to_table(toppings, ',')) AS topping_id
        FROM pizza_runner.pizza_recipes
    ) AS i ON t.topping_id = i.topping_id::NUMERIC
    JOIN pizza_runner.pizza_names n ON n.pizza_id = i.pizza_id
    JOIN pizza_runner.customer_orders AS c ON c.pizza_id = i.pizza_id
    JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
),
nestedcte2 AS
(SELECT 
    order_id,
    pizza_id,
    COUNT(topping_name) FILTER(WHERE cancellation = 'No Cancellation') AS number_ingredient_used,
    COUNT(order_id) FILTER(WHERE cancellation = 'No Cancellation') AS number_of_orders
FROM cte
GROUP BY pizza_id,order_id)
SELECT order_id,number_ingredient_used
FROM nestedcte2
WHERE number_ingredient_used > 0
ORDER BY number_of_orders DESC;

-- ========================================================


-- 6 b What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH cte AS (
    SELECT 
        i.pizza_id,
        n.pizza_name,
        t.topping_id,
        t.topping_name,
        c.order_id,
        r.cancellation
    FROM pizza_runner.pizza_toppings t
    JOIN (
        SELECT 
            pizza_id,
            TRIM(string_to_table(toppings, ',')) AS topping_id
        FROM pizza_runner.pizza_recipes
    ) AS i ON t.topping_id = i.topping_id::NUMERIC
    JOIN pizza_runner.pizza_names n ON n.pizza_id = i.pizza_id
    JOIN pizza_runner.customer_orders AS c ON c.pizza_id = i.pizza_id
    JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
),cte2 AS
(SELECT 
    topping_name,
    COUNT(topping_name) FILTER(WHERE cancellation = 'No Cancellation') AS number_ingredient_used
FROM cte
GROUP BY topping_name)
SELECT
    topping_name,
    number_ingredient_used
FROM cte2
ORDER BY number_ingredient_used DESC;






