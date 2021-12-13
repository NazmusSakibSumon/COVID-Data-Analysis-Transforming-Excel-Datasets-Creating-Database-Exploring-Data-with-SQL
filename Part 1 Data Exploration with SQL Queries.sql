/* 

COVID Data Exploration

We will use Joins, CTE's, Temporary tables, Window Functions, Aggregate functions 
to explore the data

*/

-- Lets take a look into our two tables

SELECT *
FROM [COVID Project].[dbo].[CovidDeaths$]
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM [COVID Project].[dbo].[CovidVaccinations$]
WHERE continent IS NOT NULL
ORDER BY 3,4


/*Firstly we will focus on COVID Death table*/
--We will choose the columns that we will work with

SELECT location,
       date,
       total_cases,
       new_cases,
       total_deaths,
       population
FROM   [COVID Project].[dbo].[coviddeaths$]
WHERE  continent IS NOT NULL
ORDER  BY 1,
          2 

/*
We will only focus on the United States Data.

Now we will calculate the death percentage by dividing the total deaths with 
total cases by country and date
*/

SELECT location,
       date,
       total_cases,
       total_deaths,
       ( total_deaths / total_cases ) * 100 AS Death_Percentage
FROM   [COVID Project].[dbo].[coviddeaths$]
WHERE  location LIKE '%states%'
       AND continent IS NOT NULL
ORDER  BY 1,
          2 

--Total Cases VS Total Population
--This will show us the percentage of population infected with COVID.
--We will look into all the countries.

SELECT location,
       date,
       population,
       total_cases,
       ( total_cases / population ) * 100 AS PercentPopulationInfected
FROM   [COVID Project].[dbo].[coviddeaths$]
ORDER  BY 1,
          2 


--Countries with Highest Infection Rate Compared To Population

SELECT location,
       population,
       Max(total_cases)                        AS HighestInfectionCount,
       Max(( total_cases / population ) * 100) AS PercentPopulationInfected
FROM   [COVID Project].[dbo].[coviddeaths$]
GROUP  BY location,
          population
ORDER  BY percentpopulationinfected DESC 


--Countries with highest Death Count per population

SELECT location,
       Max(Cast(total_deaths AS INT)) AS TotalDeathCount
FROM   [COVID Project].[dbo].[coviddeaths$]
WHERE  continent IS NOT NULL
GROUP  BY location
ORDER  BY totaldeathcount DESC 


/*Let us Break Things down by Continent*/

--We will sort the continents with the highest death count per population.

SELECT continent,
       Max(Cast(total_deaths AS INT)) AS TotalDeathCount
FROM   [COVID Project].[dbo].[coviddeaths$]
WHERE  continent IS NOT NULL
GROUP  BY location
ORDER  BY totaldeathcount DESC 


--Global Numbers

SELECT Sum(new_cases)                                      AS total_cases,
       Sum(Cast(new_deaths AS INT))                        AS total_deaths,
       Sum(Cast(new_deaths AS INT)) / Sum(new_cases) * 100 AS DeathPercentage
FROM   [COVID Project].[dbo].[coviddeaths$]
WHERE  continent IS NOT NULL
ORDER  BY 1,
          2 


-- Total Population VS Vaccinations
-- We will show percentage of population that has received at least one Covid Vaccine

SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       Sum(CONVERT(INT, vac.new_vaccinations))
         OVER (
           partition BY dea.location
           ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM   [COVID Project].[dbo].[coviddeaths$] dea
       JOIN [COVID Project].[dbo].[covidvaccinations$] vac
         ON dea.location = vac.location
            AND dea.date = vac.date
WHERE  dea.continent IS NOT NULL
ORDER  BY 2,
          3 


-- We will use CTE in the Previous query.

WITH populationvsvaccine (continent, location, date, population,
     new_vaccinations,
     rollingpeoplevaccinated)
     AS (SELECT dea.continent,
                dea.location,
                dea.date,
                dea.population,
                vac.new_vaccinations,
                Sum(CONVERT(INT, vac.new_vaccinations))
                  OVER (
                    partition BY dea.location
                    ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
         FROM   [COVID Project].[dbo].[coviddeaths$] dea
                JOIN [COVID Project].[dbo].[covidvaccinations$] vac
                  ON dea.location = vac.location
                     AND dea.date = vac.date
         WHERE  dea.continent IS NOT NULL)
SELECT *,
       ( rollingpeoplevaccinated / population ) * 100
FROM   populationvsvaccine 


--We will use Temp table in the Previous query.

DROP TABLE IF EXISTS #percentpopulationvaccinated
CREATE TABLE #percentpopulationvaccinated
             (
                          continent               nvarchar(255),
                          location                nvarchar(255),
                                                  date datetime,
                          population              numeric,
                          new_vaccinations        numeric,
                          rollingpeoplevaccinated numeric
             )
INSERT INTO #percentpopulationvaccinated
SELECT   dea.continent,
         dea.location,
         dea.date,
         dea.population,
         vac.new_vaccinations ,
         Sum(CONVERT(INT, vac.new_vaccinations)) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM     [COVID Project].[dbo].[coviddeaths$] dea
JOIN     [COVID Project].[dbo].[covidvaccinations$] vac
ON       dea.location = vac.location
AND      dea.date = vac.date
SELECT *,
       (rollingpeoplevaccinated/population)*100
FROM   #percentpopulationvaccinated


-- In the next sql script, we will create a view to use for the visualizations

