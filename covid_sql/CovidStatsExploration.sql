-- Create the two tables needed for data exploration 

CREATE TABLE covid_deaths (
	iso_code VARCHAR(10), continent VARCHAR(15),
	location VARCHAR(50), date DATE, population NUMERIC,
	total_cases NUMERIC, new_cases NUMERIC,	new_cases_smoothed NUMERIC, 
	total_deaths NUMERIC, new_deaths NUMERIC, new_deaths_smoothed NUMERIC,
	total_cases_per_million NUMERIC, new_cases_per_million NUMERIC,
	new_cases_smoothed_per_million NUMERIC,	total_deaths_per_million NUMERIC,
	new_deaths_per_million NUMERIC,	new_deaths_smoothed_per_million NUMERIC,
	reproduction_rate NUMERIC,icu_patients NUMERIC,
	icu_patients_per_million NUMERIC, hosp_patients NUMERIC, hosp_patients_per_million NUMERIC,
	weekly_icu_admissions NUMERIC, weekly_icu_admissions_per_million NUMERIC, 
	weekly_hosp_admissions NUMERIC, weekly_hosp_admissions_per_million NUMERIC
);

CREATE TABLE covid_vaccinations (
	iso_code VARCHAR(10), continent VARCHAR(15),
	location VARCHAR(50), date DATE, new_tests INT, 
	total_tests INT, total_tests_per_thousand NUMERIC,
	new_tests_per_thousand NUMERIC,	new_tests_smoothed INT,
	new_tests_smoothed_per_thousand NUMERIC, positive_rate NUMERIC,
	tests_per_case FLOAT, tests_units VARCHAR (20),
	total_vaccinations INT, people_vaccinated INT, 
	people_fully_vaccinated INT, new_vaccinations INT, new_vaccinations_smoothed INT,
	total_vaccinations_per_hundred NUMERIC,	people_vaccinated_per_hundred NUMERIC,
	people_fully_vaccinated_per_hundred NUMERIC, 
	new_vaccinations_smoothed_per_million INT,	
	stringency_index NUMERIC, population_density NUMERIC, median_age NUMERIC, 
	aged_65_older NUMERIC, aged_70_older NUMERIC, gdp_per_capita NUMERIC,
	extreme_poverty NUMERIC, cardiovasc_death_rate NUMERIC,
	diabetes_prevalence NUMERIC, female_smokers NUMERIC, male_smokers NUMERIC,
	handwashing_facilities NUMERIC, hospital_beds_per_thousand NUMERIC,
	life_expectancy NUMERIC, human_development_index NUMERIC
);


-- Total Cases vs Total Deaths in Japan and the United States, respectively. 
-- Shows the likelihood of death after infection.

SELECT location, date, total_cases, total_deaths, 
	(total_deaths/total_cases) * 100 AS death_percentage
FROM covid_deaths
WHERE location = 'Japan';

SELECT location, date, total_cases, total_deaths,
	(total_deaths/total_cases) * 100 AS death_percentage
FROM covid_deaths
WHERE location like '%States%'
ORDER BY 1,2;

-- Total Cases vs Total Population in Japan and the United States, respectively.
-- Shows what percentage of the population in each country contracted Covid. 

SELECT location, date,population, total_cases,
	(total_cases/population) * 100 AS population_infected_percentage
FROM covid_deaths
WHERE location = 'Japan';

SELECT location, date,population, total_cases,
	(total_cases/population) * 100 AS population_infected_percentage
FROM covid_deaths
WHERE location = 'United States'
ORDER BY 1,2;

-- Countries exhibiting the highest infection rates relative to their populations.

SELECT location, population, MAX(total_cases) AS highest_infection_count,
	MAX((total_cases/population)) * 100 AS population_infected_percentage
FROM covid_deaths
WHERE total_cases IS NOT NULL AND population IS NOT NULL
GROUP BY location, population
ORDER BY population_infected_percentage desc;

-- Countries exhibiting highest death counts. 

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE total_deaths IS NOT NULL AND continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- Continent with the highest death counts. 
-- Don't include: World, European Union, and International

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NULL AND location IN 
	('Europe', 'North America', 'South America', 'Asia', 'Africa', 'Oceania')
GROUP BY location
ORDER BY total_death_count DESC; 

-- Global Numbers

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,
	ROUND(SUM(new_deaths)/SUM(new_cases) * 100, 2) AS death_percentage
FROM covid_deaths
WHERE continent is NOT NULL;

