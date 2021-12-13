-- We will create a view to store data for later visualizations

--DROP VIEW IF EXISTS percentpopulationvaccinated
CREATE VIEW percentpopulationvaccinated
AS
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