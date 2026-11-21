# Xóm Bank: Card Portfolio Analytics (SQL Server + Power BI)

Analysis of card data from the **Xóm Dataset** banking schema: a US retail bank that also issues credit cards, serving 2,000+ individual customers with a diverse card portfolio (Visa, Mastercard, Amex, Discover) across Credit / Debit / Prepaid types. The project goes from raw data to a set of T-SQL business queries and a Power BI report, supporting the Board, Marketing, Cards/Closure, Risk/Fraud and Geographic teams.

## Dataset

Four CSV files loaded into SQL Server. Data period: 01/01/2022 – 31/10/2024.

| Table | Size | Contents |
|---|---|---|
| `transactions` | 157,224 rows | Card transactions (amount, channel, merchant, MCC, errors) |
| `users` | 2,000 customers | Income, credit score, debt, personal information |
| `banking_cards` | 6,146 cards | Brand, card type, credit limit, account open date |
| `codes` | 109 codes | Maps MCC codes to merchant category names |

## Repository Structure

```
.
├── BANKING.sql                                  # 15 business queries (Q1–Q15) and views
├── Banking.pbix                                 # Power BI report (6 pages)
├── README.md
├── Xom Bank - Card Portfolio Handover.pptx      # Executive handover presentation
├── banking_cards.csv
├── codes.csv
├── transactions.csv
└── users.csv
```

## SQL Queries (Q1–Q15)

The business questions cover: total transactions, top cities, credit score distribution, card brand mix, error rate, top spending customers, largest merchant categories, credit utilization, dormant cards, multi-state fraud signal, cumulative spend, churn, outlier detection by MCC, credit score vs spend correlation, and a state × category heatmap.

## Power BI Report

| Page | Main content |
|---|---|
| Overview | Transaction volume, top cities, error types, chip/swipe/online channels |
| Customer & Credit | Credit score distribution, top spenders, credit score vs spend correlation |
| Card Portfolio | Brand mix, credit limit utilization, dormant cards |
| Risk Signals & Customer Inactivity | Multi-state transactions in one day, gaps between transactions, churn status |
| Merchant & Geography | Largest merchant categories, outliers by MCC, state × category heatmap |
| Customer details | Monthly and cumulative spend per customer (drill-through) |

## Key Findings

**Overall performance**
- Valid spend is stable at about **$221K per month** in all three years. The downward line in 2024 is only because 2024 has 10 months of data.
- The top 10 merchant categories account for **57.56%** of spend. Service Stations is the largest (8.40%), followed by Money Transfer ($575.7K).
- Card mix by count: Mastercard 52.21%, Visa 37.85%, Amex 6.54%, Discover 3.40%. Amex is small but spends the most per active card (about $11.6K) and has the highest 30-day utilization (4.12%).

**Payments and errors**
- The transaction error rate is **1.74%**, and 64.4% of errors are *Insufficient Balance*, not system failures. Declined transactions for this reason total about $129.2K.
- Online payments have the highest error rate (2.50%), and 53.7% of online errors come from wrong card details.

**Customers and credit**
- Credit score is almost unrelated to spend (r = 0.007); income relates much more strongly (r = 0.47).
- Active credit cards use only **2.94%** of their limit in 30 days. This is spend over limit, not outstanding balance, so it is not a measure of repayment risk.

**Risk and churn**
- Churn is very low: 285 of 303 active customers (94.1%) transacted in the last 7 days, and only 3 have been silent for 30+ days.
- The multi-state rule flags 22 days ($8,877.63), about 7 cases per year, so each case can be verified manually.
- The 5.00% outlier rate is a result of the P95 threshold per MCC, not a fraud rate.

**Geography**
- Ranked by transaction count, Houston and North Hollywood lead. But North Hollywood has only 4 customers and Yorba Linda only 1, while Las Vegas has 117 customers with an average ticket of $89.40. Campaign locations should be chosen by unique customers, not by transaction count.

**Refunds**
- Refunds make up 11.1% of gross spend and are concentrated in two categories (Miscellaneous Food Stores and Service Stations). Net of refunds, Money Transfer becomes the largest category.

## Data Notes

- Only **303 of 2,000 customers** have transactions. The 5,250 dormant cards (85.42%) include 5,006 cards of customers with no transaction data and only 244 cards of active customers. Confirm the data scope before closing any cards.
- `Total Spend` is a **gross** figure: it counts only `amount > 0` and error-free transactions, and does not subtract refunds.
- The `expires` column is not reliable for judging dormant cards.

## How to Run

1. Create a SQL Server database and load the 4 CSV files into the tables `transactions`, `users`, `banking_cards` and `codes`.
2. Run the queries in `BANKING.sql` (including the creation of the views).
3. Open `Banking.pbix` in Power BI Desktop.
4. The model points to the server `DESKTOP-1KB4ADE\SQLEXPRESS02`. Change it to your own server in Transform data, then Refresh.

## Tech Stack

T-SQL (SQL Server) · Power BI (DAX)

## Credit

The data used in this project comes from: https://dataset.xomdata.com/datasets/schema/banking
