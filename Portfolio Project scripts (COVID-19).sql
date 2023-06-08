-- Selecting data that we are going to use
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1, 2

/* Looking at Total Cases vs Total Deaths,
   Shows the likeliihood of dying if contracted in Georgia */
select location,
	   date,
	   total_cases,
	   total_deaths,
	  (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
Where location like '%Georgia'
order by 1, 2

/* Looking at the Total Cases vs Population,
   Shows percentage of population infected in Georgia */
select location, 
	   date,
	   population,
	   total_cases,
	   (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
Where location like '%Georgia'
order by 1, 2

-- Looking at countries with highest infection rate compared to population

select location,
	   population,
	   max(total_cases) as HighestInfectionCount,
	   MAX((total_cases/population)*100) as InfectionPercentage
from PortfolioProject.dbo.CovidDeaths
--Where location like '%Georgia'
Group by location, population
order by InfectionPercentage desc


-- Countries with highest death count per population

select location,
	   MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null -- Solved the location column showing continent name values where continent column values are null
group by location
order by TotalDeathCount desc

-- Breaking down by continent

select location,
	   MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is null and 
	  location not in ('Upper middle income','Lower middle income','Low income','High income') -- Eliminated the inappropriate data
group by location
order by TotalDeathCount desc

-- Global Numbers

select date,
	   SUM(new_cases) as Total_Cases,
	   SUM(new_deaths) as Total_Deaths,
	   SUM(new_deaths)/SUM(new_cases) * 100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
where continent is not null and 
	  new_cases > 0 --To avoid divide by zero error
group by date
order by 1, 2


-- Looking at Total Population vs Vaccinations

Select dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(Convert(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Vaccination numbers in Georgia by date

select dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations,
	   sum(convert(float,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Inner Join PortfolioProject..CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null and dea.location = 'Georgia'
order by 2, 3

-- USE CTE for global vaccination numbers

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as (
select dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations,
	   sum(convert(float,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Inner Join PortfolioProject..CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
)
Select * , (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Creating and using TEMP TABLE

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations,
	   sum(convert(float,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Inner Join PortfolioProject..CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date

Select * ,
	   (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later use

Drop view if exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
select dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations,
	   sum(convert(float,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Inner Join PortfolioProject..CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

Select *
From PercentPopulationVaccinated