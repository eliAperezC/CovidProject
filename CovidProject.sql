USE PortfolioProject

SELECT * FROM PortfolioProject..CovidDeaths ORDER BY 3,4

--SELECT * FROM PortfolioProject..CovidVaccinations ORDER BY 3,4

--DATOS QUE SE USARÁN

SELECT location, date, total_cases, new_cases, total_deaths, population FROM PortfolioProject..CovidDeaths ORDER BY 1,2

--TOTAL DE CASOS VS TOTAL DE MUERTES

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths 
--WHERE location LIKE '%mexico' 
ORDER BY 1,2

--TOTAL DE CASOS VS POBLACIÓN

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPercentage 
FROM PortfolioProject..CovidDeaths 
--WHERE location LIKE '%mexico' 
ORDER BY 1,2

--PAISES CON MAYOR PORCENTAJE DE POBLACION INFECTADA

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage 
FROM PortfolioProject..CovidDeaths 
GROUP BY location, population
ORDER BY InfectedPercentage DESC

--PAISES CON LA MAYAR CANTIDAD DE MUERTES

--SE CASTEAN LOS CASOS TOTALES A INT DEBIDO A QUE SE ENCONTRABAN EN NVARCHAR
SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL --EVITA QUE SE MUESTREN LOS CONTINENTES REGISTRADOS
GROUP BY location
ORDER BY TotalDeathCount DESC

--SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
--FROM PortfolioProject..CovidDeaths
--WHERE continent IS NULL
--GROUP BY location
--ORDER BY TotalDeathCount DESC

--MUERTES POR CONTINENTE

SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--CASOS, MUERTES Y PORCENTAJE DE MUERTE POR DIA

SELECT date,SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS INT)) AS TotalDeaths, 
SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--NUMEROS GLOBALES

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS INT)) AS TotalDeaths, 
SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- POBLACION VS VACUNAS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--CTE

WITH PopVSVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageVaccinated
FROM PopVSVac

--TABLA TEMPORAL

--DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated(
	continent NVARCHAR(255),
	location NVARCHAR(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	RollingPeopleVaccinated NUMERIC)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageVaccinated
FROM #PercentPopulationVaccinated

-- VISTA PARA USAR EN TABLEAU

CREATE VIEW PercentPopulationVaccinated AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3

SELECT * FROM PercentPopulationVaccinated