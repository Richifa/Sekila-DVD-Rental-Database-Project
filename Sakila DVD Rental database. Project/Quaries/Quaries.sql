/* Query 1 -Most Rented Movie */
SELECT 
  f.title, 
  c.name category, 
  COUNT(*) 
FROM 
  category c 
  JOIN film_category fc ON c.category_id = fc.category_id 
  JOIN film f ON fc.film_id = f.film_id 
  JOIN inventory i ON i.film_id = f.film_id 
  JOIN rental r ON i.inventory_id = r.inventory_id 
WHERE 
  c.name IN (
    'Animation', 'Children', 'Classics', 
    'Comedy', 'Family', 'Music'
  ) 
GROUP BY 
  1, 
  2 
ORDER BY 
  2, 
  1




/* Query 2 - how the length of rental duration of these family-friendly movies compares to the duration that all movies are rented for*/

SELECT t1.title, t1.category, t1.duration, NTILE(4) OVER (Partition By duration ORDER BY t1.duration) AS standard_quartile
FROM
   (SELECT f.title title, c.name category, Sum(f.rental_duration) duration
    FROM category c
    JOIN film_category fc
    ON c.category_id = fc.category_id
    JOIN film f
    ON fc.film_id = f.film_id
    WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
    Group By f.title, c.name)t1

Group By t1.title, t1.category, t1.duration;

/* Query 3 - provide a table with the family-friendly film category, 
each of the quartiles */

SELECT category, standard_quartile,
COUNT(*)
FROM
    (SELECT c.name category, f.rental_duration,
     NTILE(4) OVER (ORDER BY f.rental_duration) AS standard_quartile
     FROM category c
     JOIN film_category fc
     ON c.category_id = fc.category_id
     JOIN film f
     ON fc.film_id = f.film_id
     WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')) t1
GROUP BY category, standard_quartile
ORDER BY category, standard_quartile;


/* Query 4 -  , for each of these top 10 paying customers, I would like to find out the difference across their monthly payments during 2007?*/

    
WITH top10 AS (
  SELECT 
    c.customer_id, 
    SUM(p.amount) AS total_payments 
  FROM 
    customer c 
    JOIN payment p ON p.customer_id = c.customer_id 
  GROUP BY 
    c.customer_id 
  ORDER BY 
    total_payments DESC 
  LIMIT 
    10
), t2 AS (
  SELECT 
    DATE_TRUNC('month', payment_date) AS pay_mon, 
    (first_name || ' ' || last_name) AS full_name, 
    SUM(p.amount) AS pay_amount 
  FROM 
    top10 
    JOIN customer c ON top10.customer_id = c.customer_id 
    JOIN payment p ON p.customer_id = c.customer_id 
  WHERE 
    payment_date >= '2007-01-01' 
    AND payment_date < '2008-01-01' 
  GROUP BY 
    1, 
    2
) 
SELECT 
  *, 
  LAG(t2.pay_amount) OVER (
    PARTITION BY full_name 
    ORDER BY 
      t2.pay_amount
  ) AS lag, 
  (
    pay_amount - COALESCE(
      LAG(t2.pay_amount) OVER (
        PARTITION BY full_name 
        ORDER BY 
          t2.pay_mon
      ), 
      0
    )
  ) AS difference 
FROM 
  t2 
ORDER BY 
  difference DESC 
Limit 
  10;
