
SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM 
	covid_project.dbo.covid_deaths
WHERE 
	continent IS NOT NULL
ORDER BY 1,2


-- Total Cases vs Total Deaths

SELECT
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(CAST(total_deaths AS float)/total_cases)*100 AS death_percentage
FROM 
	covid_project.dbo.covid_deaths
WHERE 
	continent IS NOT NULL
ORDER BY 1,2


-- Total Cases vs Population

SELECT
	location, 
	date, 
	population, 
	total_cases, 
	(CAST(total_cases AS float)/population)*100 AS infected_rate
FROM 
	covid_project.dbo.covid_deaths
WHERE
	continent IS NOT NULL
ORDER BY 1,2


-- Max Total Case Vs. Population

SELECT
	location, 
	population, 
	MAX(total_cases) AS max_total_cases, 
	(CAST(MAX(total_cases) AS float)/population)*100 AS infected_rate
FROM
	covid_project.dbo.covid_deaths
WHERE 
	continent IS NOT NULL
GROUP BY
	location, population
ORDER BY 
	infected_rate DESC


-- Countries with Highest Death Count

SELECT
	location, 
	MAX(total_deaths) AS total_death_count
FROM 
	covid_project.dbo.covid_deaths
WHERE 
	continent IS NOT NULL
GROUP BY
	location
ORDER BY 
	total_death_count DESC

	
-- Continents with Highest Death Count

SELECT 
	continent, 
	SUM(max_total_deaths) AS max_total_deaths_by_continent
FROM (
	SELECT 
		continent, 
		location, 
		MAX(total_deaths) AS max_total_deaths
 	FROM 
		covid_project.dbo.covid_deaths
	WHERE 
		continent IS NOT NULL
	GROUP BY 
		continent, location
	) AS subquery
GROUP BY 
	continent
ORDER BY 
	max_total_deaths_by_continent DESC

	
-- Second way to do the same thing, easier to use

SELECT
	location, 
	MAX(total_deaths) AS total_death_count
FROM 
	covid_project.dbo.covid_deaths
WHERE 
	continent IS NULL
GROUP BY
	location
ORDER BY 
	total_death_count DESC

	
-- Global Numbers

SELECT
	date, 
	SUM(total_cases)AS total_cases, 
	SUM(total_deaths) AS total_deaths, 
	CASE
	WHEN SUM(total_cases) = 0 THEN 0
	ELSE (SUM(CAST(total_deaths AS float))/SUM(CAST(total_cases AS float)))*100 
	END AS death_percentage
FROM 
	covid_project.dbo.covid_deaths
WHERE 
	continent IS NOT NULL
GROUP BY 
	date
ORDER BY 1,2

-- Death percentage overall, up to 06/15/2023

SELECT
	SUM(new_cases)AS total_cases, 
	SUM(new_deaths) AS total_deaths, 
	CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE (SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float)))*100 
	END AS death_percentage
FROM 
	covid_project.dbo.covid_deaths
WHERE 
	continent IS NOT NULL

	
-- Total population vs. vaccinations

SELECT 
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population, 
	cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations AS bigint)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS rolling_new_vaccinations
FROM 
	covid_project.dbo.covid_deaths cd
JOIN 
	covid_project.dbo.covid_vaccinations cv
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE 
	cd.continent IS NOT NULL
ORDER BY
	2,3

	
-- Use CTE

WITH pop_vs_vac (continet, location, date, population, new_vaccinations, rolling_new_vaccinations)
AS 
(
	SELECT 
		cd.continent, 
		cd.location, 
		cd.date, 
		cd.population, 
		cv.new_vaccinations,
		SUM(CAST(cv.new_vaccinations AS bigint)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS rolling_new_vaccinations
	FROM 
		covid_project.dbo.covid_deaths cd
	JOIN 
		covid_project.dbo.covid_vaccinations cv
		ON cd.location = cv.location 
		AND cd.date = cv.date
	WHERE 
		cd.continent IS NOT NULL
)

	
SELECT 
	*, CONVERT(float,rolling_new_vaccinations)/population)*100
FROM 
	pop_vs_vac

	
-- Create temp table

DROP TABLE IF EXISTS #percent_pop_vaccinated
CREATE TABLE #percent_pop_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date date,
population numeric,
new_vaccionations numeric,
rolling_new_vaccinations numeric
)

INSERT INTO #percent_pop_vaccinated
	SELECT 
		cd.continent, 
		cd.location, 
		cd.date, 
		cd.population, 
		cv.new_vaccinations,
		SUM(CAST(cv.new_vaccinations AS bigint)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS rolling_new_vaccinations
	FROM 
		covid_project.dbo.covid_deaths cd
	JOIN 
		covid_project.dbo.covid_vaccinations cv
		ON cd.location = cv.location 
		AND cd.date = cv.date
	WHERE 
		cd.continent IS NOT NULL

	
SELECT *, (rolling_new_vaccinations/population)*100
FROM 
	#percent_pop_vaccinated



-- Creating view to store data for later visualizations

USE covid_project

GO

CREATE VIEW percent_pop_vaccinated AS

	SELECT 
		cd.continent,
		cd.location, 
		cd.date, 
		cd.population, 
		cv.new_vaccinations,
		SUM(CAST(cv.new_vaccinations AS bigint)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS rolling_new_vaccinations
	FROM 
		covid_project.dbo.covid_deaths cd
	JOIN 
		covid_project.dbo.covid_vaccinations cv
		ON cd.location = cv.location 
		AND cd.date = cv.date
	WHERE 
		cd.continent IS NOT NULL

