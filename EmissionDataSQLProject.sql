/*

Global Emission Data Exploration
Data source: https://www.kaggle.com/datasets/thedevastator/global-fossil-co2-emissions-by-country-2002-2022?select=GCB2022v27_MtCO2_flat.csv
Credit to: Robbie M. & Glen P. (October, 2022)

Skills used: CTE's, Windows Functions, Aggregate Functions, Converting Data Types, Conditional Function, 
CASE Function, Subqueries, TRY_CAST function

*/

SELECT *
FROM EmissionDataProject..EmissionTotal
ORDER BY 1,2

SELECT * 
FROM EmissionDataProject..EmissionPerCapita
ORDER BY 1,2

--Understanding and exploring the data
EXEC sp_help EmissionTotal

EXEC sp_rename 'EmissionTotal.Total', 'country_total_emission', 'COLUMN'

SELECT *
FROM EmissionDataProject..EmissionTotal
ORDER BY 1,2

SELECT DISTINCT Country
FROM EmissionDataProject..EmissionTotal
Order by country asc

SELECT DISTINCT Country
FROM EmissionDataProject..EmissionPerCapita
Order by country asc

SELECT MAX(Year) AS latest_year, MIN(Year) AS earliest_year
FROM EmissionDataProject..EmissionTotal

--Calculating global CO2 Emission for each year
SELECT Year, SUM(country_total_emission) AS TotalCO2Emissions
FROM EmissionDataProject..EmissionTotal
GROUP BY Year
ORDER BY Year

--Looking at a specific year of a country's total emission
SELECT Country, Year, country_total_emission
FROM EmissionDataProject..EmissionTotal
WHERE Year LIKE '%2020%'
ORDER BY Country ASC


--Finding top 10 countries with highest CO2 emissions in 2021
SELECT Country, Year, country_total_emission
FROM EmissionDataProject..EmissionTotal
WHERE Year LIKE '%2021%'
ORDER BY country_total_emission desc



--Countries with highest CO2 emission in the last 10 years
SELECT TOP 10 Country, SUM(country_total_emission) AS TenYearsTotalEmission
FROM EmissionDataProject..EmissionTotal
WHERE Year BETWEEN 2013 AND 2022
GROUP BY Country
ORDER BY TenYearsTotalEmission DESC


              --Excluding 2 entries from country (Global & International Transport)
                     SELECT TOP 10 Country, SUM(country_total_emission) AS TenYearsTotalEmission
                     FROM EmissionDataProject..EmissionTotal
                     WHERE Year BETWEEN 2013 AND 2022
                             AND Country NOT IN ('Global','International Transport')
                     GROUP BY Country
                     ORDER BY TenYearsTotalEmission DESC



--Calculating average annual CO2 emissions for each country
SELECT Country, AVG(country_total_emission) AS AverageAnnualCO2Emission
FROM EmissionDataProject..EmissionTotal
WHERE Country NOT IN ('Global','International Transport')
GROUP BY Country
ORDER BY AverageAnnualCO2Emission DESC

--Identifying the year with highest global CO2 emission
SELECT TOP 1 Year, MAX(country_total_emission) AS MaxCO2Emissions
FROM EmissionDataProject..EmissionTotal
GROUP BY Year
ORDER BY MaxCO2Emissions DESC


--Calculating percentage contribution of each country to global emission
-- Using CTE
WITH CO2Global (Country, Year, country_total_emission, YearlyCO2Emission)
AS
(
       SELECT country, Year, country_total_emission, SUM(country_total_emission) OVER (PARTITION BY Year) AS YearlyCO2Emission
       FROM EmissionDataProject..EmissionTotal
       WHERE Year BETWEEN 1999 AND 2022
)
SELECT *, (country_total_emission/YearlyCO2Emission)*100 AS PercentageContribution
FROM CO2Global
WHERE Year LIKE '%2021%'
ORDER BY 1,2

