-- Altering Date Format

select SaleDate, CONVERT(date, SaleDate)
from PortfolioProject.dbo.NashvilleHousing

Update PortfolioProject..NashvilleHousing
Set SaleDate = CONVERT(date, SaleDate)

Alter Table PortfolioProject..NashvilleHousing
Add SaleDateConverted Date

Update PortfolioProject..NashvilleHousing
Set SaleDateConverted = Convert(date,SaleDate)

Select SaleDateConverted
from PortfolioProject..NashvilleHousing


--Propery Address data

Select *
from PortfolioProject..NashvilleHousing
--where PropertyAddress is null
order by ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


-- Splitting Property Address into three columns (Address, City, State)

Select PropertyAddress
from PortfolioProject..NashvilleHousing
--where PropertyAddress is null
--order by ParcelID

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',propertyaddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',propertyaddress) +1, LEN(propertyaddress)) as City

From PortfolioProject..NashvilleHousing


Alter Table PortfolioProject..NashvilleHousing
Add PropertySplitAddress nvarchar(255)

Update PortfolioProject..NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',propertyaddress) -1)

Alter Table PortfolioProject..NashvilleHousing
Add PropertySplitCity nvarchar(255)

Update PortfolioProject..NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',propertyaddress) +1, LEN(propertyaddress))


Select *
from PortfolioProject..NashvilleHousing


-- Splitting Owner Address into three columns (different from the action above)

Select OwnerAddress
from PortfolioProject..NashvilleHousing

select PARSENAME(REPLACE(owneraddress, ',','.'), 3),
	   PARSENAME(REPLACE(owneraddress, ',','.'), 2),
	   PARSENAME(REPLACE(owneraddress, ',','.'), 1)
from PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(owneraddress, ',','.'), 3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(owneraddress, ',','.'), 2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(owneraddress, ',','.'), 1)


-- Change Y and N to 'Yes' and 'No' in SoldAsVacant column

Select distinct(SoldAsVacant), COUNT(soldasvacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 1, 2

Select SoldAsVacant,
	   case when SoldAsVacant = 'Y' then 'Yes'
			when SoldAsVacant = 'N' then 'No'
			Else SoldAsVacant
			End

From PortfolioProject..NashvilleHousing

update PortfolioProject..NashvilleHousing
SET SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
			when SoldAsVacant = 'N' then 'No'
			Else SoldAsVacant
			End


-- Removing Duplicates

WITH RowNumCTE as (
Select *,
	ROW_NUMBER() OVER(
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 Legalreference
				 ORDER BY UniqueID) row_num

From PortfolioProject..NashvilleHousing
--order by ParcelID
)

Select *
From RowNumCTE
Where row_num > 1
order by PropertyAddress


-- Delete unused Columns

Select *
From PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict,PropertyAddress, SaleDate
