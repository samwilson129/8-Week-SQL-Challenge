use dannys_diner;

show tables from dannys_diner;
select * from members;
select * from menu;
select * from sales;

-- 1) What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(m.price) as total_amount from menu m join sales s on s.product_id=m.product_id group by s.customer_id;

-- 2) How many days has each customer visited the restaurant?
select s.customer_id,count(distinct s.order_date) as days_visited from sales s group by s.customer_id;

-- 3) What was the first item from the menu purchased by each customer?
with order_sales_cte as (select s.customer_id,s.order_date,m.product_name,dense_rank()over(partition by s.customer_id order by s.order_date ) as dr from sales s join menu m on s.product_id=m.product_id)
select customer_id,product_name from order_sales_cte where dr=1 group by customer_id,product_name;

-- 4) What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name,count(s.order_date) as times_ordered from sales s join menu m on s.product_id=m.product_id group by m.product_name order by count(order_date) desc limit 1;

-- 5) Which item was the most popular for each customer?
with order_sales_cte as (select s.customer_id,m.product_name,count(s.product_id) as order_count, dense_rank()over( partition by s.customer_id order by count(*)desc) as dr from sales s join menu m on s.product_id=m.product_id group by s.customer_id,m.product_name)
select customer_id,product_name,order_count from order_sales_cte where dr=1;

-- 6) Which item was purchased first by the customer after they became a member?
with order_sales_cte as (select s.customer_id as id,s.order_date as order_date,m.product_name as product_name, dense_rank()over(partition by s.customer_id order by order_date) as dr from sales s join members me join menu m on s.product_id=m.product_id and s.customer_id=me.customer_id and s.order_date>me.join_date)
select id,product_name from order_sales_cte where dr=1;

-- 7) Which item was purchased just before the customer became a member?
with order_sales_cte as (select s.customer_id as id,s.order_date as order_date,m.product_name as product_name, dense_rank()over(partition by s.customer_id order by order_date desc) as dr from sales s join members me join menu m on s.product_id=m.product_id and s.customer_id=me.customer_id and s.order_date<me.join_date)
select id,product_name from order_sales_cte where dr=1;

-- 8) What is the total items and amount spent for each member before they became a member?
select s.customer_id,count(distinct s.product_id) as total_items,sum(m.price) as total_amount from sales s join menu m join members me on s.product_id=m.product_id and s.customer_id=me.customer_id and s.order_date<me.join_date group by s.customer_id;

-- 9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id,sum(case when m.product_name='sushi' then m.price*20 else m.price*10 end) as points from sales s join menu m on s.product_id=m.product_id group by s.customer_id; 

-- 10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select s.customer_id,sum(case when s.order_date-me.join_date<7 or m.product_name='sushi' then m.price*20 else m.price*10 end) as points from sales s join menu m join members me on s.customer_id=me.customer_id and s.product_id=m.product_id and s.order_date<='2021-01-31' and s.order_date>=me.join_date group by s.customer_id;

-- Bonus Questions
-- 11) Join All The Things
select s.customer_id,s.order_date,m.product_name,m.price,case when me.join_date<=s.order_date then'Y' else 'N' end as member from sales s left join members me on s.customer_id=me.customer_id  join menu m on s.product_id=m.product_id order by customer_id,order_date asc ,price desc;

-- 12) Rank All The Things
with customer_orders_cte as (select s.customer_id,s.order_date,m.product_name,m.price,case when me.join_date<=s.order_date then'Y' else 'N' end as member from sales s left join members me on s.customer_id=me.customer_id  join menu m on s.product_id=m.product_id order by customer_id,order_date asc ,price desc)
select customer_id, order_date,product_name,price,member,case when member='y' then dense_rank()over(partition by customer_id,member order by order_date) else null end as ranking from customer_orders_cte;

