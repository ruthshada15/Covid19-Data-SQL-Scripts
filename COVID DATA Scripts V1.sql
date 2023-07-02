SELECT * FROM PortfolioProject1..CovidDeaths
ORDER BY 3,4

SELECT * FROM PortfolioProject1..CovidVaccinations
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDeaths
ORDER BY 1,2

-- Total Cases and Deaths by country

SELECT location, 
MAX(CAST(total_cases AS int)) AS AllCases, 
MAX(CAST(total_deaths AS int)) AS AllDeaths, 
MAX(CAST(total_deaths AS int))*100 /MAX(CAST(total_cases AS float)) AS DeathsPercent
FROM PortfolioProject1..CovidDeaths
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY location

-- Looking at the total cases vs total deaths
-- Shows the likelihood of dying if you contract covid in your country day by day
SELECT location, date, total_cases, total_deaths, 
(CAST(total_deaths AS int)/CAST(total_cases AS float))*100 AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE location like '%Re%Congo%' --Precision the location to DRC
ORDER BY 1,2

--Looking at Total Cases vs Population
-- Looking at total cases vs population
-- Shows what % of population got covid

SELECT location, date, population, total_cases, 
(CAST(total_cases AS int)/population)*100 AS CovidPercentage
FROM PortfolioProject1..CovidDeaths
WHERE location like '%Re%Congo%' --Precise the location to DRC
ORDER BY 1,2

-- Looking at Total cases vs deaths vs population 
-- Show what % of population died from covid

SELECT location, date, population, total_cases, total_deaths, 
(CAST(total_deaths AS int)/population)*100 AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE location like '%Re%Congo%' --Precise the location to DRC
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population

SELECT location, population, 
MAX(CAST(total_cases AS int)) AS TotalCasesBycountry, 
MAX(CAST(total_cases AS int)/population)*100 AS InfectionRate
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionRate DESC

--Pulling all data from Covid Deaths Table excluding groupings of continents and living only countries

SELECT * FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

-- Showing Countries with the highest death count per population

SELECT location,  
MAX(CAST(total_deaths AS int)) AS TotalDeathsBycountry, 
MAX(CAST(total_deaths AS int)/population)*100 AS DeathRate
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathsBycountry DESC

-- Let's break thing down by continent

SELECT continent,  
MAX(CAST(total_deaths AS int)) AS TotalDeathsBycountry, 
MAX(CAST(total_deaths AS int)/population)*100 AS DeathRate
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathsBycountry DESC 
-- less accurate

SELECT location,  
MAX(CAST(total_deaths AS int)) AS TotalDeathsBycountry, 
MAX(CAST(total_deaths AS int)/population)*100 AS DeathRate
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathsBycountry DESC
--more accurate


--Global numbers

SELECT date, 
SUM(new_cases) AS TotalCasesPerDay,
SUM(new_deaths) AS TotalDeathsPerDay
--(SUM(new_deaths)/SUM(CAST(new_cases AS int)))*100 AS DeathPercentPerDay -- DIVIDE BY ZERO ERROR, FAULTY DATA
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1, 2

SELECT * 
FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location AND dea.date = vac.date

-- Looking at Total Population vs Vaccinations

SELECT dea.location, MAX(CAST(dea.population AS bigint)) AS Population,  MAX(CAST(vac.total_vaccinations AS bigint)) AS TotalVaccinations
FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL

 GROUP BY dea.location
 ORDER BY dea.location

 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, vac.total_vaccinations
 FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 ORDER BY 2,3 --does almost the same as next query but here the total vaccinations are off; check comparison with next query

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount,
 vac.total_vaccinations
 FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 ORDER BY 2,3

 --CREATE A CTE FOR CALCULATIONS

 WITH CTE_PopvsVac (Continent, Location, Date, Population, New_Vaccinantions, VaccinationRollingCount)
 AS
 (
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
 FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 )
 SELECT * , (VaccinationRollingCount/Population)*100 AS VacPercent
 FROM CTE_PopvsVac
;

 -- Looking at the max vaccination percentage per country
 WITH CTE_MaxVax (Location, Population, TotalVaccRolling )
 AS
 (
 SELECT dea.location, dea.population, 
 SUM(CONVERT(bigint, vac.new_vaccinations)) AS TotalVaccRolling
 FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location 
 WHERE dea.continent IS NOT NULL
 GROUP BY dea.location, dea.population
 )
 SELECT *, 
 SUM(TotalVaccRolling) OVER (PARTITION BY Location) AS TotalVax,
 (SUM(TotalVaccRolling) OVER (PARTITION BY Location)/Population)*100 AS MaxPercent
 FROM CTE_MaxVax
 ; --The above not working, giving astronomical numbers


 WITH CTE_PopvsVac (Continent, Location, Date, Population, New_Vaccinantions, VaccinationRollingCount)
 AS
 (
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
 FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 )
 SELECT Location, Population, 
 MAX(VaccinationRollingCount) AS MaxVax,
 (MAX(VaccinationRollingCount) / Population)*100 AS VaxPercent
 FROM CTE_PopvsVac
 GROUP BY Location, Population
 ORDER BY 4 DESC

 ;

 WITH CTE_PopvsVac (Continent, Location, Date, Population, New_Vaccinantions, TotalVaccinations)
 AS
 (
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
--SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
vac.total_vaccinations
 FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 )
 SELECT Location, Population, 
 MAX(TotalVaccinations) AS MaxVax,
 (MAX(TotalVaccinations) / Population)*100 AS VaxPercent
 FROM CTE_PopvsVac
 GROUP BY Location, Population
 ORDER BY 4 DESC
;


-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVax
CREATE TABLE #PercentPopulationVax
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
VaccinationRollingCount numeric
)

INSERT INTO #PercentPopulationVax
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
 FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL


 SELECT * , (VaccinationRollingCount/Population)*100 AS VacPercent
 FROM #PercentPopulationVax
;

-- CREATING VIEW TO STORE DAT FOR LATER VISUALIZATIONS
CREATE VIEW PercentPopulationVax AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
 FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
 ON dea.location = vac.location AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL


 SELECT * FROM PercentPopulationVax

