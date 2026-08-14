-- Топ-10 продавцов по выручке с ранжированием (оконная функция RANK)
select seller_id, round(sum(price)::numeric, 2) as sum_seller,
	rank() over (order by sum(price) desc) as revenue_rank
from order_items 
group by order_items.seller_id 
order by sum(price) desc
limit 10

-- Динамика выручки по месяцам со скользящим средним за 3 месяца (CTE + оконная функция AVG)
with monthly as (
	select round(sum(price)::numeric, 2) as monthly_revenue, 
	date_trunc('month'::text, orders.order_purchase_timestamp::timestamp) as order_month
	from order_items 
	
	join orders 
	on order_items.order_id = orders.order_id 
	
	group by date_trunc('month'::text, orders.order_purchase_timestamp::timestamp)
),

moving_avg as(
	select order_month, monthly_revenue, 
	
	avg(monthly_revenue) over
		(order by order_month rows between 2 preceding and current row) as moving_avg_3m
		
	from monthly
)

select order_month, monthly_revenue, round(moving_avg_3m, 2) as moving_avg_3m
from moving_avg
order by order_month

-- Средняя оценка заказа в зависимости от задержки доставки (JOIN + CASE + агрегация)
select 
	case 
		when extract(day from order_delivered_customer_date::timestamp - order_estimated_delivery_date::timestamp) <= 0 
			then 'Вовремя или раньше'
		when extract(day from order_delivered_customer_date::timestamp - order_estimated_delivery_date::timestamp) between 1 and 3 
			then 'Опоздание 1-3 дня'
		when extract(day from order_delivered_customer_date::timestamp - order_estimated_delivery_date::timestamp) between 4 and 7
			then 'Опоздание 4-7 дней'
		when extract(day from order_delivered_customer_date::timestamp - order_estimated_delivery_date::timestamp) > 7
			then 'Опоздание более 7 дней'
	end
as group_delivery,
round(avg(order_reviews.review_score), 2) as avg_score

from orders
join order_reviews 
on orders.order_id = order_reviews.order_id
group by group_delivery

-- Топ-10 категорий товаров по выручке с долей от общей выручки (CTE + оконная функция SUM)
with category_revenue as (
	select products.product_category_name, 
	round(sum(order_items.price::decimal), 2) as revenue
	
	from order_items
	join products on order_items.product_id = products.product_id
	group by products.product_category_name
),

total_category_revenue as (
	select product_category_name, revenue, 
	SUM(revenue) OVER () as total_revenue
	
	from category_revenue
	)

select product_category_name, revenue,
round((revenue / total_revenue * 100), 2) as pct_of_total

from total_category_revenue

order by revenue desc
limit 10

-- RFM-сегментация клиентов (CTE + JOIN + EXTRACT + CASE)
with customer_orders as (
	select customers.customer_unique_id, orders.order_purchase_timestamp, 
		order_payments.payment_value 
		
	from order_payments
	join orders on 
		order_payments.order_id = orders.order_id 
	join customers on 
		orders.customer_id = customers.customer_id
),

rfm as (
	select customer_unique_id,
		extract (day from '2018-10-17'::timestamp - max(order_purchase_timestamp::timestamp)) as recency,
		sum(payment_value) as sum_purchase,
		count(order_purchase_timestamp) as count_purchase
		
	from customer_orders
	
	group by customer_unique_id
)

select customer_unique_id, 
	case 
		when recency <= 90 and sum_purchase >= 150
			then 'VIP (новые и ценные)'
		when recency <= 90 and sum_purchase < 150
			then 'Новые клиенты'
		when recency > 90 and sum_purchase >= 150
			then 'Ценные, но давно не покупали'
		else 'Обычные/спящие клиенты'	
	end
from rfm 
