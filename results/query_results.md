# Query Results

Verified by running the full flow (01 -> 02 -> 03) in SQLite.
Total clean revenue across all categories: **$531.58**

## Cleaning audit

| Check | Rows |
|---|---|
| Raw plants | 12 |
| Clean plants | 10 |
| Raw customers | 8 |
| Clean customers | 7 |
| Raw order lines | 22 |
| Clean orders | 18 |
| Rejected order lines | 3 |

Rejected lines, kept in `data_quality_issues` with reasons:

| Order | Problem |
|---|---|
| 109 | unit price missing |
| 120 | quantity is zero |
| 121 | quantity missing |

## Question 1: Revenue by category

| Category | Orders | Units sold | Revenue |
|---|---|---|---|
| Tropical | 6 | 8 | $210.95 |
| Succulent | 6 | 18 | $169.63 |
| Vine | 4 | 8 | $97.00 |
| Fern | 2 | 3 | $54.00 |

## Question 2: Top 5 customers by total spent

| Customer | City | Orders | Total spent |
|---|---|---|---|
| Ada Green | Austin | 3 | $135.92 |
| Priya Nair | Seattle | 4 | $108.94 |
| Tom Becker | Chicago | 3 | $84.50 |
| June Park | Portland | 3 | $80.24 |
| Omar Haddad | Denver | 2 | $72.50 |

## Question 3a: Plants that have never sold

| Plant | Category | Stock on hand | Price |
|---|---|---|---|
| Peace Lily | Flowering | 12 | (missing) |

## Question 3b: Best seller by units

| Plant | Units sold | Revenue |
|---|---|---|
| Echeveria | 12 | $107.88 |
