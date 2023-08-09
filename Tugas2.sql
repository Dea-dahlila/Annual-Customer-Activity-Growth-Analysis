--MAU (Monthly Active User) per yearr
WITH mau AS(
SELECT year, round(AVG(mau), 2) AS avg_mau
FROM(
	SELECT 	date_part('year', o.order_purchase_timestamp) AS year,
			date_part ('month', o.order_purchase_timestamp) AS month,
			count(distinct c.customer_unique_id) AS mau
	FROM 	orders_dataset AS o
	JOIN	customers_dataset AS c ON o.customer_id = c.customer_id
	GROUP BY 1, 2
) subq
GROUP BY 1
ORDER BY 1 ASC
),
--new customer per year
new_customer AS(
SELECT 	date_part('year', first_order) AS year,
		COUNT(DISTINCT customer_unique_id) AS total_new_customer
FROM(
	SELECT 	c.customer_unique_id,
			min(o.order_purchase_timestamp) AS first_order
	FROM 	orders_dataset AS o
	JOIN	customers_dataset AS c ON o.customer_id = c.customer_id
	GROUP BY 1
) subq
GROUP BY 1
ORDER BY 1 ASC
),
--repeat order customer per year
repeat AS(
SELECT 	year,
		COUNT(customer) AS total_repeat_customer
FROM(
	SELECT 	c.customer_unique_id, 
			COUNT(1) AS customer,
			date_part('year', o.order_purchase_timestamp) AS year
	FROM 	orders_dataset AS o
	JOIN	customers_dataset AS c ON o.customer_id = c.customer_id
	GROUP BY 1, 3
	HAVING COUNT (1) > 1
) subq
GROUP BY 1
ORDER BY 1 ASC
),
--average of order frequency per year
avg_freq AS(
SELECT 	year,
		ROUND(AVG(total_order), 3) AS avg_total_order
FROM(
	SELECT  c.customer_unique_id, 
			date_part('year', o.order_purchase_timestamp) AS year, 
			COUNT(1) AS total_order
	FROM 	orders_dataset AS o
	JOIN	customers_dataset AS c ON o.customer_id = c.customer_id
	GROUP BY 1, 2
) subsq
GROUP BY 1
ORDER BY 1 ASC
)
--combine the new metrics to be one table
SELECT m.year, m.avg_mau, nc.total_new_customer, r.total_repeat_customer, av.avg_total_order
FROM mau AS m
JOIN new_customer AS nc ON m.year = nc.year
JOIN repeat AS r ON m.year = r.year
JOIN avg_freq AS av ON m.year = av.year