
-- CASE STUDY 1 QUESTIONS AND SOLUTIONS

-- ========================================================================================

-- QUESTION 1
-- What is the total amount each customer spent at the restaurant?

SET search_path = dannys_dinner;

with diner AS (
    SELECT s.customer_id,n.product_name,s.order_date,s.product_id,n.price
    from dannys_dinner.sales s
    join dannys_dinner.menu n
    on n.product_id = s.product_id
    ) SELECT customer_id,sum(price) from diner
    GROUP BY customer_id
    ORDER BY sum(price);

-- ==========================================================================================

-- QUESTION 2
--How many days has each customer visited the restaurant?


with diner AS (
    SELECT s.customer_id,n.product_name,s.order_date,s.product_id,n.price
    from dannys_dinner.sales s
    join dannys_dinner.menu n
    on n.product_id = s.product_id
    )SELECT customer_id,COUNT(DISTINCT(order_date)) from diner
    GROUP BY customer_id;


-- ============================================================================================

-- QUESTION 3
-- What was the first item from the menu purchased by each customer?


with diner AS (
    SELECT s.customer_id,n.product_name,s.order_date,s.product_id,n.price
    from dannys_dinner.sales s
    join dannys_dinner.menu n
    on n.product_id = s.product_id
    ) SELECT * FROM (SELECT customer_id,product_name,order_date,
    row_number() over(PARTITION BY customer_id ORDER BY order_date) as ranks
    from diner)
    WHERE ranks = 1;



/* 
==================================================================================================
-- QUESTION 4

What is the most purchased item on the menu and how many
times was it purchased by all customers?

 */


 with diner AS (
    SELECT s.customer_id,
    n.product_name,s.order_date,s.product_id,n.price
    FROM dannys_dinner.sales s
    JOIN dannys_dinner.menu n
    ON n.product_id = s.product_id
    ) SELECT product_name AS most_purchased,
    count(product_name) AS times_purchased FROM diner
    GROUP BY product_name
    ORDER BY times_purchased DESC
    LIMIT 1;


-- ===============================================================================================

-- QUESTION 5

--5 Which item was the most popular for each customer?
-- when ties have been eliminated.

WITH filtered_data AS (
    SELECT
        s.customer_id,
        n.product_name,
        s.order_date,
        s.product_id,n.price
    FROM dannys_dinner.sales s
    JOIN dannys_dinner.menu n
    ON n.product_id = s.product_id
    ),ranked_item As (SELECT 
        customer_id AS customers,
        product_name,
        count(product_name) AS order_count,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY count(product_name) DESC) AS ranked
    FROM filtered_data
    GROUP BY customer_id,product_name)
    SELECT customers,product_name,order_count
    FROM ranked_item
    WHERE ranked = 1;

--=======================================================================================================
-- QUETION 5

--5 Which item was the most popular for each customer?
-- when ties have not eliminated.



with dinner AS (
SELECT s.customer_id,n.product_name,s.order_date,s.product_id,n.price
FROM dannys_dinner.sales s
JOIN dannys_dinner.menu n
ON n.product_id = s.product_id
    ),ranked_item As (SELECT customer_id AS customers,
    product_name,
    count(product_name) AS order_count,
    RANK() OVER(PARTITION BY customer_id ORDER BY count(product_name) DESC) AS ranked
    FROM dinner
    GROUP BY customer_id,product_name)
    SELECT customers,product_name,order_count
    FROM ranked_item
    WHERE ranked = 1;



--====================================================================================================
-- QUESTION 6

-- Which item was purchased first by the customer after they became a member?


WITH orders_after_membership AS (
SELECT s.customer_id,m.join_date,n.product_name,s.order_date,s.product_id,n.price
FROM dannys_dinner.sales s
LEFT JOIN dannys_dinner.members m
ON m.customer_id = s.customer_id
JOIN dannys_dinner.menu n
ON n.product_id = s.product_id
),order_after_membership_ranking AS(
    SELECT 
    customer_id,
    product_name,
    join_date,
    order_date,
    price,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date::DATE) AS ranked
    FROM orders_after_membership
    WHERE join_date::DATE <= order_date::DATE)
    SELECT
    customer_id,
    product_name,
    join_date,
    order_date
    FROM order_after_membership_ranking
    WHERE ranked = 1
    ;



-- ====================================================================================================

-- QUESTION 7

-- Which item was purchased just before the customer became a member?

