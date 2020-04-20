SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Gil Fox>
-- Create date: <08.20.2010>
-- Description:	< This function will return a date with the time removed.
-- The current system date will be used. No parameters will be passed in
-- at this time. >
-- =============================================
CREATE FUNCTION [dbo].[vfDateOnly] ()

RETURNS SMALLDATETIME

AS
BEGIN

	---- Returns @DateTime at midnight; i.e., it removes the time portion of a DateTime value.
	---- will look something like this: YYYY-MM-DD 00:00:00
	return DATEADD(dd,0, DATEDIFF(dd,0, GETDATE()))

END

GO
GRANT EXECUTE ON  [dbo].[vfDateOnly] TO [public]
GO
