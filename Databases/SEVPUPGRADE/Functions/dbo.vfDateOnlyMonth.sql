SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Gil Fox>
-- Create date: <09.20.2010>
-- Description:	< This function will return a date month formatted specifically
-- for our month data type. This means that the day will always be 1 and the
-- time portion is removed. The current system date will be used.
-- No parameters will be passed in at this time. >
-- =============================================
CREATE FUNCTION [dbo].[vfDateOnlyMonth] ()

	RETURNS SMALLDATETIME

AS
BEGIN

	---- Returns @DateTime at midnight; i.e., it removes the time portion of a DateTime value.
	---- Also the day will always be 01.
	---- will look something like this: YYYY-MM-01 00:00:00
	return DATEADD(mm, DATEDIFF(mm,0,GETDATE()), 0)
	----declare @Month smalldatetime
	----set @Month = DATEADD(day,-DAY(GETDATE())+1,GETDATE())
	----set @Month = DATEADD(dd,0, DATEDIFF(dd,0, @Month))
	----RETURN @Month
	

END



GO
GRANT EXECUTE ON  [dbo].[vfDateOnlyMonth] TO [public]
GO
