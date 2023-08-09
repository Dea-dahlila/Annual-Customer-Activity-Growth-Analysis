WITH total_revenues AS(
SELECT date_part('year', order_purchase_timestamp) AS year,
       ROUND(SUM(revenue)) AS total_revenue
FROM(
	SELECT 	order_id, 
			SUM(price + freight_value) AS revenue
	FROM 	order_item_dataset
    GROUP BY 1
) subsq
JOIN orders_dataset o
ON subsq.order_id = o.order_id
WHERE order_status = 'delivered'
GROUP BY 1
ORDER BY 1 ASC
),
--
canceled_customers AS(
SELECT date_part('year', order_purchase_timestamp) AS year,
       SUM(cust) AS canceled_customer
FROM(
	SELECT 	order_id, 
			COUNT(*) AS cust
	FROM 	order_item_dataset
    GROUP BY 1
) subsq
JOIN orders_dataset o
ON subsq.order_id = o.order_id
WHERE order_status = 'canceled'
GROUP BY 1
ORDER BY 1 ASC
),
--
top_product AS(
SELECT year, product_category_name AS top_product_category, ROUND(total_revenue) AS top_product_revenue
FROM (SELECT year, p.product_category_name,
             SUM(t1.revenue) AS total_revenue,
             RANK() OVER (PARTITION BY year ORDER BY SUM(t1.revenue) DESC)
             AS value_rank
      FROM (SELECT order_id, date_part('year', order_purchase_timestamp) AS year
            FROM orders_dataset
            WHERE order_status = 'delivered') o
      JOIN (SELECT order_id, product_id,
                   SUM(price + freight_value)
                   AS revenue
            FROM order_item_dataset
            GROUP BY order_id, product_id) t1
      ON o.order_id = t1.order_id
	  JOIN product_datasets p
      ON t1.product_id = p.product_id
      GROUP BY year, p.product_category_name) t3
WHERE value_rank = 1
),
--
canceled_product AS(
SELECT year, product_category_name AS most_canceled_product, total_canceled_orders
FROM (SELECT year, p.product_category_name,
             SUM(t1.num_canceled_orders) AS total_canceled_orders,
             RANK() OVER (PARTITION BY year ORDER BY SUM(t1.num_canceled_orders) DESC)
             AS value_rank
      FROM (SELECT order_id, date_part('year', order_purchase_timestamp) AS year
            FROM orders_dataset
            WHERE order_status = 'canceled') o
      JOIN (SELECT order_id, product_id,
                   COUNT(order_id)
                   AS num_canceled_orders
            FROM order_item_dataset
            GROUP BY order_id, product_id) t1
      ON o.order_id = t1.order_id
      JOIN product_datasets p
      ON t1.product_id = p.product_id
      GROUP BY year, p.product_category_name) t3
WHERE value_rank = 1
)
SELECT tr.year, tr.total_revenue, cc.canceled_customer, tp.top_product_category, tp.top_product_revenue, cp.most_canceled_product, cp.total_canceled_orders
FROM total_revenues AS tr
JOIN canceled_customers AS cc ON tr.year = cc.year
JOIN top_product AS tp ON tr.year = tp.year
JOIN canceled_product AS cp ON tr.year = cp.year