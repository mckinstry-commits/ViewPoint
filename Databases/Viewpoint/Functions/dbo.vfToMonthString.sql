SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 10/3/11
-- Description:	Returns a date time as a month string in the following format mm/yy
-- =============================================
CREATE FUNCTION [dbo].[vfToMonthString]
(
	@Date datetime
)
RETURNS nvarchar(max)
AS
BEGIN
	RETURN dbo.vfToString(MONTH(@Date)) + '/' + RIGHT(YEAR(@Date), 2)
END
GO
GRANT EXECUTE ON  [dbo].[vfToMonthString] TO [public]
GO
