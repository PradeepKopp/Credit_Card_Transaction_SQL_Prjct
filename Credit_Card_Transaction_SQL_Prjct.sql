select MIN(transaction_date), MAX(transaction_date)---10/2013 to 05/2015
from credit_card_transcations

select distinct card_type 
from credit_card_transcations
/*Silver
Signature
Gold
Platinum */

select distinct exp_type
from credit_card_transcations
/*Entertainment
Food
Bills
Fuel
Travel
Grocery*/

select distinct gender 
from credit_card_transcations ---F and M

select COUNT(distinct city)
from credit_card_transcations ----986 cities 


/*1- write a query to print top 5 cities with highest spends and
their percentage contribution of total credit card spends */
with cte as (
select top 5 city, SUM(amount) as Total_spend
from credit_card_transcations
group by city 
order by Total_spend desc), cte2 as(
select SUM(amount) as Total_amount
from credit_card_transcations), cte3 as (
select cte.*, cte2.Total_amount
from cte, cte2) 
select *, round((Total_spend*1.0/Total_amount)*100, 2) as percent_contribution
from cte3



/*2- write a query to print highest spend month and 
amount spent in that month for each card type */
with cte as (
select card_type, DATEPART(year, transaction_date) as yr, DATEPART(month, transaction_date) as mt,
SUM(amount) as Total_spend
from credit_card_transcations
group by card_type, DATEPART(year, transaction_date), DATEPART(month, transaction_date))
select * from (
select *, DENSE_RANK() over(partition by card_type order by Total_spend desc) as rn
from cte ) a  where rn = 1 

/*3- write a query to print the transaction details(all columns from the table) 
for each card type when it reaches a cumulative of 1000000 total spends
(We should have 4 rows in the o/p one for each card type) */


with cte as (
select *, SUM(amount) over(partition by card_type order by transaction_date,transaction_id) as cmt
from credit_card_transcations), cte1 as (
select *
from cte 
where cmt>=1000000)
select * from (
select *, RANK() over(partition by card_type order by cmt) as rn 
from cte1 )a where rn =1

--4- write a query to find city which had lowest percentage spend for gold card type

WITH cte AS (
    SELECT city, card_type, SUM(amount) AS sales 
    FROM credit_card_transcations
    GROUP BY city, card_type
  
), cte1 AS (
    SELECT *, SUM(sales) OVER (PARTITION BY city) AS city_sales
    FROM cte
)
SELECT *, (sales * 1.0 / city_sales) * 100 AS percent_contribution
FROM cte1
WHERE card_type = 'Gold'
ORDER BY percent_contribution;


/*5- write a query to print 3 columns:  city, highest_expense_type , 
lowest_expense_type (example format : Delhi , bills, Fuel)*/


select * from credit_card_transcations

with tb as (select city, exp_type, SUM(amount) as sales 
from credit_card_transcations
group by city, exp_type
),
 cte as (
select city,exp_type, DENSE_RANK() over( partition by city order by sales desc) as rn,
DENSE_RANK() over(partition by city order by sales asc) as lnk
from tb ) 
select city,
max(case when rn=1 then exp_type end) as highest_expense_type, 
max(case when lnk=1 then exp_type end) as Lowest_expense_type 
from cte 
group by city 


/*6- write a query to find percentage contribution of spends 
by females for each expense type */

select * from credit_card_transcations

with cte as(
select exp_type,gender, SUM(amount) as sales 
from credit_card_transcations
group by exp_type, gender), cte1 as(
select *, SUM(sales) over(partition by exp_type) as Ttl_sales 
from cte )
select *, (sales*1.0/Ttl_sales)*100 as Percent_contribution 
from cte1
where gender = 'F'


--7- which card and expense type combination saw highest month over month growth in Jan-2014

select * from credit_card_transcations

with cte as (
select card_type, exp_type, DATEPART(MONTH, transaction_date) as mth, datepart(year, transaction_date) as yr ,SUM(amount) as sales
from credit_card_transcations
group by card_type, exp_type,  DATEPART(MONTH, transaction_date), datepart(year, transaction_date)), cte1 as

(select *, LAG(sales,1) over(partition by card_type, exp_type order by yr,mth )as previous_sales from cte )
select *, (sales-previous_sales)*1.0/previous_sales as mom
from cte1
where mth='1' and yr='2014'
order by mom desc


--8- during weekends which city has highest total spend to total no of transcations ratio

select * from credit_card_transcations


 with cte as (
SELECT *, 
	DATEname(WEEKDAY, transaction_date) as weekname
FROM credit_card_transcations)
select city, SUM(amount)/ COUNT(transaction_id)  as rt
from cte 
where weekname in ('Sunday', 'Saturday')
group by city
order by rt desc


/*9- which city took least number of days to reach its 500th transaction 
after the first transaction in that city */


WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date) AS rnk
    FROM credit_card_transcations
)
SELECT city,
    DATEDIFF(DAY, 
        MIN(CASE WHEN rnk = 1 THEN transaction_date END),
        MIN(CASE WHEN rnk = 500 THEN transaction_date END)) as dt
FROM cte
GROUP BY city
HAVING DATEDIFF(DAY, 
        MIN(CASE WHEN rnk = 1 THEN transaction_date END),
        MIN(CASE WHEN rnk = 500 THEN transaction_date END)) IS NOT NULL
ORDER BY dt;

with cte as (
select *, ROW_NUMBER() over(partition by city order by transaction_date) as rn
from credit_card_transcations) 
select city, datediff(day, MIN(transaction_date), MAX(transaction_date)) as Ttl_days
from cte
where rn= 1 or rn=500
group by city 
having COUNT(*) =2
order by Ttl_days