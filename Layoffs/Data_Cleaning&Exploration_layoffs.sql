-- Data Cleaning
SELECT * 
FROM layoffs 
LIMIT 3;

-- Creating duplicate table so raw table will not be touched
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging 
SELECT * 
FROM layoffs;




-- 1. Removing Duplicates

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) as row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Checking if the output are really duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Creating a new table because I cant delete from the cte
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) as row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num>1;






-- 2. Standardising the Data

-- Notice 2nd row in company column has extra spacing
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Location
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY location;

-- Industry
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;		-- Notice there is Crypto ,Crypto Currency,CryptoCurrency which should all be the same

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Country
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;		-- Notice there is a period at the end of United States

SELECT *
FROM layoffs_staging2
WHERE country = 'United States.';

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States.';

-- Date
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- total_laid_off
SELECT DISTINCT total_laid_off
FROM layoffs_staging2
ORDER BY total_laid_off;	

-- percentage_laid_off
SELECT DISTINCT percentage_laid_off
FROM layoffs_staging2
ORDER BY percentage_laid_off;

-- stage
SELECT DISTINCT stage
FROM layoffs_staging2
ORDER BY stage;

-- funds_raised_millions
SELECT DISTINCT funds_raised_millions
FROM layoffs_staging2
ORDER BY funds_raised_millions;






-- 3. Dealing with NULL and Blank values

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Checking if can populate null or blank values
SELECT *
FROM layoffs_staging2 
WHERE company = 'Airbnb';

SELECT table1.industry, table2.industry
FROM layoffs_staging2 table1
JOIN layoffs_staging2 table2
ON table1.company = table2.company AND table1.location = table2.location
WHERE (table1.industry IS NULL OR table1.industry = '') AND table2.industry IS NOT NULL;

-- Setting blanks to nulls
UPDATE layoffs_Staging2
SET industry = NULL 
WHERE industry = '';

-- Populating
UPDATE layoffs_staging2 table1
JOIN layoffs_staging2 table2
ON table1.company = table2.company AND table1.location = table2.location
SET table1.industry = table2.industry
WHERE (table1.industry IS NULL OR table1.industry = '') AND table2.industry IS NOT NULL;

-- Checking if there is still NULL values in industry column
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL;

SELECT * 
FROM layoffs_staging2
WHERE company LIKE 'Bally%';		-- Only one row so cant populate the null

-- Other columns cannot populate the null values


-- 4. Removing some columns and rows

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2 
LIMIT 5;


-- Exploratory Data Analysis

SELECT MAX(total_laid_off)
FROM layoffs_staging2;

-- Looking at Percentage to see how big these layoffs were
SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM layoffs_staging2
WHERE  percentage_laid_off IS NOT NULL;

-- Companies that laid off 100% of staff
SELECT *
FROM layoffs_staging2
WHERE  percentage_laid_off = 1;
-- these are mostly startups it looks like who all went out of business during this time
-- if we order by funcs_raised_millions we can see how big some of these companies were
SELECT *
FROM layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


-- Companies with the biggest single Layoff (single day)
SELECT company, total_laid_off
FROM layoffs_staging
ORDER BY 2 DESC
LIMIT 5;

-- Companies with the most Total Layoffs
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;
-- Google probably laid off all at one time because the SUM is 12000 which is the MAX(layoff)


-- by location
SELECT location, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- by year
SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC;

-- by year (Singapore)
SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
WHERE country = 'Singapore'
GROUP BY YEAR(date)
ORDER BY 1 ASC;

-- by industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- by stage
SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


-- Rolling Total of Layoffs Per Month
SELECT SUBSTRING(`date`,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY dates
ORDER BY dates ASC;

-- now use it in a CTE so we can query off of it
WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, total_laid_off, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;


-- Top 5 companies that had the highest layoffs per year
WITH Company_Year_CTE AS 
(
  SELECT company, YEAR(`date`) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank_CTE AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year_CTE
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank_CTE
WHERE ranking <= 5
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;























