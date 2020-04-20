SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************************
* Create Date:	11/8/2012
* Created By:	AR 
* Modified By:	JayR   Actually check into Version Control	TK-14356
*		     
* Description: Returns the day of week as string, calculates for 
				@@DateFirst so british english dates are handled
*
* Inputs: 
*
* Outputs:
*
*************************************************/

CREATE FUNCTION [dbo].[vfDayOfWeekAsString] ( @Date DATETIME )
RETURNS VARCHAR(10)
AS 
    BEGIN
		DECLARE @Datepart INT;
		SET @Datepart = ((@@DATEFIRST-1) + DATEPART(dw,@Date))%7;
        DECLARE @DayofWeek VARCHAR(10);
        SELECT  @DayofWeek = CASE @Datepart
                                 WHEN 0 THEN 'Sunday'
                                 WHEN 1 THEN 'Monday'
                                 WHEN 2 THEN 'Tuesday'
                                 WHEN 3 THEN 'Wednesday'
                                 WHEN 4 THEN 'Thursday'
                                 WHEN 5 THEN 'Friday'
                                 WHEN 6 THEN 'Saturday'
                               END
        RETURN (@DayofWeek)
    END
GO
GRANT EXECUTE ON  [dbo].[vfDayOfWeekAsString] TO [public]
GO
