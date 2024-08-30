/* 
Exploratory Analysis of Netflix Shows and Movies
The objective of this exercise is to learn, clean and prepare the dataset in order to draw valuable insights.

*/



/* VERIFYING THE DATASET */

-- Verifying the dataset has been imported properly

SELECT *
FROM Netflix..netflix_titles
ORDER BY show_id ASC

-- At this point, show_id is ordered strangely such that "s1" is followed by "s10", "s100", and so forth. We want to order these numerically.

SELECT *
FROM Netflix..netflix_titles
ORDER BY LEN(show_id), show_id ASC

-- First we want to check that the primary key show_id has no duplicates.

SELECT show_id
	, COUNT(*) AS count_show_id
FROM Netflix..netflix_titles
GROUP BY show_id
HAVING COUNT(*) > 1

-- Next, we check for null values across columns

SELECT COUNT(CASE WHEN show_id IS NULL THEN 1 END) AS showid_nulls
    ,  COUNT(CASE WHEN type IS NULL THEN 1 END) AS type_nulls
    ,  COUNT(CASE WHEN title IS NULL THEN 1 END) AS title_nulls
    ,  COUNT(CASE WHEN director IS NULL THEN 1 END) AS director_nulls
    ,  COUNT(CASE WHEN cast IS NULL THEN 1 END) AS cast_nulls
    ,  COUNT(CASE WHEN country IS NULL THEN 1 END) AS country_nulls
    ,  COUNT(CASE WHEN date_added IS NULL THEN 1 END) AS date_added_nulls
    ,  COUNT(CASE WHEN release_year IS NULL THEN 1 END) AS release_year_nulls
    ,  COUNT(CASE WHEN rating IS NULL THEN 1 END) AS rating_nulls
    ,  COUNT(CASE WHEN duration IS NULL THEN 1 END) AS duration_nulls
    ,  COUNT(CASE WHEN listed_in IS NULL THEN 1 END) AS listed_in_nulls
    ,  COUNT(CASE WHEN description IS NULL THEN 1 END) AS description_nulls
FROM Netflix..netflix_titles

-- The hypothesis is that the show_id is generated according to the date_added to the platform.
-- Sorting from oldest date_added to newest. Selecting all titles, ordered by date_added ascending

SELECT *
FROM Netflix..netflix_titles
WHERE date_added IS NOT NULL
ORDER BY date_added ASC

/* INSIGHT: The primary key show_id does not correspond to the record's date_added attribute. 
This could mean that it is generated randomly, or there are factors for being assigned this show_id. 
As the dataset and its source offers no other information, we cannot determine how the primary key is generated. */



/* DATA EXPLORATION */

-- Finding the count per type

SELECT DISTINCT type
	, COUNT(type) AS type_count
FROM Netflix..netflix_titles
GROUP BY type

-- Selecting the first title added to the platform

SELECT TOP 1 title
	, date_added
FROM Netflix..netflix_titles
WHERE date_added IS NOT NULL
ORDER BY date_added ASC

-- Selecting the last title added to the platform

SELECT TOP 1 title
	, date_added
FROM Netflix..netflix_titles
WHERE date_added IS NOT NULL
ORDER BY date_added DESC

-- Selecting the titles added to the platform without date_added

SELECT title
	, date_added
FROM Netflix..netflix_titles
WHERE date_added IS NULL

-- Checking the count of titles per release year

SELECT release_year
	, COUNT(show_id) AS count
FROM Netflix..netflix_titles
GROUP BY release_year
ORDER BY release_year ASC

SELECT release_year
	, COUNT(*) AS count
FROM Netflix..netflix_titles
GROUP BY release_year
ORDER BY release_year ASC

-- Finding the year with the highest release count

SELECT TOP 1 release_year
	, COUNT(show_id) AS count
FROM Netflix..netflix_titles
GROUP BY release_year
ORDER BY COUNT(*) DESC

-- We want to find the top billed actor. The top billed actor is usually the first in the cast list, and a quick online search confirms that this dataset follows that logic.
-- Creating a new column for the top billed actor where it takes the first name in the string, or the whole cast if there is only one name.

SELECT title
	, cast
    , IIF(SUBSTRING(cast, 0, CHARINDEX(',', cast)) = '', cast, SUBSTRING(cast, 0, CHARINDEX(',', cast))) AS top_billed_actor
FROM Netflix..netflix_titles
ORDER BY date_added ASC

-- Number of films per top billed actor. We need to create either a common table expression (CTE).

WITH top_billing
AS
	(
	SELECT *
		, IIF(SUBSTRING(cast, 0, CHARINDEX(',', cast)) = '', cast, SUBSTRING(cast, 0, CHARINDEX(',', cast))) AS top_billed_actor
	FROM Netflix..netflix_titles
	)
SELECT top_billed_actor
	, COUNT(show_id) AS count
FROM top_billing
GROUP BY top_billed_actor
ORDER BY count DESC

