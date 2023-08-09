WITH num_payment AS(
SELECT payment_type,
       COUNT(order_id) AS num_payments
FROM order_payments_dataset
GROUP BY payment_type
ORDER BY num_payments DESC
),
--
type_payment AS(
SELECT payment_type,
       SUM(CASE WHEN(date_part('year', order_purchase_timestamp)) = 2016 THEN 1 ELSE 0 END) AS year_2016,
       SUM(CASE WHEN(date_part('year', order_purchase_timestamp)) = 2017 THEN 1 ELSE 0 END) AS year_2017,
       SUM(CASE WHEN(date_part('year', order_purchase_timestamp)) = 2018 THEN 1 ELSE 0 END) AS year_2018
FROM order_payments_dataset AS op
JOIN orders_dataset o ON op.order_id = o.order_id 
GROUP BY 1
ORDER BY 4 DESC
)
SELECT 	np.payment_type, tp.year_2016, tp.year_2017, tp.year_2018
FROM num_payment AS np
JOIN type_payment AS tp ON np.payment_type = tp.payment_type