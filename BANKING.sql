select top 100 * from [dbo].[transactions]
select top 100 * from users
select top 100 * from banking_cards
select top 100 * from codes

--Q1: 	What is the total number of card transactions made by Xóm Bank in 2023?
select count(*)
from [dbo].[transactions]
where date >= '2023-01-01' and date <= '2023-12-31'

--Q2: Which are the top 5 merchant cities by transaction volume, and what is the total transaction amount in each city?	
select 
	top 5
	merchant_city
	, count(*) as total_transaction
	, SUM(amount) as total_amount
from [dbo].[transactions]
where merchant_city <> 'ONLINE'
group by merchant_city
order by count(*)desc

--Q3: 	What is the customer distribution across five credit score categories: 
	-- Poor (below 580), Fair (580–669), Good (670–739), Very Good (740–799), and Excellent (800 or above
select 
	case
	when credit_score >= 800 then 'excellent'
	when credit_score <= 799 and credit_score >= 740 then 'very good'
	when credit_score <= 739 and credit_score >= 670 then 'good'
	when credit_score <= 669 and credit_score >= 580 then 'fair'
	else 'poor'
	end as "distribution"
	, count(*) as total_customer
	, cast(count(*) *100.0/ sum(count(*)) over () as decimal(5,2)) as pct_of_total
from users
group by 
	case
	when credit_score >= 800 then 'excellent'
	when credit_score <= 799 and credit_score >= 740 then 'very good'
	when credit_score <= 739 and credit_score >= 670 then 'good'
	when credit_score <= 669 and credit_score >= 580 then 'fair'
	else 'poor'
	end
order by pct_of_total desc

--Q4: 	What is the number of cards by brand (Visa, Mastercard, Amex, and Discover), 
	-- and what percentage does each brand represent of the total card portfolio?
select 
	card_brand
	, count(*) as "total"
	,cast(count(*) *100.0/ sum(count(*)) over () as decimal(5,2)) as pct
from banking_cards
group by card_brand
order by pct desc

--Q5: What is the percentage of failed transactions out of total transactions, and what is the breakdown by failure type?
select distinct
	errors
	, COUNT(errors)*100.0/sum(count(*)) over () as "fail transaction"
	, count(*) as "total_failed"
from [dbo].[transactions]
where errors != 'Success'
group by errors
order by "fail transaction"

select 
	top 10
	t.client_id,
	max (u.gender),
	(YEAR(t.date)) as Year,
	(MONTH(t.date)) as Month,
	SUM(t.amount) as total_amount,
	max (u.yearly_income) as yearly_income
from transactions t
join users u on t.client_id = u.id
group by t.client_id, (YEAR(t.date)), (MONTH(t.date))
order by total_amount desc, t.client_id 

--Q6: Who are the top 10 customers with the highest spending in any given month, based on their total spending within that month? 
	-- What are their gender and annual income profiles?
select 
	top 10
	t.client_id,
	max (u.gender),
	(YEAR(t.date)) as Year,
	(MONTH(t.date)) as Month,
	SUM(t.amount) as total_amount,
	max (u.yearly_income) as yearly_income
from transactions t
join users u on t.client_id = u.id
where t.amount > 0
group by t.client_id, (YEAR(t.date)), (MONTH(t.date))
order by total_amount desc

--Q7: 	Which are the top 10 merchant categories by total customer spending, based only on successful transactions and excluding refunds?
select 
	top 10
	c.description
	, sum(t.amount)
	, COUNT(DISTINCT t.client_id)
from transactions t
join codes c
	on t.mcc = c.mcc_id
where t.errors = 'Success' and t.amount > 0
group by c.description
 order by sum(t.amount) desc

 --Q8:  What is the credit card utilization ratio for each card over the last 30 days, calculated as total spending divided by total credit limit? 
	-- Only credit cards are included, excluding debit and prepaid cards
	SELECT 
    t.card_id,
    c.client_id,
    c.credit_limit,
    ROUND(SUM(t.amount), 2) AS spend_last_30_days,
    ROUND(SUM(t.amount) * 1.0 / NULLIF(c.credit_limit, 0), 4) AS utilization_ratio,
    CONCAT(ROUND((SUM(t.amount) * 100.0) / NULLIF(c.credit_limit, 0), 2), '%') AS utilization_pct
FROM dbo.transactions t
INNER JOIN dbo.banking_cards c 
    ON t.card_id = c.id
WHERE c.card_type = 'Credit'
  AND t.errors = 'Success'
  AND t.amount > 0
  AND t.date >= DATEADD(DAY, -30, (SELECT MAX(date) FROM dbo.transactions))
GROUP BY 
    t.card_id,
    c.client_id,
    c.credit_limit
ORDER BY 
    utilization_ratio DESC;
--Q9:  Which cards have been open for more than two years but have never had any transactions?
select 
	c.id as card_id
	, c.card_brand
	, c.acct_open_date
from banking_cards c
left join transactions t
	on	c.id = t.card_id
where t.id is null
	and c.acct_open_date <= dateadd(YEAR, -2, (select MAX(date) from transactions))

--Q10: 	Which customers have conducted transactions across three or more different states on the same day? 
	-- For each case, identify the customer ID, transaction date, number of states, number of transactions, and total transaction amount.
create or alter view vw_multistate as
SELECT
    t.client_id,
    CAST(t.[date] AS DATE) AS transaction_date,
    COUNT(DISTINCT t.merchant_state) AS distinct_states,
    COUNT(*) AS total_transactions,
    CAST(SUM(t.amount) AS DECIMAL(14, 2)) AS total_amount
FROM dbo.transactions AS t
WHERE t.merchant_state IS NOT NULL
    AND t.merchant_state <> 'ONLINE'
    AND t.errors = 'Success'
    AND t.amount > 0
GROUP BY
    t.client_id,
    CAST(t.[date] AS DATE)
HAVING COUNT(DISTINCT t.merchant_state) >= 3;

--Q11: 	What is each customer's monthly spending and cumulative spending up to each month over the most recent 24 months?
with consumtion as (
select 
	client_id
	, sum(amount) as "tổng chi tiêu"
	, DATEFROMPARTS(YEAR(date), MONTH(date), 1) AS month_start
from transactions
where amount > 0 
	and errors = 'Success'
	and date >= DATEADD(MONTH, -24, (select MAX(date) from transactions))
group by client_id, DATEFROMPARTS(YEAR(date), MONTH(date), 1)
)
select 
	client_id
	, [tổng chi tiêu]
	, sum("tổng chi tiêu") OVER (partition by client_id ORDER BY month_start asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS tong_tich_luy
	, month_start
from consumtion c

--Q12:  Which customers have gaps of more than 30 days between consecutive transactions, potentially indicating churn? 
	-- For each customer, calculate the longest gap between consecutive transactions.
create or alter view vw_churn as
WITH customer_dates AS (
    SELECT DISTINCT
        client_id,
        CAST([date] AS DATE) AS trans_date
    FROM dbo.transactions
    WHERE errors = 'Success'
        AND amount > 0
),
trans_gaps AS (
    SELECT
        client_id,
        trans_date,
        LAG(trans_date) OVER (
            PARTITION BY client_id
            ORDER BY trans_date
        ) AS prev_trans_date,
        ROW_NUMBER() OVER (
            PARTITION BY client_id
            ORDER BY trans_date DESC
        ) AS rn
    FROM customer_dates
),
customer_summary AS (
    SELECT
        client_id,
        MAX(trans_date) AS latest_trans,
        MAX(
            CASE WHEN rn = 1
                THEN prev_trans_date
            END
        ) AS prev_trans,
        MAX(
            CASE WHEN rn = 1
                THEN DATEDIFF(DAY, prev_trans_date, trans_date)
            END
        ) AS latest_gap_days,
        MAX(
            DATEDIFF(DAY, prev_trans_date, trans_date)
        ) AS max_gap_days
    FROM trans_gaps
    GROUP BY client_id
),
data_cutoff AS (
    SELECT CAST(MAX([date]) AS DATE) AS data_as_of
    FROM dbo.transactions
)
SELECT
    s.client_id,
    s.latest_trans,
    s.prev_trans,
    s.latest_gap_days,
    s.max_gap_days,
    d.data_as_of,
    DATEDIFF(
        DAY, s.latest_trans, d.data_as_of
    ) AS days_since_last_txn
FROM customer_summary AS s
CROSS JOIN data_cutoff AS d;

--Q13: Which transactions have unusually high amounts compared with other transactions within the same merchant category? 
	-- Flag transactions exceeding the 95th percentile (P95).
create view vw_fraud as 
with percentage as (
select 
	id,
	mcc,
	round(amount, 2) as amount,
	round(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY amount) OVER(PARTITION BY mcc), 2) AS median_amount,
    round(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY amount) OVER(PARTITION BY mcc), 2) AS p95_amount
from transactions
where amount > 0
	and errors = 'Success'
)
select
	id,
	mcc,
	c.description,
	amount,
	median_amount,
	p95_amount,
	case
		when amount > p95_amount then 'fraud alert'
		else 'normal'
		end as Flag,
	round((amount/median_amount), 2) as times_median
