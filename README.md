# Messy Data, Clean Answers

A small SQL project about the part of data work nobody puts on a poster: taking a genuinely messy little dataset and making it trustworthy enough to answer questions with.

The dataset is a fictional plant shop's plants, customers, and orders, stored exactly the way messy real-world exports arrive. All values land as text. Names have stray spaces and inconsistent capitalization, one plant is listed twice under two spellings, one customer exists as two different people-rows, prices sometimes carry a dollar sign, dates show up in four different formats, and a few order lines are quietly unusable.

## Skills used

SQL: `JOIN` (inner and left), `GROUP BY` with `SUM` / `COUNT`, `CASE` mapping, string functions (`TRIM`, `LOWER`, `UPPER`, `SUBSTR`, `REPLACE`), type casting, `DISTINCT` deduplication, subqueries and CTEs, and data-quality auditing.

## Files

| File | What it does |
|---|---|
| `data/raw_plants.csv`, `data/raw_customers.csv`, `data/raw_orders.csv` | The raw data, as it "arrived" |
| `sql/01_create_raw_tables.sql` | Creates and loads the raw tables |
| `sql/02_clean_data.sql` | Builds `plants_clean`, `customers_clean`, `orders_clean`, ID maps, and `data_quality_issues` |
| `sql/03_analysis_queries.sql` | The three business questions |
| `results/query_results.md` | The verified outputs |

## How to run

Any SQLite 3 database works. From this folder:

```bash
sqlite3 plantshop.db < sql/01_create_raw_tables.sql
sqlite3 plantshop.db < sql/02_clean_data.sql
sqlite3 plantshop.db < sql/03_analysis_queries.sql
```

The SQL is standard and ports to MySQL with only minor changes (for example, string concatenation syntax).

## Cleaning rules

- Trim whitespace and normalize capitalization on names, emails, and categories; each category gets one canonical spelling.
- Prices: strip `$`, cast to a real number. A price that is missing at the source stays missing. Cleaning never invents data.
- Duplicate plants (same normalized name) merge into one row, with stock added together.
- Duplicate customers are detected by lowercased email and merged; every order is re-pointed to the surviving customer ID through a mapping table. The one customer with no email on file is kept as her own row.
- Order dates are standardized to ISO format (`YYYY-MM-DD`) from all four source formats.
- Exact duplicate order lines are removed.
- Order lines with a missing price, a missing quantity, or a quantity of zero are **not** silently dropped. They are set aside in `data_quality_issues` with the reason, so the rejection itself is auditable.

## The three questions, and what the data said

**1. Which category brings in the most revenue?**
Tropical, at $210.95. Succulents sell far more units (18 vs. 8) but at lower prices, so they land second at $169.63. Total clean revenue: $531.58.

**2. Who are the top 5 customers?**
Ada Green leads at $135.92 across 3 orders. The interesting row is second place: Priya Nair, $108.94 across 4 orders. In the raw data Priya existed as two separate customers (IDs 3 and 5, same email in different cases). Uncleaned, she would have looked like two mid-tier customers and the shop would never have known she was its second-best one.

**3. Which plants have never sold, and what is the best seller?**
The Peace Lily has never sold, and the data hints at why: it is also the only plant with **no price at all** in the source data. Twelve in stock, no price, no sales. The best seller by units is the Echeveria: 12 units, $107.88.

## What I would do next

- Add a monthly revenue trend once the dataset covers more than one month.
- Flag low-stock best sellers automatically (the String of Pearls sits at 0 stock).
- Load the clean tables into a small dashboard or spreadsheet for the shop owner.

---

Built by Bri Hatter as a portfolio project. Dataset is fictional; the mess is, unfortunately, realistic.
