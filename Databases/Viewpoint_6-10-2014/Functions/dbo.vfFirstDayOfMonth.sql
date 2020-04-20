SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Gil Fox
-- Create date: 05/25/2013 TFS-47326
-- Description:	Gets the first day of the month for the given date parameter.
-- Currently bDate is defined as smalldatetime. This will limit the years
-- that are valid to 1900 to 2079. Last Month is 06/2079 (June)
-- =============================================
CREATE FUNCTION [dbo].[vfFirstDayOfMonth]
(
	@Date SMALLDATETIME
)
RETURNS SMALLDATETIME
AS
BEGIN

	IF @Date IS NULL RETURN NULL
    
	---- validate the date parameter can be returned as a bDate (smalldatetime)
	DECLARE	@DateCheck DATETIME
	SET @DateCheck = @Date  
	IF @DateCheck NOT BETWEEN '19000101 00:00:00.000' AND '20790630 23:59:29.997'
		BEGIN
		RETURN NULL
		END

	---- FindFirstDayOfMonth - Find the first date of any month
	---- Replace the day part with -01
	DECLARE @FirstDayOfMonth SMALLDATETIME
	SET @FirstDayOfMonth = CAST( CAST(YEAR(@Date) AS varchar(4)) + '-' + CAST(MONTH(@Date) AS varchar(2)) + '-01' AS SMALLDATETIME)

	RETURN @FirstDayOfMonth

END

GO
GRANT EXECUTE ON  [dbo].[vfFirstDayOfMonth] TO [public]
GO