from percentage p
join codes c
	on p.mcc = c.mcc_id

--Q14: 	Do customers with higher credit scores spend more? 
	-- Divide customers into five groups based on credit score, and calculate the average monthly spending and average annual income for each group.

with trans as (
	select
		client_id 
		, round(sum(amount), 2) as "tổng giao dịch"
		, round((sum(amount) / COUNT (distinct FORMAT(date, 'yyyy-MM'))), 2) as "chi tiêu tháng"
	from transactions
	where errors = 'Success' AND amount > 0
	group by client_id
),
full_table as (
	SELECT
        u.id AS client_id,
        ISNULL(t.[tổng giao dịch], 0) AS [tổng giao dịch],
        ISNULL(t.[chi tiêu tháng], 0) AS [chi tiêu tháng],
        u.yearly_income,
        u.credit_score,
        NTILE(5) OVER (ORDER BY u.credit_score DESC) AS rank
    FROM dbo.users u
    LEFT JOIN trans t
        ON u.id = t.client_id
)
select
	rank
	, count(client_id) as "tổng khách"
	, max(credit_score) as highest_score
	, min(credit_score) as lowest_score
	, round(avg([chi tiêu tháng]), 2) as avg_month
	, round(avg(yearly_income), 2) as avg_year
from full_table
group by rank
order by rank

