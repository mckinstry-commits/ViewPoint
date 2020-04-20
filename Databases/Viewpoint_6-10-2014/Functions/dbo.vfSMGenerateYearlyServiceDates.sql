SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/14/12
-- Description:	Returns the next generated service date
-- =============================================
CREATE FUNCTION [dbo].[vfSMGenerateYearlyServiceDates]
(	
	@EffectiveDate bDate,
	@ExpirationDate bDate,
	@YearlyType tinyint,
	@YearlyEveryYear tinyint,
	@YearlyEveryDateMonth tinyint,
	@YearlyEveryDateMonthDay tinyint,
	@YearlyEveryDayOrdinal tinyint,
	@YearlyEveryDayDay tinyint,
	@YearlyEveryDayMonth tinyint
)
RETURNS TABLE
AS
RETURN
(
	WITH DateYears_CTE
	AS
	(
		SELECT YEAR(@EffectiveDate) EffectiveDateYear, YEAR(@ExpirationDate) ExpirationDateYear
	),
	ServiceDateForEffectiveDateYear_CTE
	AS
	(
		--Generate the service date of the effective date year
		--It may be before the effective date
		SELECT EffectiveDateYear, ExpirationDateYear,
			CASE @YearlyType 
				WHEN 1 THEN dbo.vfDateCreate(@YearlyEveryDateMonth, @YearlyEveryDateMonthDay, EffectiveDateYear)
				WHEN 2 THEN dbo.vfDateCreateFromDayType(@YearlyEveryDayMonth, EffectiveDateYear, @YearlyEveryDayOrdinal, @YearlyEveryDayDay)
			END ServiceDateForEffectiveDateYear
		FROM DateYears_CTE
	),
	FirstServiceDateYear_CTE
	AS
	(
		--If the service date for the effective date year is before the effective date then add a year.
		SELECT ExpirationDateYear, 
			CASE 
				WHEN ServiceDateForEffectiveDateYear < @EffectiveDate THEN EffectiveDateYear + 1
				ELSE EffectiveDateYear 
			END FirstServiceDateYear
		FROM ServiceDateForEffectiveDateYear_CTE
	),
	--Recursive CTE
	GenerateYears_CTE AS
	(
		--Generate the years that will have work done.
		SELECT ExpirationDateYear, FirstServiceDateYear ServiceDateYear
		FROM FirstServiceDateYear_CTE
		UNION ALL
		SELECT ExpirationDateYear, ServiceDateYear + @YearlyEveryYear
		FROM GenerateYears_CTE
		WHERE ServiceDateYear <= ExpirationDateYear
	),
	GenerateType1ServiceDates_CTE
	AS
	(
		--Using the years work will be done build the specific date work will be done.
		SELECT dbo.vfDateCreate(@YearlyEveryDateMonth, @YearlyEveryDateMonthDay, ServiceDateYear) ServiceDate
		FROM GenerateYears_CTE
	),
	GenerateType2ServiceDates_CTE
	AS
	(
		--Using the years work will be done build the specific date work will be done.
		SELECT dbo.vfDateCreateFromDayType(@YearlyEveryDayMonth, ServiceDateYear, @YearlyEveryDayOrdinal, @YearlyEveryDayDay) ServiceDate
		FROM GenerateYears_CTE
	),
	GenerateServiceDates_CTE
	AS
	(
		SELECT ServiceDate
		FROM GenerateType1ServiceDates_CTE
		WHERE @YearlyType = 1
		UNION ALL
		SELECT ServiceDate
		FROM GenerateType2ServiceDates_CTE
		WHERE @YearlyType = 2
	)
	SELECT ServiceDate
	FROM GenerateServiceDates_CTE
	WHERE ServiceDate <= @ExpirationDate
)
GO
GRANT SELECT ON  [dbo].[vfSMGenerateYearlyServiceDates] TO [public]
GO
