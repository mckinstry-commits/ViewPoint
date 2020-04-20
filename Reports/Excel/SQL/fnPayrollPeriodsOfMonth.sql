IF OBJECT_ID (N'[dbo].[fnPayrollPeriodsOfMonth]', N'FN') IS NOT NULL
    DROP FUNCTION [dbo].[fnPayrollPeriodsOfMonth];
GO

CREATE FUNCTION [dbo].[fnPayrollPeriodsOfMonth] (@pr_date Date)
RETURNS int
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE
		@start_date Date,
		@end_date Date,
		@num_weeks int
	SET @start_date = DATEADD(dd, -1*DAY(@pr_date)+1, @pr_date)
	SET @end_date = DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@pr_date)+1,0))

	--;WITH Days_Of_The_Week AS (
	--	SELECT 7 AS day_number, 'Sunday' AS day_name
	--)
	--SELECT @num_weeks =
	--	1 + DATEDIFF(wk, @start_date, @end_date) -
	--		CASE WHEN DATEPART(weekday, @start_date) > day_number THEN 1 ELSE 0 END -
	--		CASE WHEN DATEPART(weekday, @end_date)   < day_number THEN 1 ELSE 0 END
	--FROM
	--	Days_Of_The_Week

	SELECT @num_weeks = DATEDIFF(wk, @start_date, @end_date) +
						CASE DATENAME(dw, @start_date) WHEN 'Sunday' THEN 1 ELSE 0 END
	RETURN(@num_weeks)
END
GO

-- Test Script
 --select dbo.fnPayrollPeriodsOfMonth('8/5/2014')
 --select dbo.fnPayrollPeriodsOfMonth('9/22/2013')
 --select dbo.fnPayrollPeriodsOfMonth('12/22/2013')
 --select dbo.fnPayrollPeriodsOfMonth('2014-09-22 00:00:00')