--Q15: 	Which are the top 10 states and top 10 merchant categories by spending? 
	-- Create a state-by-category spending heatmap, where each matrix cell represents total spending.
create view vw_matrix as
WITH clean_trans AS (
    SELECT 
        t.merchant_state,
        c.description AS category_name,
        t.amount
    FROM dbo.transactions t
    INNER JOIN dbo.codes c 
        ON t.mcc = c.mcc_id
    WHERE t.errors = 'Success'
      AND t.amount > 0
      AND t.merchant_state IS NOT NULL 
      AND t.merchant_state <> 'ONLINE'
),
top_states AS (
    SELECT TOP 10 
        merchant_state,
        SUM(amount) AS state_spend
    FROM clean_trans
    GROUP BY merchant_state
    ORDER BY state_spend DESC
),
top_categories AS (
    SELECT TOP 10 
        category_name,
        SUM(amount) AS cat_spend
    FROM clean_trans
    GROUP BY category_name
    ORDER BY cat_spend DESC
)
SELECT 
    ct.merchant_state,
    ct.category_name,
    CAST(SUM(ct.amount) AS DECIMAL(14, 2)) AS total_amount
FROM clean_trans ct
INNER JOIN top_states s 
    ON ct.merchant_state = s.merchant_state
INNER JOIN top_categories c 
    ON ct.category_name = c.category_name
GROUP BY 
    ct.merchant_state,
    ct.category_name
