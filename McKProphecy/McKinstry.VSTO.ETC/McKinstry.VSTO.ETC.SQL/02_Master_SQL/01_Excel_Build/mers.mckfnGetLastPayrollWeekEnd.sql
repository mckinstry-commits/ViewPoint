use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnGetLastPayrollWeekEnd' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mckfnGetLastPayrollWeekEnd'
	DROP FUNCTION mers.mckfnGetLastPayrollWeekEnd
end
go

print 'CREATE FUNCTION mers.mckfnGetLastPayrollWeekEnd'
go

CREATE FUNCTION [mers].[mckfnGetLastPayrollWeekEnd]()
--(
--@InDate DATE
--)
RETURNS bDate
AS
BEGIN
-- ========================================================================
-- Object Name: mers.mckfnGetLastPayrollWeek
-- Author:		Ziebell, Jonathan
-- Create date: 07/28/2016
-- Description: Get the Last Payroll End Date that has posted into Viewpoint Actuals (Previous Sunday When after Wednesday at 5pm)
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
DECLARE  @DayStart INT
	, @Today DateTime
	, @TimePart INT
	, @PAYEndDate Date

SELECT @Today = SYSDATETIME() --@InDate

SET @TimePart = DATEPART(hh, @Today)
SET @DayStart = DATEPART(dw, @Today)
IF @TimePart >= 17 AND @DayStart = 4
	BEGIN
		SET @PAYEndDate = DATEADD(Day,1 -@DayStart,@Today)
	END
ELSE
	BEGIN
		IF @DayStart <= 4
			BEGIN
				 SET @PAYEndDate = DATEADD(Day,-6 -@DayStart,@Today)
			END
		ELSE
			BEGIN
				 SET @PAYEndDate = DATEADD(Day,(1 - @DayStart),@Today)
			END
	END


RETURN @PAYEndDate

END

GO

Grant EXECUTE ON mers.mckfnGetLastPayrollWeekEnd TO [MCKINSTRY\Viewpoint Users]


