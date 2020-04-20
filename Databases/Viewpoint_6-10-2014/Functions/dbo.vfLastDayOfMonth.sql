SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Gil Fox
-- Create date: 05/25/2013 TFS-47326
--
-- Description:	Gets the last day of the month for the given date parameter.
-- Currently bDate is defined as smalldatetime. This will limit the years
-- that are valid to 1900 to 2079. Last Month is 06/2079 (June)
-- NOTE: With SQL 2012 can use built in date function EOMonth to date.
--
-- =============================================
CREATE FUNCTION [dbo].[vfLastDayOfMonth]
(
	@Date SMALLDATETIME
)
RETURNS SMALLDATETIME
AS
BEGIN

	IF @Date IS NULL RETURN NULL
    
	---- validate the date parameter can be returned as a bDate (smalldatetim)
	DECLARE	@DateCheck DATETIME
	SET @DateCheck = @Date  
	IF @DateCheck NOT BETWEEN '19000101 00:00:00.000' AND '20790630 23:59:29.997'
		BEGIN
		RETURN NULL
		END

	/* FindLastDayOfMonth - Find what is the last day of a month - Leap year is handled by DATEADD */
	-- Get the first day of next month and remove a day from it using DATEADD
	--DECLARE @LastDayOfMonth date = CAST( DATEADD(dd, -1, DATEADD(mm, 1, @firstDayOfMonth)) AS date)
	DECLARE @LastDayOfMonth SMALLDATETIME	
	set @LastDayOfMonth = CAST( DATEADD(dd, -1, DATEADD(mm, 1,  dbo.vfFirstDayOfMonth(@Date))) AS SMALLDATETIME)

	RETURN @LastDayOfMonth

END

GO
GRANT EXECUTE ON  [dbo].[vfLastDayOfMonth] TO [public]
GO
