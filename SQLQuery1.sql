--SELECT *
--FROM PortfolioProject..CovidDeaths
--ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

SELECT location,continent, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
Order by 1,2

-- Looking at Total Cases vs Total Deaths

--SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
--FROM PortfolioProject..CovidDeaths
--Order by 1,2

-- A way around as both column ( Total deaths and total cases) are nvarchar
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths,
    (CAST(total_deaths AS DECIMAL(18, 2)) / CAST(total_cases AS DECIMAL(18, 2))) * 100 AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE location like '%kingdom%'
ORDER BY 
    1, 2;

-- Looking at Total cases vs Population
-- Shows what percentage of population got covid

SELECT 
    location, 
    date, 
	population,
    total_cases, 
    (CAST(total_cases AS DECIMAL(18, 2)) / CAST(population AS DECIMAL(18, 2))) * 100 AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE location like '%kingdom%'
ORDER BY 
    1, 2;


-- Countries with Highest infection rate vs population

SELECT 
    location, 
	population,
    MAX(total_cases) AS HighestInfectionCoiunt,
    MAX((CAST(total_cases AS DECIMAL(18, 2)) / CAST(population AS DECIMAL(18, 2)))) * 100 AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY 
	PercentPopulationInfected desc;

-- Showing continent with highest death count

SELECT 
    continent, 
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY 
	TotalDeathCount desc;

-- Showing countries with highest death count

SELECT 
    location AS Countries, 
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY 
	TotalDeathCount Desc;



-- Globally by death

SELECT 
    date, 
    SUM(new_cases) AS Total_Cases, 
    SUM(CAST(new_deaths AS int)) AS Total_Deaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE SUM(CAST(new_deaths AS int)) * 100.0 / SUM(new_cases)
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 
    1, 2;

-- Looking at total population vs vaccinations

--SELECT dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations , 
--SUM(CAST(vac.new_vaccinations AS INT)) OVER (Partition by dea.location order by dea.location,dea.date)
--FROM PortfolioProject..CovidDeaths dea
--JOIN
--PortfolioProject..CovidVaccinations vac

--	ON dea.location = vac.location
--	and dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT 
    dea.continent, 
    dea.location,
    dea.date,
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS BIGINT)) OVER (Partition by dea.location order by dea.location, dea.date) AS Cumulative_Vaccinations
FROM 
    PortfolioProject..CovidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
ORDER BY 
    2, 3;


-- WITH CTE

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Cummulative_Vaccinations)
AS
(
SELECT 
    dea.continent, 
    dea.location,
    dea.date,
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS BIGINT)) OVER (Partition by dea.location order by dea.location, dea.date) AS Cumulative_Vaccinations
FROM 
    PortfolioProject..CovidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
--ORDER BY 
--    2, 3
)
SELECT *
FROM PopVsVac



-- Temp Table
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
Create Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Cummulative_Vaccinations numeric
)

Insert into #PercentagePopulationVaccinated
SELECT 
    dea.continent, 
    dea.location,
    dea.date,
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS BIGINT)) OVER (Partition by dea.location order by dea.location, dea.date) AS Cumulative_Vaccinations
FROM 
    PortfolioProject..CovidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
	
SELECT *, (Cummulative_Vaccinations/ Population) *100
FROM #PercentagePopulationVaccinated


-- Creating View to store data to use later for visulalisation

Create View PercentagePopulationVaccinated as 
SELECT 
    dea.continent, 
    dea.location,
    dea.date,
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS BIGINT)) OVER (Partition by dea.location order by dea.location, dea.date) AS Cumulative_Vaccinations
FROM 
    PortfolioProject..CovidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL

SELECT *
FROM PercentagePopulationVaccinated