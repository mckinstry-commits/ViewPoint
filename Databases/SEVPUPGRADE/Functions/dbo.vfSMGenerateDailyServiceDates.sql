SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/14/12
-- Description:	Returns the next generated service date
-- =============================================
CREATE FUNCTION [dbo].[vfSMGenerateDailyServiceDates]
(	
	@EffectiveDate bDate,
	@ExpirationDate bDate,
	@DailyType tinyint,
	@DailyEveryDays int
)
RETURNS TABLE
AS
RETURN
(
	--Recursive CTE
	WITH GenerateType1ServiceDates_CTE
	AS
	(
		--Generate dates starting with today and spacing them out.
		SELECT @EffectiveDate ServiceDate
		UNION ALL
		SELECT DATEADD(d, @DailyEveryDays, ServiceDate)
		FROM GenerateType1ServiceDates_CTE
		WHERE ServiceDate <= @ExpirationDate
	),
	--Recursive CTE
	GenerateDays_CTE
	AS
	(
		--Generate dates for every day between the effective and expiration dates
		SELECT @EffectiveDate ServiceDate
		UNION ALL
		SELECT DATEADD(d, 1, ServiceDate)
		FROM GenerateDays_CTE
		WHERE ServiceDate <= @ExpirationDate
	),
	GenerateType2ServiceDates_CTE
	AS
	(
		--Filter out the weekends
		SELECT ServiceDate
		FROM GenerateDays_CTE
		WHERE DATEPART(dw, ServiceDate) NOT IN (1,7)
	),
	GenerateDates_CTE
	AS
	(
		SELECT ServiceDate
		FROM GenerateType1ServiceDates_CTE
		WHERE @DailyType = 1
		UNION ALL
		SELECT ServiceDate
		FROM GenerateType2ServiceDates_CTE
		WHERE @DailyType = 2
	)
	SELECT *
	FROM GenerateDates_CTE
	WHERE ServiceDate <= @ExpirationDate
)
GO
GRANT SELECT ON  [dbo].[vfSMGenerateDailyServiceDates] TO [public]
GO
