CREATE OR REPLACE FUNCTION customer_name(cust_id int)
	RETURNS varchar(91)
	LANGUAGE PLPGSQL
	AS $$
	DECLARE
		full_name varchar(91);
	BEGIN
		SELECT CONCAT(first_name, ' ', last_name)
		INTO full_name
		FROM customer_rentals
		WHERE customer_id = cust_id;
	RETURN full_name;
	END;
	$$;
	
CREATE OR REPLACE FUNCTION top_customer(cust_id int, cutoff double precision)
	RETURNS boolean
	LANGUAGE plpgsql
	AS $$
	DECLARE
	    rental_count bigint;
	BEGIN
	    SELECT COUNT(rental_id)
	    INTO rental_count
	    FROM customer_rentals
	    WHERE customer_id = cust_id;
	
	    RETURN rental_count >= cutoff;
	END;
	$$;

CREATE OR REPLACE FUNCTION rpc_trigger_func()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
DELETE FROM rentals_per_customer;
INSERT INTO rentals_per_customer
	SELECT customer_id, count(rental_id) as number_of_rentals, 
customer_name(customer_id) AS customer_name, 
	email, top_customer(customer_id) as top_customer
	FROM customer_rentals
	GROUP BY customer_id, customer_name, email
	ORDER BY number_of_rentals desc;
RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER rpc_trigger
AFTER INSERT OR UPDATE OR DELETE ON customer_rentals
FOR EACH STATEMENT
EXECUTE PROCEDURE rpc_trigger_func();

CREATE OR REPLACE FUNCTION tcm_trigger_func()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
DELETE FROM top_customer_movies;
INSERT INTO top_customer_movies
SELECT title, count(title) as times_rented, description, fulltext
FROM (
SELECT title, description, fulltext
FROM customer_rentals
WHERE customer_id IN
(SELECT customer_id 
FROM rentals_per_customer
WHERE top_customer)
ORDER BY title) as subq
GROUP BY title, description, fulltext
ORDER BY times_rented DESC;
RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER tcm_trigger
AFTER INSERT OR UPDATE OR DELETE ON customer_rentals
FOR EACH STATEMENT
EXECUTE PROCEDURE tcm_trigger_func();


CREATE OR REPLACE FUNCTION patc_trigger_func()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
DELETE FROM popular_among_top_customers;
INSERT INTO popular_among_top_customers
SELECT * 
FROM top_customer_movies
WHERE (times_rented*1.0)/
(SELECT COUNT(*) 
FROM rentals_per_customer
WHERE top_customer) > 0.15;
RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER patc_trigger
AFTER INSERT OR UPDATE OR DELETE ON customer_rentals
FOR EACH STATEMENT
EXECUTE PROCEDURE patc_trigger_func();

CREATE OR REPLACE FUNCTION get_top_keywords()
	RETURNS TEXT[]
	LANGUAGE PLPGSQL
	AS $$
	DECLARE
		x text[];
	BEGIN
		x := ARRAY(SELECT word
		FROM ts_stat('SELECT fulltext FROM popular_among_top_customers')
		WHERE word <> 'must'
		  AND ndoc > 2
		ORDER BY ndoc DESC);
			RETURN x;
	END;
	$$;

CREATE OR REPLACE FUNCTION compare_keywords()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
	x text[];
	word text;
	counter int; 
BEGIN 
	counter := 0;
	x := get_top_keywords();
	FOREACH word in ARRAY x
	LOOP 
		IF NEW.fulltext @@ to_tsquery(word)
		THEN counter:= counter + 1;
		END IF;
	END LOOP;
	IF counter >= 2
	THEN PERFORM pg_notify('newmovies',  'A new movie has been released that you might like: '||NEW."title"|| ': ' ||lower(NEW."description")||'.');
	END IF;
RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER new_movie_notify
AFTER INSERT ON film
FOR EACH ROW
EXECUTE PROCEDURE compare_keywords();

CREATE OR REPLACE PROCEDURE create_tables()
LANGUAGE PLPGSQL
AS $$
BEGIN
DROP TABLE IF EXISTS customer_rentals;
DROP TABLE IF EXISTS rentals_per_customer;
DROP TABLE IF EXISTS top_customer_movies;
DROP TABLE IF EXISTS popular_among_top_customers;
CREATE TABLE customer_rentals AS
	SELECT c.customer_id, c.first_name, c.last_name, c.email, r.rental_id, i.inventory_id, 
f.film_id, f.title, f.description, f.fulltext
	FROM customer c
	LEFT JOIN rental r
	ON c.customer_id = r.customer_id
	JOIN inventory i 
	ON r.inventory_id = i.inventory_id
	JOIN film f
	ON f.film_id = i.film_id
	ORDER BY f.film_id, c.customer_id;
	
CREATE TABLE rentals_per_customer AS
WITH per_customer AS (SELECT customer_id, COUNT(rental_id) AS number_of_rentals,
customer_name(customer_id) AS customer_name, email
FROM customer_rentals GROUP BY customer_id, customer_name, email),
cutoff AS (SELECT percentile_cont(0.8) WITHIN GROUP (ORDER BY number_of_rentals) AS value
FROM per_customer)
SELECT pc.customer_id, pc.number_of_rentals, pc.customer_name, pc.email,
    top_customer(pc.customer_id, cutoff.value) AS top_customer
FROM per_customer pc, cutoff
ORDER BY pc.number_of_rentals DESC;

ALTER TABLE rentals_per_customer
ADD PRIMARY KEY(customer_id);

ALTER TABLE customer_rentals
ADD FOREIGN KEY(customer_id) REFERENCES rentals_per_customer(customer_id);

CREATE TABLE top_customer_movies AS
SELECT title, count(title) as times_rented, description, fulltext
FROM (
SELECT title, description, fulltext
FROM customer_rentals
WHERE customer_id IN
(SELECT customer_id 
FROM rentals_per_customer
WHERE top_customer)
ORDER BY title) as subq
GROUP BY title, description, fulltext
ORDER BY times_rented desc;

CREATE TABLE popular_among_top_customers AS
WITH mpm as (select * from top_customer_movies),
cutoff as (select percentile_cont(0.9) within group (order by times_rented) as value
FROM mpm)
select * from mpm, cutoff
WHERE mpm.times_rented >= cutoff.value;

RETURN;
END;
$$;
CALL create_tables();