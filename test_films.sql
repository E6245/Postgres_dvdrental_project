-- THE BELOW QUERY WILL SHOW KEYWORDS FROM MOVIES + # OF APPEARANCES IF YOU WANT TO EDIT THE TEST MOVIES
-- select * from ts_stat('select fulltext from film')
-- order by ndoc desc;

DELETE FROM film
WHERE release_year = 2020;

LISTEN newmovies;

INSERT INTO public.film(
	title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features)
	VALUES ('Friends Forever', 'A student and a squirrel explore a submarine', 
			2020, 1, 5, 4.99, 100, 10.99, 'PG', '{"Deleted Scenes","Behind the Scenes"}'),
			('Abandoned Love', 'A rock abandoned love', 
			 2020, 1, 5, 4.99, 100, 10.99, 'PG', '{"Deleted Scenes","Behind the Scenes"}'),
			('Squirrels Away', 'An angry child throws a robot away', 
			2020, 1, 5, 4.99, 100, 10.99, 'PG', '{"Deleted Scenes","Behind the Scenes"}'),
			('Workday Adventure', 'Two waitresses encounter an abandoned tank', 
			2020, 1, 5, 4.99, 100, 10.99, 'PG', '{"Deleted Scenes","Behind the Scenes"}'),
			('Extinction Event', 'A heartwarming saga about dinosaur wrestlers', 
			2020, 1, 5, 4.99, 100, 10.99, 'PG', '{"Deleted Scenes","Behind the Scenes"}'),
			('Evil Monster', 'A Fateful Reflection of a Moose And a Monkey who must Overcome a Monster in Chicago', 
			2020, 1, 5, 4.99, 100, 10.99, 'PG', '{"Deleted Scenes","Behind the Scenes"}'),
			('Career Change', 'A juggler learns to use a chainsaw from a teacher in Casablanca', 
			2020, 1, 5, 4.99, 100, 10.99, 'PG', '{"Deleted Scenes","Behind the Scenes"}'),
			('Tragic Mining', 'A Sad Epic of a Miner And a Mad Vampire',
			2020, 1, 5, 4.99, 100, 10.99, 'PG', '{"Deleted Scenes","Behind the Scenes"}');
			