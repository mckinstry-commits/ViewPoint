SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 02/07/12
-- Description:	Returns a line break.
-- =============================================
CREATE FUNCTION dbo.vfLineBreak 
(
)
RETURNS char(2)
AS
BEGIN

	RETURN CHAR(13) + CHAR(10)

END

GO
GRANT EXECUTE ON  [dbo].[vfLineBreak] TO [public]
GO