WITH orders_after_membership AS (
SELECT s.customer_id,m.join_date,n.product_name,s.order_date,s.product_id,n.price
FROM dannys_dinner.sales s
LEFT JOIN dannys_dinner.members m
ON m.customer_id = s.customer_id
JOIN dannys_dinner.menu n
ON n.product_id = s.product_id
),order_after_membership_ranking AS(
    SELECT 
    customer_id,
    product_name,
    join_date,
    order_date,
    price,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date::DATE DESC) AS ranked
    FROM orders_after_membership
    WHERE join_date::DATE > order_date::DATE)
    SELECT
    customer_id,
    product_name,
    join_date,
    order_date,
    (join_date::DATE -order_date::DATE) AS Days_difference
    FROM order_after_membership_ranking
    WHERE ranked = 1;


-- ===================================================================================================

/*
-QUESTION 8
-What is the total items and amount spent for each member before they became a member?
*/

WITH all_orders_and_prices AS (
SELECT 
    s.customer_id,
    m.join_date,
    n.product_name,
    s.order_date,
    s.product_id,
    n.price
FROM dannys_dinner.sales s
LEFT JOIN dannys_dinner.members m
ON m.customer_id = s.customer_id
JOIN dannys_dinner.menu n
ON n.product_id = s.product_id)
    SELECT
    customer_id,
    COUNT(product_name) total_orders,
    SUM(price) total_Price
    FROM all_orders_and_prices
    WHERE join_date > order_date OR join_date IS NULL 
    GROUP BY customer_id
    ORDER BY total_orders,total_Price ASC;


/*
=====================================================================================================
- QUESTION 9
If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
how many points would each customer have?

=======================================================================================================
*/


WITH all_orders_and_prices AS (
SELECT 
    s.customer_id,
    m.join_date,
    n.product_name,
    s.order_date,
    s.product_id,
    n.price,
    (CASE WHEN n.product_name != 'sushi' THEN n.price*10 
        ELSE n.price*10*2 
    End) AS points
FROM dannys_dinner.sales s
LEFT JOIN dannys_dinner.members m
ON m.customer_id = s.customer_id
JOIN dannys_dinner.menu n
ON n.product_id = s.product_id)
    SELECT
    customer_id,
    SUM(points) total_points
    FROM all_orders_and_prices
    GROUP BY customer_id
    ORDER BY total_points ASC




/*
============================================================================================================
- QUESTION 10
In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi how many points do customer A and B have at the end of January?

=============================================================================================================
*/



WITH points_category_table AS (
SELECT 
    s.customer_id,
    m.join_date,
    n.product_name,
    s.order_date,
    s.product_id,
    n.price,
    (CASE WHEN m.join_date <= s.order_date AND s.order_date -  m.join_date <= 6 THEN 'valid'
        ELSE 'invalid'
    END) week_one_points
FROM dannys_dinner.sales s
LEFT JOIN dannys_dinner.members m
ON m.customer_id = s.customer_id
JOIN dannys_dinner.menu n
ON n.product_id = s.product_id),total_points_table AS
    (SELECT customer_id,
    (CASE WHEN product_name != 'sushi'AND week_one_points = 'invalid' THEN price*10 
        WHEN product_name != 'sushi' AND week_one_points = 'valid' THEN price*10*2
        WHEN product_name = 'sushi' THEN price*10*2
    END) points
    FROM points_category_table
    WHERE customer_id != 'C'
    ORDER BY points)
        SELECT customer_id,SUM(points) FROM total_points_table
        GROUP BY customer_id;


-- ===========================================================================================
-- BONUS QUESTION 1
-- Join All The Things

-- ===========================================================================================

CREATE OR REPLACE VIEW dannys_dinner.all_data AS
(
    SELECT 
        s.customer_id,
        m.join_date,
        n.product_name,
        s.order_date,
        n.price,
        (CASE WHEN  m.join_date <= s.order_date THEN 'Y'
            ELSE 'N'
        END) AS member
    FROM dannys_dinner.sales s
    LEFT JOIN dannys_dinner.members m ON m.customer_id = s.customer_id
    JOIN dannys_dinner.menu n ON n.product_id = s.product_id
);


-- show view with all items
SELECT * FROM dannys_dinner.all_data
ORDER BY customer_id, order_date;



--===============================================================================================
-- BONUS QUESTION 2
--Rank All The Things

CREATE VIEW dannys_dinner.ranked_data AS 
(
WITH main AS (
    SELECT 
        s.customer_id,
        m.join_date,
        n.product_name,
        s.order_date,
        n.price,
        (CASE 
            WHEN m.join_date <= s.order_date THEN 'Y'
            ELSE 'N'
        END) AS member
    FROM dannys_dinner.sales s
    LEFT JOIN dannys_dinner.members m ON m.customer_id = s.customer_id
    JOIN dannys_dinner.menu n ON n.product_id = s.product_id
)
SELECT 
    *, 
    (CASE 
        WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
        ELSE NULL
     END) AS ranking
FROM main
);


-- show the ranked view

SELECT * FROM dannys_dinner.ranked_data;


-- ============================THE END OF CASE STUDY 1 DANNY'S DINER================================================