-- Join the two tables

SELECT * 
FROM covid_deaths cd
JOIN covid_vaccinations cv
ON cd.location = cv.location AND cd.date = cv.date;

-- Total Vaccinations vs Total Population (Using CTE)

With PopvsVaccs (continent, location, date, population, new_vaccinations, rolling_vaccinations)
as
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
	,SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location,
	cd.date) AS rolling_vaccinations
FROM covid_deaths cd
JOIN covid_vaccinations cv
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent is NOT NULL
)
SELECT *, ROUND((rolling_vaccinations/population) *100, 3) AS percent_population_vaccs
FROM PopvsVaccs;

-- Same query as previous (Utilizing TEMP Table)

DROP TABLE IF EXISTS percent_population_vaccinated;
CREATE TEMP TABLE percent_population_vaccinated
(
	continent varchar(255),
	location varchar(255),
	date Date,
	population numeric,
	new_vaccinations numeric,
	rolling_vaccinations numeric
);

INSERT INTO percent_population_vaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
	,SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location,
	cd.date) AS rolling_vaccinations
FROM covid_deaths cd
JOIN covid_vaccinations cv
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent is NOT NULL;

SELECT *, ROUND((rolling_vaccinations/population) *100, 3) AS percent_population_vaccs
FROM percent_population_vaccinated;

-- Creating views to store data for later visualizations

CREATE VIEW RollingVaccinationsCount AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
	,SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location,
	cd.date) AS rolling_vaccinations
FROM covid_deaths cd
JOIN covid_vaccinations cv
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent is NOT NULL
ORDER BY 2,3;


-- [EXTRA EXPLORATORY QUERIES AND VIEWS]

-- Infection rates in East Asia 

SELECT location, population, MAX(total_cases) AS highest_infection_count,
	MAX((total_cases/population)) * 100 AS population_infected_percentage
FROM covid_deaths
WHERE location IN ('Japan', 'South Korea', 'China', 'Taiwan', 'Mongolia') AND 
	total_cases IS NOT NULL AND population IS NOT NULL
GROUP BY location, population
ORDER BY population_infected_percentage DESC;

-- Creating View from previous query

CREATE VIEW EastAsiaInfections AS
SELECT location, population, MAX(total_cases) AS highest_infection_count,
	MAX((total_cases/population)) * 100 AS population_infected_percentage
FROM covid_deaths
WHERE location IN ('Japan', 'South Korea', 'China', 'Taiwan', 'Mongolia') AND 
	total_cases IS NOT NULL AND population IS NOT NULL
GROUP BY location, population
ORDER BY population_infected_percentage DESC;

-- Death rates in East Asia

SELECT location, population, MAX(total_deaths) AS highest_death_count,
	MAX((total_deaths)/population) * 100 AS population_death_percentage
FROM covid_deaths
WHERE location IN ('Japan', 'South Korea', 'China', 'Taiwan', 'Mongolia') AND 
	total_cases IS NOT NULL AND population IS NOT NULL
GROUP BY location, population
ORDER BY population_death_percentage DESC; 

-- Creating View from previous

CREATE VIEW EastAsiaDeaths AS
SELECT location, population, MAX(total_deaths) AS highest_death_count,
	MAX((total_deaths)/population) * 100 AS population_death_percentage
FROM covid_deaths
WHERE location IN ('Japan', 'South Korea', 'China', 'Taiwan', 'Mongolia') AND 
	total_cases IS NOT NULL AND population IS NOT NULL
GROUP BY location, population
ORDER BY population_death_percentage DESC; 

-- Top 10 countries with the highest icu patients count. 

SELECT location, MAX(total_cases) AS highest_infection_count, 
	MAX(total_deaths) AS highest_death_count,
	MAX(icu_patients) AS highest_icu_patients_count
FROM covid_deaths
WHERE total_cases IS NOT NULL AND icu_patients IS NOT NULL
GROUP BY location
ORDER BY highest_icu_patients_count DESC
LIMIT 10;

-- Last View 

CREATE VIEW Top10Countries_ICU AS 
SELECT location, MAX(total_cases) AS highest_infection_count, 
	MAX(total_deaths) AS highest_death_count,
	MAX(icu_patients) AS highest_icu_patients_count
FROM covid_deaths
WHERE total_cases IS NOT NULL AND icu_patients IS NOT NULL
GROUP BY location
ORDER BY highest_icu_patients_count DESC
LIMIT 10;