-- We want to have a table of all the titles in which country they are available. 
-- Unlike the top billing position in the previous query where there is a hierarchy in the order of names, there is no such order in the country.

WITH countries_split
AS
	(
	SELECT *
	, value as countries_available
	FROM Netflix..netflix_titles
	OUTER APPLY STRING_SPLIT(REPLACE(country, ', ', ','),',')
	--ORDER BY LEN(show_id), show_id ASC
	)
SELECT countries_available
	, COUNT(show_id) AS count
FROM countries_split
GROUP BY countries_available 
ORDER BY count DESC

-- Similar to the previous query where there is no hierarchy in the order of names, we want to apply the same logic for directors.

WITH director_split
AS
	(
	SELECT *
		, value as director_names
	FROM Netflix..netflix_titles
	OUTER APPLY STRING_SPLIT(REPLACE(director, ', ', ','),',')
	)
SELECT director_names
	, COUNT(show_id) AS count
FROM director_split
GROUP BY director_names 
ORDER BY count DESC

-- Apply the same equal weight for listed_in and rename to a more recognizable name like 'genres'.

WITH genres_split
AS
	(	
	SELECT show_id
		, type
		, title
		, date_added
		, release_year
		, rating
		, value as genres
	FROM Netflix..netflix_titles
	OUTER APPLY STRING_SPLIT(REPLACE(listed_in, ', ', ','),',')
	)
SELECT genres
	, COUNT(show_id) AS count
FROM genres_split
GROUP BY genres
ORDER BY count DESC

-- Count of title by actor
-- Unlike the top_billing_actor, we want to assign equal weights on each cast value we extract.

SELECT *
	, value as actor_name
FROM Netflix..netflix_titles
CROSS APPLY STRING_SPLIT(REPLACE(cast, ', ', ','),',')
ORDER BY LEN(show_id), show_id ASC

WITH cast_split
AS 
	(
	SELECT *
		, value as actor_name
	FROM Netflix..netflix_titles
	CROSS APPLY STRING_SPLIT(REPLACE(cast, ', ', ','),',')
	)
SELECT actor_name
	, COUNT(show_id) AS count
FROM cast_split
GROUP BY actor_name
ORDER BY count DESC

-- Count of actors with most TV shows

WITH cast_split
AS 
	(
	SELECT *
		, value as actor_name
	FROM Netflix..netflix_titles
	CROSS APPLY STRING_SPLIT(REPLACE(cast, ', ', ','),',')
	WHERE type = 'TV Show'
	)
SELECT actor_name
	, COUNT(show_id) AS count
FROM cast_split
GROUP BY actor_name
ORDER BY count DESC

-- Count of actors with most movies

WITH cast_split
AS 
	(
	SELECT *
		, value as actor_name
	FROM Netflix..netflix_titles
	CROSS APPLY STRING_SPLIT(REPLACE(cast, ', ', ','),',')
	WHERE type = 'Movie'
	)
SELECT actor_name
	, COUNT(show_id) AS count
FROM cast_split
GROUP BY actor_name
ORDER BY count DESC

-- Count of TV shows vs movies per actor

WITH cast_split
AS 
	(
	SELECT *
		, value as actor_name
	FROM Netflix..netflix_titles
	CROSS APPLY STRING_SPLIT(REPLACE(cast, ', ', ','),',')
	)
SELECT actor_name
	, COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_show_count
	, COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movie_count
FROM cast_split
GROUP BY actor_name
ORDER BY tv_show_count DESC

-- Checking the count of titles per type per release year

SELECT release_year
	, COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_show_count
	, COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movie_count
FROM Netflix..netflix_titles
GROUP BY release_year
ORDER BY release_year ASC

-- Top billed actors by country

WITH countries_split
AS
	(
	SELECT *
	, value as countries_available
	, IIF(SUBSTRING(cast, 0, CHARINDEX(',', cast)) = '', cast, SUBSTRING(cast, 0, CHARINDEX(',', cast))) AS top_billed_actor
	FROM Netflix..netflix_titles
	OUTER APPLY STRING_SPLIT(REPLACE(country, ', ', ','),',')
	)
SELECT top_billed_actor
	, countries_available
	, COUNT(show_id) AS count
FROM countries_split
GROUP BY top_billed_actor
	, countries_available 
ORDER BY count DESC

-- Count of Titles per Director per Genre

WITH director_genres_split
AS
	(	
	SELECT show_id
		, type
		, title
		, date_added
		, release_year
		, rating
		, genres.value as genres
		, directors.value as directors
	FROM Netflix..netflix_titles
	OUTER APPLY STRING_SPLIT(REPLACE(listed_in, ', ', ','),',') AS genres
	OUTER APPLY STRING_SPLIT(REPLACE(director, ', ', ','),',') AS directors
	)
SELECT type
	, directors
	, genres
	, COUNT(show_id) AS count
FROM director_genres_split
GROUP BY type 
	, directors
	, genres
ORDER BY directors ASC