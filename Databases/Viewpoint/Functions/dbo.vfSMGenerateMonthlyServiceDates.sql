SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/14/12
-- Description:	Returns the next generated service date
-- =============================================
CREATE FUNCTION [dbo].[vfSMGenerateMonthlyServiceDates]
(	
	@EffectiveDate bDate,
	@ExpirationDate bDate,
	@MonthlyType tinyint,
	@MonthlyDay tinyint,
	@MonthlyDayEveryMonths tinyint,
	@MonthlyEveryOrdinal tinyint,
	@MonthlyEveryDay tinyint,
	@MonthlyEveryMonths tinyint,
	@MonthlySelectOrdinal tinyint,
	@MonthlySelectDay tinyint,
	@MonthlyJan bYN,
	@MonthlyFeb bYN,
	@MonthlyMar bYN,
	@MonthlyApr bYN,
	@MonthlyMay bYN,
	@MonthlyJun bYN,
	@MonthlyJul bYN,
	@MonthlyAug bYN,
	@MonthlySep bYN,
	@MonthlyOct bYN,
	@MonthlyNov bYN,
	@MonthlyDec bYN
)
RETURNS TABLE
AS
RETURN
(
	WITH EffectiveDateParts_CTE
	AS
	(
		SELECT MONTH(@EffectiveDate) EffectiveDateMonth, YEAR(@EffectiveDate) EffectiveDateYear
	),
	ServiceDateForEffectiveDateMonth_CTE
	AS
	(
		--Generate the service date for the effective date month. The date generated may be before the effective date.
		SELECT 
			CASE @MonthlyType 
				WHEN 1 THEN dbo.vfDateCreate(EffectiveDateMonth, @MonthlyDay, EffectiveDateYear)
				WHEN 2 THEN dbo.vfDateCreateFromDayType(EffectiveDateMonth, EffectiveDateYear, @MonthlyEveryOrdinal, @MonthlyEveryDay)
				WHEN 3 THEN dbo.vfDateCreateFromDayType(EffectiveDateMonth, EffectiveDateYear, @MonthlySelectOrdinal, @MonthlySelectDay)
			END ServiceDateForEffectiveDateMonth
		FROM EffectiveDateParts_CTE
	),
	FirstServiceDateMonth_CTE
	AS
	(
		--If the date generated is before the effective date then a month is added.
		SELECT 
			CASE 
				WHEN ServiceDateForEffectiveDateMonth < @EffectiveDate THEN DATEADD(m, 1, ServiceDateForEffectiveDateMonth)
				ELSE ServiceDateForEffectiveDateMonth
			END FirstServiceDateMonth
		FROM ServiceDateForEffectiveDateMonth_CTE
	),
	--Recursive CTE
	GenerateMonths_CTE
	AS
	(
		--Generate all the months between the effective and expiration dates
		SELECT FirstServiceDateMonth ServiceDateMonth
		FROM FirstServiceDateMonth_CTE
		UNION ALL
		--For types 1 and 2 space the months out as specificed. For type 3 generate every month and filter the months not needed later.
		SELECT DATEADD(m, CASE @MonthlyType WHEN 1 THEN @MonthlyDayEveryMonths WHEN 2 THEN @MonthlyEveryMonths WHEN 3 THEN 1 END, ServiceDateMonth)
		FROM GenerateMonths_CTE
		WHERE ServiceDateMonth <= @ExpirationDate
	),
	GenerateMonthParts_CTE
	AS
	(
		--Split the month parts out
		SELECT MONTH(ServiceDateMonth) ServiceDateMonthPart, YEAR(ServiceDateMonth) ServiceDateYearPart
		FROM GenerateMonths_CTE
	),
	GenerateType1ServiceDates_CTE
	AS
	(
		--Using the months work will be done build the specific date work will be done.
		SELECT dbo.vfDateCreate(ServiceDateMonthPart, @MonthlyDay, ServiceDateYearPart) ServiceDate
		FROM GenerateMonthParts_CTE
	),
	GenerateType2ServiceDates_CTE
	AS
	(
		--Using the months work will be done build the specific date work will be done.
		SELECT dbo.vfDateCreateFromDayType(ServiceDateMonthPart, ServiceDateYearPart, @MonthlyEveryOrdinal, @MonthlyEveryDay) ServiceDate
		FROM GenerateMonthParts_CTE
	),
	SelectedMonths_CTE
	AS
	(
		SELECT [Month]
		FROM
		(
			SELECT @MonthlyJan DoWork, 1 [Month]
			UNION ALL
			SELECT @MonthlyFeb, 2
			UNION ALL
			SELECT @MonthlyMar, 3
			UNION ALL
			SELECT @MonthlyApr, 4
			UNION ALL
			SELECT @MonthlyMay, 5
			UNION ALL
			SELECT @MonthlyJun, 6
			UNION ALL
			SELECT @MonthlyJul, 7
			UNION ALL
			SELECT @MonthlyAug, 8
			UNION ALL
			SELECT @MonthlySep, 9
			UNION ALL
			SELECT @MonthlyOct, 10
			UNION ALL
			SELECT @MonthlyNov, 11
			UNION ALL
			SELECT @MonthlyDec, 12
		) SelectedMonths
		WHERE DoWork = 'Y'
	),
	GenerateType3ServiceDates_CTE
	AS
	(
		--Filter out the dates that aren't for a month picked and build out the specific dates work will be done.
		SELECT dbo.vfDateCreateFromDayType(ServiceDateMonthPart, ServiceDateYearPart, @MonthlySelectOrdinal, @MonthlySelectDay) ServiceDate
		FROM GenerateMonthParts_CTE
			INNER JOIN SelectedMonths_CTE ON ServiceDateMonthPart = SelectedMonths_CTE.[Month]
	),
	GenerateServiceDates_CTE
	AS
	(
		SELECT ServiceDate
		FROM GenerateType1ServiceDates_CTE
		WHERE @MonthlyType = 1
		UNION ALL
		SELECT ServiceDate
		FROM GenerateType2ServiceDates_CTE
		WHERE @MonthlyType = 2
		UNION ALL
		SELECT ServiceDate
		FROM GenerateType3ServiceDates_CTE
		WHERE @MonthlyType = 3
	)
	SELECT *
	FROM GenerateServiceDates_CTE
	WHERE ServiceDate <= @ExpirationDate
)
GO
GRANT SELECT ON  [dbo].[vfSMGenerateMonthlyServiceDates] TO [public]
GO
