CREATE SCHEMA DW
CREATE TABLE DW.Dim_Location (
    LocationID smallint PRIMARY KEY,
    LocationName nvarchar(50),
    CostRate money,
    Availability decimal(8, 2) ,
    StartDate datetime,
    EndDate datetime
);
go
CREATE TABLE DW.Dim_Product (
  ProductID int PRIMARY KEY,
  ProductName nvarchar(50) NOT NULL,
  ProductNumber nvarchar(25) NOT NULL,
  MakeFlag bit,
  FinishedGoodsFlag bit NOT NULL,
  Color nvarchar(15),
  SafetyStockLevel smallint NOT NULL,
  ReorderPoint smallint NOT NULL,
  StandardCost money NOT NULL,
  ListPrice money NOT NULL,
  Size nvarchar(5) DEFAULT NULL,
  SizeUnitMeasureCode nchar(3) DEFAULT NULL,
  WeightUnitMeasureCode nchar(3) DEFAULT NULL,
  Weight decimal(8, 2),
  DaysToManufacture int,
  ProductLine nchar(2),
  Class nchar(2),
  Style nchar(2),
  ProductSubcategoryID int,
  ProductSubCategoryName nvarchar(50),
  ProductCategoryID int,
  ProductCategoryName nvarchar(50),
  ProductModelID int,
  SellStartDate datetime,
  SellEndDate datetime,
  DiscontinuedDate datetime,
  StartDate datetime,
    EndDate datetime,

  UNIQUE (ProductNumber) -- Ensures unique product numbers
);
go
-- Create Dim_ScrapReason table
CREATE TABLE DW.Dim_ScrapReason (
  ScrapReasonID smallint PRIMARY KEY,
  ScrapReasonName nvarchar(50) NOT NULL,
  StartDate datetime,
  EndDate datetime
);
go

/****** Object:  Table [dw].[DimTime]    Script Date: 03/07/2024 12:25:07 AM ******/
DROP TABLE IF EXISTS dw.DimTime;
DECLARE @StartDate date = '20110101';
DECLARE @Year int = 4;
DECLARE @CutoffDate date = DATEADD(DAY, -1, DATEADD(YEAR, @Year, @StartDate));

;WITH seq(n) AS 
(
  SELECT 0 UNION ALL SELECT n + 1 FROM seq
  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
),
d(d) AS 
(
  SELECT DATEADD(DAY, n, @StartDate) FROM seq
),
src AS
(
  SELECT
    DateKey         	= CONVERT(datetime, d),
    TheDay         		= DATEPART(DAY,       d),
    TheDayName      	= DATENAME(WEEKDAY,   d),
    TheWeek         	= DATEPART(WEEK,      d),
    TheISOWeek      	= DATEPART(ISO_WEEK,  d),
    TheDayOfWeek    	= DATEPART(WEEKDAY,   d),
    TheMonth        	= DATEPART(MONTH,     d),
    TheMonthName    	= DATENAME(MONTH,     d),
    TheQuarter      	= DATEPART(Quarter,   d),
    TheYear         	= DATEPART(YEAR,      d),
    TheFirstOfMonth 	= DATEFROMPARTS(YEAR(d), MONTH(d), 1),
    TheLastOfYear   	= DATEFROMPARTS(YEAR(d), 12, 31),
    TheDayOfYear    	= DATEPART(DAYOFYEAR, d)
  FROM d
)


SELECT * 
INTO dw.DimTime 
FROM src
ORDER BY DateKey
OPTION (MAXRECURSION 0)
GO


-- Create Fact_Manufacturing table
CREATE TABLE DW.Fact_Manufacturing (
    WorkOrderID int,
    ProductID int,
    OrderQty int,
    StockedQty int,
    ScrappedQty smallint,
    ScrapReasonID smallint,
    OperationSequence smallint,
    LocationID smallint,
    ScheduledStartDate datetime,
    ScheduledEndDate datetime,
    ActualStartDate datetime,
    ActualEndDate datetime,
    ActualResourceHrs decimal(9,4),
    PlannedCost money,
    ActualCost money,
    PRIMARY KEY (WorkOrderID) 
	-- Assuming WorkOrderID is the primary key
);

SELECT 
	w.WorkOrderID,
	w.ProductID,
	w.ScrapReasonID,
	wr.LocationID,
	w.OrderQty,
	w.StockedQty,
	w.ScrappedQty,
                   wr.OperationSequence,
	wr.ScheduledStartDate,
	wr.ScheduledEndDate,
	wr.ActualStartDate,
	wr.ActualEndDate,
	wr.ActualResourceHrs,
	wr.PlannedCost,
	wr.ActualCost
FROM Production.WorkOrder as w
LEFT JOIN Production.WorkOrderRouting as wr
on w.WorkOrderID = wr.WorkOrderID
