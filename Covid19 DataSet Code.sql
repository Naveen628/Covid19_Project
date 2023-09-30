SELECT *
FROM Covid19..CovidDeaths

--Let's select the columns we're going to be working with.
--We'll order it by location & date
--Also the data contains Continent names like Asia,Africa etc in location column which should be in the Continent column.
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Covid19..CovidDeaths
WHERE continent is not NULL
Order By 1,2

--Calculating Total Deaths vs Total Cases
--Likelihood of getting the Covid and dying in Pakistan
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Covid19..CovidDeaths
WHERE location = 'Pakistan'
and continent is not NULL
Order By 1,2

--Calculating Total Cases vs Population
--Percentage of Population getting infected by Covid
-- Pakistan did not reach even half the percent of infection count in a population of 220 million with total cases of almost 8.5 lacs.
SELECT Location, date, population, total_cases, (total_cases/population)*100 as InfectedPopulationPercentage
FROM Covid19..CovidDeaths
WHERE location = 'Pakistan'
and continent is not NULL
Order By 1,2


--Calculating which country has the highest infection rates compared to the population
--Pakistan stands on the 129th place of highest infected countries out of 219 countires of the world.
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPopulationPercentage
FROM Covid19..CovidDeaths
GROUP BY location, population
--WHERE location = 'Pakistan'
Order By InfectedPopulationPercentage DESC


--Calculating the Countries with Highest Death Count per Population
SELECT Location, MAX(total_deaths) as TotalDeathCount
FROM Covid19..CovidDeaths
GROUP BY location
--WHERE location = 'Pakistan'
Order By TotalDeathCount DESC

--The data type of total deaths is wrong, it should be an integar but it is a nvarchar, which gives the results incorrect. So we need to change the data type of the column to get the correct results.
SELECT Location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM Covid19..CovidDeaths
WHERE continent is not NULL
GROUP BY location
--WHERE location = 'Pakistan'
Order By TotalDeathCount DESC



--Above we were looking at everything by 'LOCATION' - Now let's do it by 'CONTINENT'
--Continents with the highest death counts per population

SELECT continent, MAX(CAST(total_deaths as int)) as HighestDeathCount
FROM Covid19..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
--WHERE location = 'Pakistan'
Order By HighestDeathCount DESC


--GLOBAL NUMBERS
--Per day new cases vs per day deaths
SELECT date, SUM(new_cases) as SumOfNewCases, SUM(CAST(new_deaths as int)) as SumOfNewDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentageGlobally
FROM Covid19..CovidDeaths
WHERE continent is not NULL
GROUP BY date 
Order By 1,2

--Total Number of Cases across the Globe and total number of people died due to Covid and death percentage
SELECT SUM(new_cases) as SumOfNewCases, SUM(CAST(new_deaths as int)) as SumOfNewDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentageGlobally
FROM Covid19..CovidDeaths
WHERE continent is not NULL
--GROUP BY date 
Order By 1,2



--Total Population vs New Vaccination PER DAY
-- The total amount of people in the world that have been vaccinated

SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations 
FROM Covid19..CovidDeaths death
JOIN Covid19..CovidVaccinations vaccine
	ON death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent is not NULL
Order By 2,3



--PER DAY ROLLING COUNT -- of each day people get vaccinated - Adding the vaccinations per day 
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
, SUM(CAST(vaccine.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Covid19..CovidDeaths death
JOIN Covid19..CovidVaccinations vaccine
	ON death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent is not NULL
Order By 2,3


--Creating CTE for RollingPeopleVaccinated

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
, SUM(CAST(vaccine.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Covid19..CovidDeaths death
JOIN Covid19..CovidVaccinations vaccine
	ON death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent is not NULL
--Order By 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac
Order By 2,3


--TEMP TABLE 

DROP TABLE IF EXISTS #PopulationPercentVaccinated
CREATE TABLE #PopulationPercentVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT into #PopulationPercentVaccinated
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
, SUM(CAST(vaccine.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
FROM Covid19..CovidDeaths death
JOIN Covid19..CovidVaccinations vaccine
	ON death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent is not NULL

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PopulationPercentVaccinated
--Order By 2,3


--Creating View for Visualizations
CREATE VIEW PopulationPercentVaccinated as
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
, SUM(CAST(vaccine.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Covid19..CovidDeaths death
JOIN Covid19..CovidVaccinations vaccine
	ON death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent is not NULL
--Order By 2,3

SELECT *
FROM PopulationPercentVaccinated