--Using aggregation, subqueries and conditional statements
SELECT SUM(country_total_emission) AS YearlyCO2Emissions
FROM EmissionDataProject..EmissionTotal
WHERE Year = (SELECT MAX(Year) FROM EmissionDataProject..EmissionTotal)

       SELECT Country, (country_total_emission / YearlyCO2Emissions) * 100 AS PercentageContribution
       FROM EmissionDataProject..EmissionTotal, (SELECT SUM(country_total_emission) AS YearlyCO2Emissions
                                          FROM EmissionDataProject..EmissionTotal
                                          WHERE Year = (SELECT MAX(Year) FROM EmissionDataProject..EmissionTotal)) AS Global
       WHERE Year = (SELECT MAX(Year) FROM EmissionDataProject..EmissionTotal)
       GROUP BY Country, country_total_emission, YearlyCO2Emissions



--Find the country with the highest increase in CO2 emissions from the earliest to the latest year
SELECT Country, MAX(country_total_emission) - MIN(country_total_emission) AS EmissionsIncrease
FROM 
(
       SELECT Country, country_total_emission, ROW_NUMBER() OVER (PARTITION BY Country ORDER BY Year) AS RowNum
       FROM EmissionDataProject..EmissionTotal
       WHERE Year >= 1999 AND Year <= 2022
) AS T
WHERE RowNum = 1 OR RowNum = (SELECT COUNT(DISTINCT Year) FROM EmissionDataProject..EmissionTotal WHERE Year >= 1999 AND Year <= 2022)
AND Country NOT IN ('Global','International Transport')
GROUP BY Country
ORDER BY EmissionsIncrease DESC

--Finding the major contribution of CO2 emission by country
--Coal/Oil/Gas/Cement/Falring/Other
          SELECT Country, Year,
          CASE
               WHEN [Coal] = MAX([Coal]) OVER (PARTITION BY Year) THEN 'Coal'
               WHEN [Oil] = MAX([Oil]) OVER (PARTITION BY Year) THEN 'Oil'
               WHEN [Gas] = MAX([Gas]) OVER (PARTITION BY Year) THEN 'Gas'
               WHEN [Cement] = MAX([Cement]) OVER (PARTITION BY Year) THEN 'Cement'
               WHEN [Flaring] = MAX([Flaring]) OVER (PARTITION BY Year) THEN 'Flaring'
               ELSE 'Other'
          END AS HighestSourceOfEmission
          FROM EmissionDataProject..EmissionTotal
          WHERE Country LIKE '%Malaysia%'
          ORDER BY Country, Year


          SELECT Country, Year,
          CASE
               WHEN CAST([Coal] AS DECIMAL) >= CAST([Oil] AS DECIMAL) AND
                    CAST([Coal] AS DECIMAL) >= CAST([Gas] AS DECIMAL) AND
                    CAST([Coal] AS DECIMAL) >= CAST([Cement] AS DECIMAL) AND
                    CAST([Coal] AS DECIMAL) >= CAST([Flaring] AS DECIMAL) THEN 'Coal'
               WHEN CAST([Oil] AS DECIMAL) >= CAST([Coal] AS DECIMAL) AND
                    CAST([Oil] AS DECIMAL) >= CAST([Gas] AS DECIMAL) AND
                    CAST([Oil] AS DECIMAL) >= CAST([Cement] AS DECIMAL) AND
                    CAST([Oil] AS DECIMAL) >= CAST([Flaring] AS DECIMAL) THEN 'Oil'
               WHEN CAST([Gas] AS DECIMAL) >= CAST([Coal] AS DECIMAL) AND
                    CAST([Gas] AS DECIMAL) >= CAST([Oil] AS DECIMAL) AND
                    CAST([Gas] AS DECIMAL) >= CAST([Cement] AS DECIMAL) AND
                    CAST([Gas] AS DECIMAL) >= CAST([Flaring] AS DECIMAL) THEN 'Gas'
               WHEN CAST([Cement] AS DECIMAL) >= CAST([Coal] AS DECIMAL) AND
                    CAST([Cement] AS DECIMAL) >= CAST([Oil] AS DECIMAL) AND
                    CAST([Cement] AS DECIMAL) >= CAST([Gas] AS DECIMAL) AND
                    CAST([Cement] AS DECIMAL) >= CAST([Flaring] AS DECIMAL) THEN 'Cement'
               WHEN CAST([Flaring] AS DECIMAL) >= CAST([Coal] AS DECIMAL) AND
                    CAST([Flaring] AS DECIMAL) >= CAST([Oil] AS DECIMAL) AND
                    CAST([Flaring] AS DECIMAL) >= CAST([Gas] AS DECIMAL) AND
                    CAST([Flaring] AS DECIMAL) >= CAST([Cement] AS DECIMAL) THEN 'Flaring'
               ELSE 'Others'
          END AS HighestSourceOfEmission
          FROM EmissionDataProject..EmissionTotal
          ORDER BY Country, Year

