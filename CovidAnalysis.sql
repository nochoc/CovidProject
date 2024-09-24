# check that data has been imported correctly
select count(*) from covidvaccinations;
select count(*) from coviddeaths;

select * from coviddeaths limit 20; 
select * from covidvaccinations limit 20; 

DESC coviddeaths;
DESC covidvaccinations;

# fix date column
ALTER TABLE coviddeaths
MODIFY date DATE;

ALTER TABLE covidvaccinations
MODIFY date DATE;

-- start analysis

# Data of interest
SELECT location,date,total_cases,new_cases, total_deaths, population
FROM coviddeaths
ORDER BY 1,2;

	# Total cases vs total deaths

# Overall total
WITH temp as(
SELECT MAX(total_cases) as total_c, MAX(total_deaths) as total_d, location FROM coviddeaths
GROUP BY location)
SELECT sum(total_c) AS Overall_total_cases, sum(total_d) AS Overall_total_deaths, sum(total_d)/sum(total_c)*100 AS death_percent 
FROM temp;

# By country
SELECT location, MAX(total_cases) as total_c, MAX(total_deaths) as total_d, MAX(total_deaths)/MAX(total_cases)*100 AS death_percent
FROM coviddeaths
GROUP BY location;

# Specific country
SELECT location, MAX(total_cases) as total_c, MAX(total_deaths) as total_d, MAX(total_deaths)/MAX(total_cases)*100 AS death_percent
FROM coviddeaths
GROUP BY location
HAVING location LIKE "%Singapore%";

# Ordered by highest death_percent
SELECT location, MAX(total_cases) as total_c, MAX(total_deaths) as total_d, MAX(total_deaths)/MAX(total_cases)*100 AS death_percent
FROM coviddeaths
GROUP BY location
ORDER BY death_percent DESC ;

# Looking at trend
SELECT location,date,total_cases,new_cases, total_deaths, population,total_deaths/total_cases*100 AS death_percent
FROM coviddeaths
WHERE location LIKE "%Sing%"
ORDER BY 1,2;

	# Total Cases vs Population
SELECT 
	location, total_cases, population, total_cases/population*100 AS cases_percent
FROM coviddeaths;

# Percentage of cases by population
With temp as(
SELECT 
	location, total_cases, population, total_cases/population*100 AS cases_percent
FROM coviddeaths
)
SELECT location, MAX(population) as population, MAX(total_cases) AS total_case, MAX(cases_percent) AS case_percent
FROM temp
GROUP BY location;

# Overall
WITH temp AS(
SELECT 
	location, MAX(total_cases) as total_c, MAX(population) as pop
FROM coviddeaths
GROUP BY location
)
SELECT SUM(total_c) AS total_cases, SUM(pop) as total_pop, SUM(total_c)/SUM(pop)*100 as Overall_case_percent
FROM temp;

# Trend
WITH temp as(
SELECT location, date, total_cases, population, total_cases/population*100 as case_percent
FROM coviddeaths
ORDER BY 1,2
)
SELECT * FROM temp;

# Highest infection rate compared to population
SELECT 
	location, population, MAX(total_cases) AS HighestInfectedCount, MAX(total_cases/population)*100 AS PercentInfected
FROM coviddeaths
GROUP BY location,population
ORDER BY PercentInfected DESC;

# Highest Death Count per Population
SELECT 
	location, MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- If data type is wrong, eg: total_deaths is data type text instead of int, need to use CAST()
-- And since there are NULL values in some rows in continent, where the continent was put under 'location' instead, we need to use 'WHERE continent IS NOT NULL' to get country data
SELECT 
	location, MAX(CAST(total_deaths as double)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- analyze by continent
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM coviddeaths
GROUP BY continent
ORDER BY TotalDeathCount DESC; -- we have a large number under NULL and the numbers dont look quite right - America shouldn't have that much more cases than Europe, if at all

SELECT * FROM coviddeaths
ORDER BY continent;

# Taking data only where continent is NULL, so that means the location column would be the continent
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM coviddeaths
WHERE continent IS NULL
GROUP BY location
ORDER by TotalDeathCount DESC;

# Another approach
SELECT continent, SUM(new_deaths) AS TotalDeathCount
FROM coviddeaths
GROUP BY continent
ORDER BY TotalDeathCount DESC;

WITH temp as(
SELECT continent, SUM(new_deaths) AS TotalDeathCount
FROM coviddeaths
GROUP BY continent
ORDER BY TotalDeathCount DESC
)
SELECT SUM(TotalDeathCount) GlobalDeathCount FROM temp
WHERE continent is not null;

-- Remove NULL continent
SELECT continent, SUM(new_deaths) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

	# Global Numbers
# Daily cases and deaths
SELECT date, SUM(new_cases) as Total_Cases_Today, SUM(new_deaths) as Total_Deaths_Today,SUM(new_deaths)/SUM(new_cases)*100 AS DailyDeathPercent
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

# Global Death Rate
SELECT SUM(new_cases) as Total_Cases_Today, SUM(new_deaths) as Total_Deaths_Today,SUM(new_deaths)/SUM(new_cases)*100 AS DailyDeathPercent
FROM coviddeaths
WHERE continent IS NOT NULL;

	# Join coviddeaths and covidvaccinations
SELECT * 
FROM coviddeaths d
JOIN covidvaccinations v
ON d.date = v.date
AND d.location = v.location;

# Total Population vs Vaccinations
WITH temp as (
SELECT d.continent,d.location,d.date,d.population,v.new_vaccinations,
SUM(v.new_vaccinations) OVER(PARTITION BY d.location ORDER BY d.location,d.date) AS rolling_count_vaccinated
FROM coviddeaths d
JOIN covidvaccinations v
ON d.date = v.date
AND d.location = v.location
WHERE d.continent IS NOT NULL
ORDER BY 2,3
)
SELECT 
*,
rolling_count_vaccinated/population*100 AS PercentVaccinated
FROM temp
WHERE location LIKE '%Sing%';

# Create View
CREATE VIEW PercentPopVac AS
SELECT d.continent,d.location,d.date,d.population,v.new_vaccinations,
SUM(v.new_vaccinations) OVER(PARTITION BY d.location ORDER BY d.location,d.date) AS rolling_count_vaccinated
FROM coviddeaths d
JOIN covidvaccinations v
ON d.date = v.date
AND d.location = v.location
WHERE d.continent IS NOT NULL
;







