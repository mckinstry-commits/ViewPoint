SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 1/26/09
-- Description:	Returns a bit representing whether a value is null or empty or not
-- =============================================
CREATE FUNCTION [dbo].[vpfIsNullOrEmpty]
(@CheckExpression VARCHAR(MAX))
RETURNS BIT
AS
BEGIN
	-- Return the result of the function
	RETURN(SELECT CASE WHEN @CheckExpression IS NULL OR @CheckExpression = '' THEN 1 ELSE 0 END)
END

GO
GRANT EXECUTE ON  [dbo].[vpfIsNullOrEmpty] TO [public]
GO