--The 2 statements above gives me error while trying to convert the nvarcahr data type to numeric
--I intentionally leaving the code above as part of my learning adventure and future reference

--Code below is looking at the major contributor of CO2 emission in Malaysia
SELECT Country, Year,
    CASE
        WHEN TRY_CAST([Coal] AS DECIMAL) >= TRY_CAST([Oil] AS DECIMAL) AND
             TRY_CAST([Coal] AS DECIMAL) >= TRY_CAST([Gas] AS DECIMAL) AND
             TRY_CAST([Coal] AS DECIMAL) >= TRY_CAST([Cement] AS DECIMAL) AND
             TRY_CAST([Coal] AS DECIMAL) >= TRY_CAST([Flaring] AS DECIMAL) THEN 'Coal'
        WHEN TRY_CAST([Oil] AS DECIMAL) >= TRY_CAST([Coal] AS DECIMAL) AND
             TRY_CAST([Oil] AS DECIMAL) >= TRY_CAST([Gas] AS DECIMAL) AND
             TRY_CAST([Oil] AS DECIMAL) >= TRY_CAST([Cement] AS DECIMAL) AND
             TRY_CAST([Oil] AS DECIMAL) >= TRY_CAST([Flaring] AS DECIMAL) THEN 'Oil'
        WHEN TRY_CAST([Gas] AS DECIMAL) >= TRY_CAST([Coal] AS DECIMAL) AND
             TRY_CAST([Gas] AS DECIMAL) >= TRY_CAST([Oil] AS DECIMAL) AND
             TRY_CAST([Gas] AS DECIMAL) >= TRY_CAST([Cement] AS DECIMAL) AND
             TRY_CAST([Gas] AS DECIMAL) >= TRY_CAST([Flaring] AS DECIMAL) THEN 'Gas'
        WHEN TRY_CAST([Cement] AS DECIMAL) >= TRY_CAST([Coal] AS DECIMAL) AND
             TRY_CAST([Cement] AS DECIMAL) >= TRY_CAST([Oil] AS DECIMAL) AND
             TRY_CAST([Cement] AS DECIMAL) >= TRY_CAST([Gas] AS DECIMAL) AND
             TRY_CAST([Cement] AS DECIMAL) >= TRY_CAST([Flaring] AS DECIMAL) THEN 'Cement'
        WHEN TRY_CAST([Flaring] AS DECIMAL) >= TRY_CAST([Coal] AS DECIMAL) AND
             TRY_CAST([Flaring] AS DECIMAL) >= TRY_CAST([Oil] AS DECIMAL) AND
             TRY_CAST([Flaring] AS DECIMAL) >= TRY_CAST([Gas] AS DECIMAL) AND
             TRY_CAST([Flaring] AS DECIMAL) >= TRY_CAST([Cement] AS DECIMAL) THEN 'Flaring'
        ELSE 'Others'
    END AS HighestSourceOfEmission
FROM EmissionDataProject..EmissionTotal
WHERE Country LIKE '%Malaysia%'
ORDER BY Country, Year
