/* 
Cleaning Data using SQL
*/

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing

----------------------------------------------------------------------------------------------------------------
-- Standardising Date Format

-- I do not want the SaleDate to be DateTime format, just Date
SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add SaleDateConverted Date

UPDATE PortfolioProject.dbo.NashvilleHousing 
SET SaleDateConverted = CONVERT(Date,SaleDate)

----------------------------------------------------------------------------------------------------------------
-- Populate Property Address data as there are null values
SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID

/* 
Notice that for the same parcel ID, the PropertyAddress is the same, so I want to populate those propertyaddress with null values
with those whose parcalid is the same and propertyaddress is not null
*/

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b 
ON a.ParcelID = b.ParcelID AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Use ISNULL to populate
UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b 
ON a.ParcelID = b.ParcelID AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Run again to check if it is now empty 
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b 
ON a.ParcelID = b.ParcelID AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL


----------------------------------------------------------------------------------------------------------------
-- Breaking out PropertyAddress into Indivudual Columns (Address, City) using SUBSTRING
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD 
PropertySplitAddress NVARCHAR(255),
PropertySplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET 
PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) 

-- Breaking out OwnerAddress into Individual Columns (Address, City, State) using PARSENAME
SELECT TOP 10 OwnerAddress FROM NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD 
OwnerSplitAddress NVARCHAR(255),
OwnerSplitCity NVARCHAR(255),
OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
SET 
OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)


----------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in 'Sold as Vacant'
SELECT DISTINCT(SoldAsVacant) 
FROM PortfolioProject.dbo.NashvilleHousing

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes' 
     WHEN SoldAsVacant = 'N' THEN 'No'
     ELSE SoldAsVacant
     END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes' 
                        WHEN SoldAsVacant = 'N' THEN 'No'
                        ELSE SoldAsVacant
                        END

----------------------------------------------------------------------------------------------------------------
-- Remove Duplicates (not used on raw data in practice)
WITH RowNumCTE AS(
SELECT *,
ROW_NUMBER() OVER (             
    PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference     -- Differentiators
    ORDER BY UniqueID
) as row_num
FROM PortfolioProject.dbo.NashvilleHousing
-- ORDER BY ParcelID
)
--SELECT * 
DELETE
FROM RowNumCTE
WHERE row_num > 1               -- >1 represents rows that are duplicates
--ORDER BY PropertyAddress



