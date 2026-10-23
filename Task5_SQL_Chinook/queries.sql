-- Chinook SQL Analysis - Task 5 (Elevvo Data Analytics Internship)
-- Run on Chinook_Sqlite.sqlite (SQLite)

SELECT name FROM sqlite_master WHERE type = 'table';

-- Sales overview
SELECT COUNT(*) AS invoices,
COUNT(DISTINCT CustomerId) AS customers,
MIN(DATE(InvoiceDate)) AS first_sale,
MAX(DATE(InvoiceDate)) AS last_sale,
ROUND(SUM(Total), 2) AS total_revenue
FROM Invoice;

-- 1. Top 10 tracks
SELECT t.Name AS track,
ar.Name AS artist,
g.Name AS genre,
SUM(il.Quantity) AS units_sold,
ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Album al ON t.AlbumId = al.AlbumId
JOIN Artist ar ON al.ArtistId = ar.ArtistId
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY t.TrackId
ORDER BY revenue DESC, units_sold DESC
LIMIT 10;

-- 1. Top 10 genres
SELECT g.Name AS genre,
SUM(il.Quantity) AS units_sold,
ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue,
ROUND(100.0 * SUM(il.UnitPrice * il.Quantity) / (SELECT SUM(Total) FROM Invoice), 1) AS revenue_pct
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY g.Name
ORDER BY revenue DESC
LIMIT 10;

-- 1. Top 10 artists
SELECT ar.Name AS artist,
SUM(il.Quantity) AS units_sold,
ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Album al ON t.AlbumId = al.AlbumId
JOIN Artist ar ON al.ArtistId = ar.ArtistId
GROUP BY ar.Name
ORDER BY revenue DESC
LIMIT 10;

-- 1. Top 10 albums
SELECT al.Title AS album,
ar.Name AS artist,
SUM(il.Quantity) AS units_sold,
ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Album al ON t.AlbumId = al.AlbumId
JOIN Artist ar ON al.ArtistId = ar.ArtistId
GROUP BY al.AlbumId
ORDER BY revenue DESC
LIMIT 10;

-- 2. Revenue per country (RANK)
SELECT BillingCountry AS country,
COUNT(DISTINCT CustomerId) AS customers,
COUNT(*) AS invoices,
ROUND(SUM(Total), 2) AS revenue,
ROUND(SUM(Total) / COUNT(DISTINCT CustomerId), 2) AS revenue_per_customer,
RANK() OVER (ORDER BY SUM(Total) DESC) AS revenue_rank
FROM Invoice
GROUP BY BillingCountry
ORDER BY revenue DESC;

-- 2. Revenue per region
SELECT CASE
WHEN BillingCountry IN ('USA', 'Canada') THEN 'North America'
WHEN BillingCountry IN ('Brazil', 'Argentina', 'Chile') THEN 'South America'
WHEN BillingCountry = 'India' THEN 'Asia'
WHEN BillingCountry = 'Australia' THEN 'Oceania'
ELSE 'Europe'
END AS region,
COUNT(DISTINCT CustomerId) AS customers,
ROUND(SUM(Total), 2) AS revenue,
ROUND(100.0 * SUM(Total) / (SELECT SUM(Total) FROM Invoice), 1) AS revenue_pct
FROM Invoice
GROUP BY region
ORDER BY revenue DESC;

-- 3. Monthly revenue with running total (SUM OVER)
SELECT strftime('%Y-%m', InvoiceDate) AS month,
COUNT(*) AS invoices,
ROUND(SUM(Total), 2) AS revenue,
ROUND(SUM(SUM(Total)) OVER (ORDER BY strftime('%Y-%m', InvoiceDate)), 2) AS running_total
FROM Invoice
GROUP BY month
ORDER BY month;

-- 3. Yearly revenue and growth (LAG)
WITH yearly AS (
SELECT strftime('%Y', InvoiceDate) AS year,
COUNT(*) AS invoices,
ROUND(SUM(Total), 2) AS revenue
FROM Invoice
GROUP BY year
)
SELECT year, invoices, revenue,
LAG(revenue) OVER (ORDER BY year) AS prev_year,
ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year)) / LAG(revenue) OVER (ORDER BY year), 1) AS growth_pct
FROM yearly;

-- 3. Average revenue per calendar month
SELECT strftime('%m', InvoiceDate) AS month_num,
ROUND(SUM(Total) / COUNT(DISTINCT strftime('%Y', InvoiceDate)), 2) AS avg_revenue
FROM Invoice
GROUP BY month_num;

-- Bonus: best-selling artist in each genre (ROW_NUMBER)
WITH artist_sales AS (
SELECT g.Name AS genre,
ar.Name AS artist,
ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue,
ROW_NUMBER() OVER (PARTITION BY g.Name ORDER BY SUM(il.UnitPrice * il.Quantity) DESC) AS rn
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Genre g ON t.GenreId = g.GenreId
JOIN Album al ON t.AlbumId = al.AlbumId
JOIN Artist ar ON al.ArtistId = ar.ArtistId
GROUP BY g.Name, ar.Name
)
SELECT genre, artist AS top_artist, revenue
FROM artist_sales
WHERE rn = 1
ORDER BY revenue DESC
LIMIT 10;

-- Bonus: top 5 customers (RANK)
SELECT c.FirstName || ' ' || c.LastName AS customer,
c.Country AS country,
COUNT(i.InvoiceId) AS invoices,
ROUND(SUM(i.Total), 2) AS total_spent,
RANK() OVER (ORDER BY SUM(i.Total) DESC) AS spend_rank
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
ORDER BY spend_rank
LIMIT 5;
