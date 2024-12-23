SELECT * FROM PortfolioProject..CovidDeaths


-- Head of dataset
SELECT TOP 5 * FROM PortfolioProject..CovidDeaths


-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Total Cases vs Total Deaths 
-- Shows likelihood of dying if I had contracted covid in Singapore
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 AS DeathPercentage FROM PortfolioProject..CovidDeaths
WHERE location like 'Singapore'
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population got Covid in Singapore
SELECT location, date, total_cases, population, (CAST(total_cases AS FLOAT)/population) * 100 AS ContractedPercentage FROM PortfolioProject..CovidDeaths
WHERE location like 'Singapore'
ORDER BY 1,2


-- Looking at Countries with the highest infection rates comparaed to population
-- Note population size when comparing
SELECT location, population, MAX(total_cases) as HighestInfectionCount, Max((CAST(total_cases AS FLOAT)/population)) * 100 AS PercentofPopulationInfected FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentofPopulationInfected DESC


-- Showing Countries with the highest death count per population
SELECT location, MAX(total_deaths) as TotalDeathCount FROM PortfolioProject..CovidDeaths
GROUP BY location
ORDER BY TotalDeathCount DESC
    -- When running the above, we see locations like world, north america, south america which are continents not countries, so we make the following changes
SELECT location, MAX(total_deaths) as TotalDeathCount FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL -- this is the change, because in the dataset when continent is null location becomes the continent
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Showing Continents with the highest death count per population
SELECT continent, MAX(total_deaths) as TotalDeathCount FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC 


-- Global Numbers - new_cases & new_deaths & death_percentage per day across the world
SELECT date, SUM(new_cases) as TotalNewCases, SUM(new_deaths) as TotalNewDeaths, SUM(CAST(new_deaths as float))/SUM(cast(new_cases as float))*100 as TotalDeathPercentage FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Global numbers across the world
SELECT SUM(new_cases) as TotalNewCases, SUM(new_deaths) as TotalNewDeaths, SUM(CAST(new_deaths as float))/SUM(cast(new_cases as float))*100 as TotalDeathPercentage FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- What is the population that was vaccinated each day in each country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- What is the population that was vaccinated (cumulative) in each country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as PeopleVaccinated_cumulative 
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Make the above a CTE because last column cant be reused for another column
WITH PopVsVac (continent, location, date , population, new_vaccinations, PeopleVaccinated_cumulative)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as PeopleVaccinated_cumulative 
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, PeopleVaccinated_cumulative/(cast(Population as float))*100 as PercentageofPeopleVaccinated_cumulative
FROM PopVsVac


-- Another method of the above query instead of using CTE 
-- Temporary Table
DROP TABLE if exists PercentPopulationVaccinated 
CREATE TABLE PercentPopulationVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    PeopleVaccinated_cumulative numeric
)

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as PeopleVaccinated_cumulative 
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
SELECT *, PeopleVaccinated_cumulative/(cast(Population as float))*100 as PercentageofPeopleVaccinated_cumulative
FROM PercentPopulationVaccinated

DROP TABLE PercentPopulationVaccinated

-- Creating views for visualisation usage
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as PeopleVaccinated_cumulative 
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM PercentPopulationVaccinated
