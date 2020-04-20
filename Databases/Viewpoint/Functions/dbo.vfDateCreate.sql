SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/16/12
-- Description:	Returns the date built from the month, day and year supplied.
-- If the month is not between 0 and 12 or the day is not between 1 and 31 null is returned.
-- If the day doesn't exist for the month such as 4/31 then the last day of the month is returned so 4/30 in our example.
-- =============================================
CREATE FUNCTION [dbo].[vfDateCreate]
(
	@Month tinyint,
	@Day tinyint,
	@Year smallint
)
RETURNS bDate
AS
BEGIN
	DECLARE @Date bDate
	
	IF @Month BETWEEN 1 AND 12 AND @Day BETWEEN 1 AND 31
		--Start with the day and create the default date for it e.g. Day = 5 -> 1/5/1900
		--Add the appropriate # months to the default date
		SET @Date = DATEADD(m, ((@Year - 1900) * 12) + @Month - 1, @Day - 1)
		
	RETURN @Date
END

GO
GRANT EXECUTE ON  [dbo].[vfDateCreate] TO [public]
GO
